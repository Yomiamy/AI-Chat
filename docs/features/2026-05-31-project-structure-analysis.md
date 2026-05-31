# AI-Chat 專案結構與執行流程分析

> 產出日期：2026-05-31
> 分析方法：codebase-memory 知識圖譜（1016 nodes / 1277 edges）+ 源碼核對
> 對象 commit 分支：`feature/202605/adjust-project-skill-and-agent-3`

---

## 一、專案定位

一個 **Flutter 跨平台 AI 聊天 App**，透過 `firebase_ai` 串接 Gemini（`gemini-3.1-flash-lite`）做串流對話，支援圖片／檔案附件、本地對話快取（ObjectBox）、歷史搜尋與匯出。

- 套件名稱：`ai_chat`
- Dart SDK：`^3.10.8`
- 狀態管理：`bloc` / `flutter_bloc`
- 依賴注入：`get_it`
- 本地資料庫：`objectbox`
- AI：`firebase_ai` + `firebase_core`

---

## 二、目錄組成（lib/）

採「**分層 + feature folder**」混合架構，職責切得很乾淨：

| 目錄 | 職責 | 關鍵檔案 |
|------|------|----------|
| `bloc/gemini_api/` | 對話主流程的狀態機 | `GeminiApiBloc`（348 行，核心） |
| `bloc/search/` | 歷史訊息搜尋狀態機 | `SearchBloc`（debounce 300ms） |
| `data/` | Repository 抽象 + ObjectBox 實作 | `ChatRepository`(介面) / `ObjectBoxChatRepository`(實作) / `ChatMessage`(Entity) |
| `di/` | 依賴注入組裝 | `injection.dart`（`configureDependencies`） |
| `services/` | 純功能服務 | `ExportService`（對話匯出） |
| `pages/` | 頁面入口 | `AiChatPage`（Provider 組裝） |
| `pages/widgets/` | UI 元件 | `AiChatView` / `MessageBubbleWidget` / `InputAreaWidget` / `SearchAppBar` / `HighlightText` 等 |
| `features/foundation/` | 常數、樣式、擴充 | `AppConstants` / `Sizes` / `*Extension` |
| `features/utils/` | 工具 | `FilePickManager`（檔案/圖片選取 + 權限） |
| `generated/` | 自動產生碼 | `objectbox.g.dart` / `assets.gen.dart` / l10n |
| `l10n/` `generated/intl/` | 多語系 | en / zh / zh_TW |

> 觀察：`data/` 用 interface（`ChatRepository`）隔離 ObjectBox 實作，Bloc 只依賴抽象 —— 這是正確的依賴反轉，測試裡的 `MockChatRepository` 就靠這點。

---

## 三、核心資料結構

```
ChatMessage (ObjectBox @Entity)
├── id: int           主鍵
├── content: String   訊息內容（base64 圖片在落地前被替換為佔位符）
├── timestamp: int    毫秒 epoch，用於排序與 session 過濾
└── role: String      原始字串，透過 roleEnum getter 做型別安全存取
                      (prompt | aiReply | error)
```

兩份「同一份資料的不同視角」並存於 `GeminiApiBloc`：
- `_messages: List<ChatMessage>` —— 結構化資料，給搜尋/匯出/資料層用
- `_chatList: List<String>` —— 帶 `ChatEntryPrefix` 前綴的渲染字串，給 UI 直接吃

> 風險點：這兩份 list 在 `_query`/`_init`/`_newChat`/`_clearAll` 多處手動同步插入，是目前最容易出現不一致 bug 的地方。任何新增訊息的路徑都必須同時維護兩者。

---

## 四、啟動流程（main → UI）

```
main()
 └─ WidgetsFlutterBinding.ensureInitialized()
 └─ Firebase.initializeApp()
 └─ _initLocale()              依系統 locale 載入 S（intl）
 └─ configureDependencies()    建立 ObjectBoxChatRepository（openStore）→ 註冊為 GetIt singleton
 └─ runApp(MyApp)
      └─ MaterialApp（Material3 + 多語系 delegate）
           └─ AiChatPage
                └─ MultiBlocProvider
                     ├─ GeminiApiBloc(GetIt<ChatRepository>)   ← 建構時自動 add(InitEvent)
                     └─ SearchBloc(GetIt<ChatRepository>)
                          └─ AiChatView（實際 UI）
```

