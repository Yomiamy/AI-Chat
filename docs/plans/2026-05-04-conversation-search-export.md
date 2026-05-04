# 對話搜尋與匯出功能實作計畫

**日期**：2026-05-04  
**狀態**：待實作  
**對應規格**：`docs/features/2026-05-04-conversation-search-export.md`

---

## 1. 現有架構分析

### 1.1 資料層

| 元件 | 位置 | 說明 |
|------|------|------|
| `ChatMessage` | `lib/data/chat_message.dart` | ObjectBox Entity，含 `id`、`content`、`timestamp`、`role` |
| `ChatRepository` | `lib/data/chat_repository.dart` | 抽象介面 + `ChatRepo` 實作，已有 `loadMessages()` 方法 |
| ObjectBox Store | `lib/generated/objectbox/objectbox.g.dart` | 自動生成的 ORM 程式碼 |

### 1.2 狀態管理層

| 元件 | 位置 | 說明 |
|------|------|------|
| `GeminiApiBloc` | `lib/bloc/gemini_api/gemini_api_bloc.dart` | 主要 BLoC，管理聊天狀態 |
| `GeminiApiState` | `lib/bloc/gemini_api/gemini_api_state.dart` | 含 `chatList`、`status` 等 |
| `ChatEntryPrefix` | `lib/bloc/gemini_api/models/chat_entry_prefix.dart` | 訊息前綴處理 |

### 1.3 UI 層

| 元件 | 位置 | 說明 |
|------|------|------|
| `AiChatView` | `lib/pages/widgets/ai_chat_view.dart` | 主畫面，含 AppBar + Menu |
| `MessageBubbleWidget` | `lib/pages/widgets/message_bubble_widget.dart` | 訊息泡泡元件 |

### 1.4 現有依賴

已有可用套件：
- `objectbox` — 本地資料庫
- `flutter_bloc` — 狀態管理
- `flutter_markdown` — Markdown 渲染

需新增套件：
- `share_plus` — 系統分享功能

---

## 2. 技術方案

### 2.1 架構選擇：獨立 SearchBloc vs 擴展 GeminiApiBloc

| 方案 | 優點 | 缺點 |
|------|------|------|
| **A. 獨立 SearchBloc** | 單一職責、易測試、不影響現有邏輯 | 需額外注入 Repository |
| **B. 擴展 GeminiApiBloc** | 共用狀態、減少 Provider 層級 | BLoC 變肥、職責混淆 |

**選擇：方案 A — 獨立 SearchBloc**

理由：
1. 搜尋是獨立功能，不依賴聊天串流邏輯
2. 便於未來擴展（如進階篩選）
3. 可獨立測試搜尋邏輯

### 2.2 搜尋實作方案

```
┌─────────────────────────────────────────────────────┐
│                   SearchBloc                        │
├─────────────────────────────────────────────────────┤
│ Events:                                             │
│   - SearchQueryChanged(String query)                │
│   - SearchCleared()                                 │
│                                                     │
│ State:                                              │
│   - query: String                                   │
│   - results: List<ChatMessage>                      │
│   - status: SearchStatus (idle/searching/done/empty)│
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│              ChatRepository                         │
├─────────────────────────────────────────────────────┤
│ 新增方法：                                           │
│   searchMessages(String query) → List<ChatMessage>  │
│   使用 ObjectBox 的 contains() 查詢                  │
└─────────────────────────────────────────────────────┘
```

### 2.3 匯出實作方案

```
ExportService (純函式，無狀態)
    │
    ├── formatAsTxt(List<ChatMessage>) → String
    ├── formatAsMarkdown(List<ChatMessage>) → String
    └── share(String content, String filename) → Future<void>
                                                      │
                                                      ▼
                                              share_plus 套件
```

### 2.4 UI 整合方案

```
AiChatView
    │
    ├── 一般模式 (現有)
    │       AppBar: [Title] [Menu]
    │       Body: ListView + InputArea
    │
    └── 搜尋模式 (新增)
            AppBar: [Back] [SearchField] [Clear]
            Body: SearchResultList (高亮關鍵字)
```

---

## 3. 檔案清單

### 3.1 新增檔案

| 檔案路徑 | 用途 |
|----------|------|
| `lib/bloc/search/search_bloc.dart` | 搜尋 BLoC 主體 |
| `lib/bloc/search/search_event.dart` | 搜尋事件定義 |
| `lib/bloc/search/search_state.dart` | 搜尋狀態定義 |
| `lib/bloc/search/search.dart` | barrel export |
| `lib/services/export_service.dart` | 匯出格式化 + 分享 |
| `lib/pages/widgets/search_app_bar.dart` | 搜尋模式 AppBar |
| `lib/pages/widgets/search_result_item.dart` | 搜尋結果項目（含高亮） |
| `lib/pages/widgets/highlight_text.dart` | 關鍵字高亮元件 |
| `test/bloc/search_bloc_test.dart` | SearchBloc 單元測試 |
| `test/services/export_service_test.dart` | ExportService 單元測試 |

### 3.2 修改檔案

| 檔案路徑 | 修改內容 |
|----------|----------|
| `lib/data/chat_repository.dart` | 新增 `searchMessages()` 方法 |
| `lib/pages/widgets/ai_chat_view.dart` | 整合搜尋模式 UI |
| `lib/bloc/bloc.dart` | 匯出 search barrel |
| `lib/l10n/intl_zh_TW.arb` | 新增搜尋/匯出相關文字 |
| `lib/l10n/intl_en.arb` | 新增英文翻譯 |
| `pubspec.yaml` | 新增 `share_plus` 依賴 |

---

## 4. 任務拆分

### Phase 1：基礎建設

#### Task 1.1：新增 share_plus 依賴
**交付物**：`pubspec.yaml` 更新，`flutter pub get` 成功  
**預估時間**：2 分鐘  
**驗證**：`flutter pub deps | grep share_plus`

#### Task 1.2：擴展 ChatRepository 搜尋方法
**交付物**：  
- `ChatRepository` 介面新增 `searchMessages(String query)`
- `ChatRepo` 實作使用 `ChatMessage_.content.contains(query, caseSensitive: false)`

**預估時間**：5 分鐘  
**驗證**：單元測試 `test/data/chat_repository_test.dart`

```dart
// 預期介面
List<ChatMessage> searchMessages(String query);
```

---

### Phase 2：搜尋 BLoC

#### Task 2.1：建立 SearchBloc 骨架
**交付物**：  
- `lib/bloc/search/search_event.dart`
- `lib/bloc/search/search_state.dart`
- `lib/bloc/search/search_bloc.dart`（空殼）
- `lib/bloc/search/search.dart`

**預估時間**：5 分鐘  
**驗證**：編譯通過

#### Task 2.2：實作 SearchQueryChanged 事件
**交付物**：  
- 300ms debounce 邏輯（使用 `stream.debounceTime` 或 `Timer`）
- 呼叫 `ChatRepository.searchMessages()`
- 更新 State

**預估時間**：5 分鐘  
**驗證**：`test/bloc/search_bloc_test.dart`

```dart
// 測試案例
1. 輸入關鍵字後 300ms 觸發搜尋
2. 連續輸入只觸發最後一次
3. 搜尋結果正確匹配
4. 空字串清除結果
```

---

### Phase 3：搜尋 UI

#### Task 3.1：建立 SearchAppBar 元件
**交付物**：`lib/pages/widgets/search_app_bar.dart`  
- 返回按鈕
- TextField（autofocus）
- 清除按鈕

**預估時間**：5 分鐘  
**驗證**：Widget 預覽

#### Task 3.2：建立 HighlightText 元件
**交付物**：`lib/pages/widgets/highlight_text.dart`  
- 接受 `text`、`highlight`、`highlightStyle` 參數
- 使用 `TextSpan` 實作高亮

**預估時間**：5 分鐘  
**驗證**：Widget 預覽 + 單元測試

#### Task 3.3：建立 SearchResultItem 元件
**交付物**：`lib/pages/widgets/search_result_item.dart`  
- 顯示角色標籤（你 / AI）
- 顯示時間戳
- 內容預覽（截斷 + 高亮）

**預估時間**：5 分鐘  
**驗證**：Widget 預覽

#### Task 3.4：整合搜尋模式至 AiChatView
**交付物**：修改 `lib/pages/widgets/ai_chat_view.dart`  
- AppBar 新增搜尋 icon
- 點擊後切換為搜尋模式
- 注入 SearchBloc
- 顯示搜尋結果列表

**預估時間**：10 分鐘  
**驗證**：手動測試搜尋流程

---

### Phase 4：匯出功能