`GeminiApiBloc` 一被建立就 `add(GeminiApiInitEvent())`，自動載入本機快取的當次 session 訊息。

---

## 五、對話主流程（GeminiApiBloc）

事件驅動，7 個 event handler。`GeminiApiBloc extends Bloc<GeminiApiEvent, GeminiApiState>`，建構子注入 `ChatRepository`，並在建構當下 `add(GeminiApiInitEvent())`。

> 視覺化的 event / handler / state 轉換圖（mermaid 狀態機 + `_query` 時序圖）見
> → [GeminiApiBloc 狀態流程圖](./bloc/gemini-api-bloc-states.md)。

### 5.1 Event 定義（payload）

所有 event 繼承 `abstract GeminiApiEvent extends Equatable`（`props = []`）：

| Event | 攜帶欄位 | 觸發來源 |
|-------|----------|----------|
| `GeminiApiInitEvent` | 無 | Bloc 建構子自動觸發 |
| `GeminiApiQueryEvent` | `String query`（納入 props） | 使用者按送出 |
| `GeminiApiPickFileEvent` | 無 | 點選「附加檔案」 |
| `GeminiApiPickImageEvent` | `VoidCallback? onPermissionDenied`（**不**納入 props） | 點選「附加圖片」 |
| `GeminiApiRemoveFileEvent` | 無 | 移除已選附件 / stream 內部自呼 |
| `GeminiApiNewChatEvent` | 無 | 「新對話」 |
| `GeminiApiClearAllEvent` | 無 | 「清空全部」 |

> 細節：`PickImageEvent` 刻意把 `onPermissionDenied` 排除在 `props` 外，避免 callback 參與 Equatable 比較導致 event 去重失準。

### 5.2 共用狀態（Bloc 內部欄位 + GeminiApiState）

Bloc 持有三個可變欄位：
- `late GenerativeModel _aiModel` —— Gemini 模型（`InitEvent` 才賦值）
- `List<String> _chatList` —— 帶 `ChatEntryPrefix` 前綴的渲染字串
- `List<ChatMessage> _messages` —— 結構化訊息

`GeminiApiState extends Equatable`（5 個欄位，全可空）：

| 欄位 | 型別 | 用途 |
|------|------|------|
| `status` | `Status?`（預設 `initial`） | 驅動 UI 狀態 |
| `chatList` | `List<String>?` | 渲染清單快照 |
| `messages` | `List<ChatMessage>?` | 結構化清單快照 |
| `selectedFileBytes` | `Uint8List?` | 待送附件 bytes |
| `selectedMimeType` | `String?` | 待送附件 MIME |

`copyWith` 有兩個布林旗標破壞「`x ?? this.x`」的慣例以表達「明確清空」：
- `clearChat: true` → 強制 `chatList`/`messages` 設 `null`
- `clearFile: true` → 強制 `selectedFileBytes`/`selectedMimeType` 設 `null`

`Status` enum 共 11 個值，本 Bloc 實際只用到 `initial / newPrompt / loading / success / failure`；其餘（`empty / noInternetConnection / unauthorized / forbidden / notFound / serverError`）目前未使用。

### 5.3 每個 Event 的處理細節

每列標明：**讀取來源 → 改動哪些內部欄位 → 是否動 DB → emit 的 Status / state 變化**。

#### `_init`（InitEvent）
```
讀: SharedPreferences['session_start_ms']
 → _repo.loadMessages(since: sessionStartMs)   // DB 讀（不寫）
 → 重建 _messages
 → 依 roleEnum 用 ChatEntryPrefix.wrap() 重建 _chatList
 → _initFirebaseAiLogic()                      // 建 _aiModel
emit: copyWith(
        chatList: _chatList 空則傳 null,
        messages: _messages 空則傳 null,
      )                                          // status 維持 initial
DB: 只讀
```

#### `_query`（QueryEvent）→ **主路徑**，見 5.4

#### `_pickFile`（PickFileEvent）
```
讀: FilePickManager.pickFile()
分支:
  result 為空 / files 空 → emit copyWith(status: failure, clearFile: true)
  否則:
    bytes = file.bytes ?? File(file.path).readAsBytes()
    bytes 仍為 null → return（不 emit）
    否則 → emit copyWith(selectedFileBytes: bytes,
                         selectedMimeType: file.mimeType)
DB: 不動 / _chatList、_messages 不動
```

#### `_pickImage`（PickImageEvent）
```
讀: FilePickManager.pickImageWithPermission(onPermissionDenied: event.onPermissionDenied)
分支:
  file 為 null → emit copyWith(status: failure, clearFile: true)
  否則:
    bytes = file.readAsBytes()
    → emit copyWith(selectedFileBytes: bytes, selectedMimeType: file.mimeType)
DB: 不動 / _chatList、_messages 不動
```

#### `_removeFile`（RemoveFileEvent）
```
emit copyWith(clearFile: true)   // 僅清空 state 中的待送附件
DB: 不動。註：_query stream 迴圈內也會主動呼叫它清掉已送出的附件
```

#### `_newChat`（NewChatEvent）
```
寫: SharedPreferences['session_start_ms'] = now()   // 推進 session 起點
 → _chatList = []；_messages = []                   // 清空記憶體
emit copyWith(status: initial, clearChat: true, clearFile: true)
DB: 不刪資料（歷史保留，只是新 session 載不到舊訊息）
```

#### `_clearAll`（ClearAllEvent）
```
_repo.clearAll()                 // DB removeAll()，真正清空
 → _chatList = []；_messages = []
emit copyWith(status: initial, clearChat: true, clearFile: true)
DB: 全刪
```

> 對比重點：`_newChat` 與 `_clearAll` emit 完全相同的 state，差別只在 **是否真的刪 DB**。前者靠推進 `session_start_ms` 讓 `loadMessages(since:)` 載不到舊資料（軟隔離），後者是硬刪除。

### 5.4 `_query` 主路徑（送出訊息）

```
1. 附件大小檢查（>5MB 直接拒絕，寫 error 訊息）
2. _buildUserMessage：圖片轉 base64 內嵌 markdown / 其他附件轉描述
3. ① 落地使用者訊息（_stripBase64 把 base64 換成 [附件: ...] 佔位符）
   同步更新 _chatList(insert 0) 與 _messages(insert 0)
4. emit newPrompt → loading
5. _buildContent：組 Gemini 請求（text 或 multi[InlineDataPart + TextPart]）
   附帶固定 prompt 規則（繁中 + markdown）
6. generateContentStream → await for 逐 chunk：
   - TextPart / ExecutableCodePart / CodeExecutionResultPart / InlineDataPart(圖片)
   - 串流時就地拼接到 _chatList[0]（同一則 AI 回覆持續 append）
   - 每 chunk emit loading 即時刷新 UI
7. ② stream 結束 → 落地 AI 回覆（_stripAiBase64 把圖片換成 [圖片回覆]）
8. emit success
   ③ 例外 → 落地 error 訊息 + emit failure
```

> 設計重點：**DB 存的是「瘦身版」**（base64 被替換成佔位符），避免 ObjectBox 塞爆；UI 的 `_chatList` 才保留完整 base64 供當下渲染。落地時機分三點（① 送出、② 完成、③ 例外），確保每種結局都有持久化。

> `ObjectBoxChatRepository` 用 `_maxMessages = 100` + `_trimToLimit()` 做滑動窗口，超量時刪最舊。

---

## 五之二、Bloc 送出時使用的 Model（Gemini）

### 模型建立（`_initFirebaseAiLogic`，由 `_init` 呼叫）

```dart
_aiModel = FirebaseAI.googleAI().generativeModel(
  model: 'gemini-3.1-flash-lite',
  generationConfig: GenerationConfig(
    responseModalities: [ResponseModalities.text],   // 只要文字輸出
  ),
);
```

| 項目 | 值 | 說明 |
|------|----|------|
| 來源 | `FirebaseAI.googleAI()` | 走 Firebase AI Logic（`firebase_ai` 套件），非直連 Google AI SDK |
| 模型 | `gemini-3.1-flash-lite` | 硬編碼，無設定切換（前一版為 `gemini-2.5-flash`） |
| 輸出模態 | `ResponseModalities.text` | 設定上只取文字（但 stream 解析仍會處理圖片 `InlineDataPart`，見下方注意） |
| 型別 | `late GenerativeModel` | `_init` 前未初始化，靠事件保證先 init 再 query |