#### Task 4.1：建立 ExportService
**交付物**：`lib/services/export_service.dart`  
- `formatAsTxt(List<ChatMessage>)` → 純文字格式
- `formatAsMarkdown(List<ChatMessage>)` → Markdown 格式
- `generateFilename(String ext)` → `chat_export_YYYYMMDD_HHmmss.{ext}`

**預估時間**：5 分鐘  
**驗證**：`test/services/export_service_test.dart`

#### Task 4.2：實作分享功能
**交付物**：擴展 `ExportService`  
- `shareAsFile(String content, String filename)` 
- 使用 `path_provider` 暫存檔案
- 呼叫 `Share.shareXFiles()`

**預估時間**：5 分鐘  
**驗證**：手動測試分享流程

#### Task 4.3：整合匯出至 Menu
**交付物**：修改 `lib/pages/widgets/ai_chat_view.dart`  
- Menu 新增「匯出對話」選項
- 彈出格式選擇 Dialog（TXT / Markdown）
- 支援匯出「全部對話」或「搜尋結果」

**預估時間**：10 分鐘  
**驗證**：手動測試匯出流程

---

### Phase 5：國際化 & 收尾

#### Task 5.1：新增 i18n 字串
**交付物**：  
- `lib/l10n/intl_zh_TW.arb` 新增搜尋/匯出相關文字
- `lib/l10n/intl_en.arb` 同步英文

**預估時間**：5 分鐘  
**驗證**：`flutter gen-l10n` 成功

#### Task 5.2：整合測試
**交付物**：  
- 完整搜尋流程測試
- 完整匯出流程測試

**預估時間**：10 分鐘  
**驗證**：`flutter test` 全部通過

---

## 5. 依賴套件

```yaml
# pubspec.yaml 新增
dependencies:
  share_plus: ^10.0.0  # 系統分享功能
```

`path_provider` 已為 `share_plus` 的傳遞依賴，無需額外添加。

---

## 6. 測試計畫

### 6.1 單元測試

| 測試檔案 | 測試範圍 |
|----------|----------|
| `test/data/chat_repository_test.dart` | `searchMessages()` 方法 |
| `test/bloc/search_bloc_test.dart` | debounce、狀態轉換 |
| `test/services/export_service_test.dart` | 格式化輸出正確性 |
| `test/widgets/highlight_text_test.dart` | 高亮邏輯 |

### 6.2 測試案例

**搜尋功能**：
1. 輸入「flutter」應匹配「Flutter」（不區分大小寫）
2. 300ms 內連續輸入只觸發一次搜尋
3. 空字串清除搜尋結果
4. 無匹配時顯示「找不到相關對話」

**匯出功能**：
1. TXT 格式包含正確時間戳和角色標籤
2. Markdown 格式符合規格範例
3. 檔案命名符合 `chat_export_YYYYMMDD_HHmmss` 格式

---

## 7. 風險與緩解

| 風險 | 影響 | 緩解措施 |
|------|------|----------|
| ObjectBox contains() 效能 | 大量訊息時搜尋緩慢 | 限制最大回傳筆數 100 筆 |
| 跨平台分享相容性 | iOS/Android 行為不一致 | 使用成熟的 share_plus 套件 |
| 搜尋 UI 狀態混亂 | UX 不佳 | 獨立 BLoC 管理搜尋狀態 |

---

## 8. 執行方式建議

### 方案 A：循序執行（適合單人開發）
按 Phase 1 → 5 依序完成，每個 Task 獨立 commit。

### 方案 B：平行執行（適合多人協作）
- 開發者 A：Phase 1 + 2（資料層 + BLoC）
- 開發者 B：Phase 3（UI 元件）
- 最後整合 Phase 4 + 5

### 方案 C：Subagent 驅動
使用 Claude Code Task Agent 平行處理：
- Agent 1：Task 1.1 + 1.2（基礎建設）
- Agent 2：Task 2.1 + 2.2（SearchBloc）
- Agent 3：Task 3.1 + 3.2 + 3.3（UI 元件）
- 主 Agent：Task 3.4 + 4.x（整合）

---

## 9. 總結

| 指標 | 數值 |
|------|------|
| 新增檔案 | 10 個 |
| 修改檔案 | 6 個 |
| 總任務數 | 12 個 |
| 預估總時間 | 77 分鐘 |
| 新增依賴 | 1 個（share_plus） |