### 送出的請求內容（`_buildContent`）

`_query` 不直接傳使用者字串，而是經 `_buildContent(prompt, fileBytes, mimeType)` 組裝，**一律附帶固定格式指令**：

- **純文字**：`Content.text(...)`
- **帶附件**：`Content.multi([InlineDataPart(mimeType, bytes), TextPart(...)])`

兩者的文字部分都尾隨同一段系統提示：
```
請用以下格式要求回答:
- 繁體中文回答
- 以markdown格式輸出
- 依照內容調整縮排
```

### 呼叫方式（串流）

```dart
final response = _aiModel.generateContentStream([content]);
await for (final chunk in response) {
  final parts = chunk.candidates.firstOrNull?.content.parts ?? [];
  // 逐 part 解析後拼接到 _chatList[0]，每 chunk emit loading 即時刷新
}
```

`generateContentStream` 回傳 `Stream`，Bloc 以 `await for` 逐 chunk 消費。每個 chunk 解析的 part 型別與處理：

| Part 型別 | 處理 |
|-----------|------|
| `TextPart` | `writeln(part.text)` |
| `ExecutableCodePart` | `writeln(part.code)` |
| `CodeExecutionResultPart` | `writeln(part.output)` |
| `InlineDataPart`（`image/jpeg\|png\|webp`） | `base64Encode` 後組成 `![image](data:...;base64,...)` 內嵌 markdown |

> 注意（潛在不一致）：`generationConfig` 宣告 `responseModalities: [text]`，但 stream 解析仍保留 `InlineDataPart` 圖片分支。實務上 text-only 模型不會回圖，這段圖片處理目前等同 dead branch；若日後切換成可回圖的模型才會生效。是「為未來預留」還是「設定與程式碼不一致」需釐清。

---

## 六、搜尋流程（SearchBloc）

```
SearchQueryChanged（debounce 300ms）
 └─ 空字串 → reset
 └─ searchMessages(query)   ObjectBox content.contains(caseInsensitive) + findAsync
      └─ empty / done / error
```

`searchMessages` 走 `findAsync()`（非阻塞 isolate），UI 用 `HighlightText` 標示命中字串。

---

## 七、輔助能力

- **匯出**：`ExportService`（`lib/services/`）+ `share_plus`，把對話輸出分享。
- **檔案/權限**：`FilePickManager` 封裝 `file_picker` / `image_picker` / `permission_handler`，圖片選取帶 `onPermissionDenied` callback。
- **多語系**：兩套 l10n 並存 —— `generated/l10n.dart`(intl `S`) 與 `l10n/l10n.dart`(`AppLocalizations`)。

---

## 八、整體評價（Linus 視角）

**🟢 好品味之處**
- Repository interface 隔離 ObjectBox，依賴反轉乾淨，可測。
- DB 落地「瘦身」策略消滅了「base64 撐爆資料庫」這個特殊情況。
- Search 用 debounce + findAsync，沒有把主執行緒卡死。

**🟡 凑合 / 風險**
- `_messages` 與 `_chatList` 雙清單手動同步，散落在 4+ 個 handler，是最脆弱的點。若未來要加訊息來源，極易漏改其中一個。
- 兩套 l10n 機制並存，職責重疊，長期應收斂成一套。
- `_query` 單一函式約 130 行、巢狀達 3~4 層（stream 迴圈內再分支 part 型別），逼近「該重寫」門檻；part 解析可抽成獨立函式。
- 模型 `gemini-3.1-flash-lite` 硬編碼，且 `responseModalities: [text]` 與 stream 內的 `InlineDataPart` 圖片解析分支不一致（dead branch）。
- `Status` enum 有 11 個值，Bloc 只用 5 個，其餘 6 個（網路/權限/HTTP 錯誤類）從未被 emit，屬未落實的預留。

**改進方向（不破壞現有行為）**
1. 把 `_messages` / `_chatList` 的雙寫包成單一 `_appendMessage(role, content)` helper，消滅散落同步。
2. `_query` 內的 chunk part 解析（TextPart/Code/InlineData）抽成 `_renderParts(parts) → String`，把巢狀壓平。
