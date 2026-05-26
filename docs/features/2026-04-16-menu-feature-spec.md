# Menu 功能規格文件

**日期**：2026-04-16  
**狀態**：待實作  
**範圍**：`ios/` AppBar `more_vert` IconButton 功能實作

---

## 背景

`ai_chat_view.dart` line 71-74 有一個空白的 `more_vert` IconButton，`onPressed: () {}` 完全未實作。本規格定義此 Menu 的完整功能集、UI 行為與實作細節。

---

## 功能清單

4 個 Menu 項目，按使用頻率排序：

| # | 項目 | 說明 | 複雜度 |
|---|------|------|--------|
| 1 | **新對話** (New Chat) | 清空畫面，開啟全新對話 | 低 |
| 2 | **清除對話** (Clear Chat) | 清空畫面 + 清除 ObjectBox 所有記錄 | 低 |
| 3 | **複製對話** (Copy All) | 將所有訊息格式化後複製到剪貼簿 | 低 |
| 4 | **關於** (About) | 顯示 App 版本、模型名稱 | 低 |

---

## UI 規格

### Menu 呈現方式

使用 Flutter 原生 `showMenu()` 或 `PopupMenuButton`，點擊 `more_vert` icon 後從右上角展開。

```
┌─────────────────┐
│ ✦ 新對話        │
│ 🗑 清除對話     │
│ 📋 複製對話     │
│ ─────────────── │
│ ℹ  關於         │
└─────────────────┘
```

- 「關於」與其他項目之間加 `Divider`
- 使用 `PopupMenuButton<_MenuAction>` enum 驅動，避免 magic string

---

## 各功能規格

### 1. 新對話（New Chat）

**行為**：
- 清空畫面訊息列表（UI 回到 `EmptyWidget`）
- **不刪除** ObjectBox 記錄（歷史訊息永久保留於 DB）
- 將當下時間戳寫入 SharedPreferences（key: `session_start_ms`）作為新 session 邊界
- 重置 BLoC 狀態：`chatList = null`、清除已選附件
- **重啟 App 後**：`_init` 只載入 `timestamp > session_start_ms` 的訊息，因此舊訊息不會重新出現

**Session 載入規則**：

| SharedPreferences `session_start_ms` | `_init` 行為 |
|--------------------------------------|-------------|
| 不存在（從未點過新對話）| 載入全部訊息 |
| 存在（值為 T）| 只載入 `timestamp > T` 的訊息 |

**觸發路徑**：
```
Menu tap → GeminiApiNewChatEvent → BLoC._newChat()
  → SharedPreferences.setInt('session_start_ms', now)
  → emit(state.copyWith(chatList: null, clearFile: true))
```

**依賴套件**：`shared_preferences`（需新增至 `pubspec.yaml`）

**新增事件**：
```dart
// gemini_api_event.dart
class GeminiApiNewChatEvent extends GeminiApiEvent {}
```

**BLoC handler**：
```dart
on<GeminiApiNewChatEvent>(_newChat);

Future<void> _newChat(GeminiApiNewChatEvent event, Emitter<GeminiApiState> emit) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('session_start_ms', DateTime.now().millisecondsSinceEpoch);
  _chatList = [];
  emit(state.copyWith(
    status: Status.initial,
    chatList: null,
    clearFile: true,
  ));
}
```

**`_init` 調整**（配合 session 邊界）：
```dart
void _init(GeminiApiInitEvent event, Emitter<GeminiApiState> emit) async {
  final prefs = await SharedPreferences.getInstance();
  final sessionStartMs = prefs.getInt('session_start_ms'); // null → 首次安裝

  _chatList = _repo.loadMessages(since: sessionStartMs).map((m) { ... }).toList();
  ...
}
```

---

### 2. 清除對話（Clear Chat）

**行為**：
- 顯示確認 Dialog（防止誤操作）
- 確認後：清空 ObjectBox 所有記錄 + 清空畫面

**確認 Dialog**：
```
標題：清除所有對話？
內容：此操作無法復原，所有對話記錄將被永久刪除。
按鈕：取消 | 清除（紅色）
```

**觸發路徑**：
```
Menu tap → showDialog() → 確認 → GeminiApiClearAllEvent → BLoC._clearAll()
```

**ChatRepository 調整**：
```dart
// abstract interface class ChatRepository
// loadMessages 新增 since 參數（null → 載入全部）
List<ChatMessage> loadMessages({int? since});
void clearAll();

// ChatRepo 實作
@override
List<ChatMessage> loadMessages({int? since}) {
  final query = since != null
      ? _box.query(ChatMessage_.timestamp.greaterThan(since))
            .order(ChatMessage_.timestamp, flags: Order.descending)
            .build()
      : _box.query()
            .order(ChatMessage_.timestamp, flags: Order.descending)
            .build()
    ..limit = _maxMessages;
  try {
    return query.find();
  } finally {
    query.close();
  }
}

@override
void clearAll() => _box.removeAll();
```

**新增事件**：
```dart
class GeminiApiClearAllEvent extends GeminiApiEvent {}
```

**BLoC handler**：
```dart
on<GeminiApiClearAllEvent>(_clearAll);

void _clearAll(GeminiApiClearAllEvent event, Emitter<GeminiApiState> emit) {
  _repo.clearAll();
  _chatList = [];
  emit(state.copyWith(
    status: Status.initial,
    chatList: null,
    clearFile: true,
  ));
}
```

---

### 3. 複製對話（Copy All）

**行為**：
- 將 `state.chatList` 格式化為純文字
- 用 `Clipboard.setData()` 複製
- 顯示 `SnackBar` 確認提示：「已複製對話記錄」

**格式化規則**：
- 每條訊息前綴已由 `ChatEntryPrefix` 包裝（`[PROMPT]`、`[AI_REPLY]`、`[ERROR]`）
- 輸出時轉換為可讀前綴：
  - `[PROMPT]` → `👤 You:`
  - `[AI_REPLY]` → `🤖 Gemini:`
  - `[ERROR]` → `⚠️ Error:`
- 訊息間以空行分隔

**不需要新 BLoC event**，直接在 widget 層處理：
```dart
void _copyAllMessages(BuildContext context, List<String> chatList) {
  final buffer = StringBuffer();
  // chatList 是 newest-first，複製時 reversed 為時間順序
  for (final msg in chatList.reversed) {
    final readable = msg
        .replaceFirst('[PROMPT]', '👤 You:')
        .replaceFirst('[AI_REPLY]', '🤖 Gemini:')
        .replaceFirst('[ERROR]', '⚠️ Error:');
    buffer.writeln(readable);
    buffer.writeln();
  }
  Clipboard.setData(ClipboardData(text: buffer.toString()));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(S.current.copiedToClipboard)),
  );
}
```

---

### 4. 關於（About）

**行為**：
- 顯示 `AboutDialog` 或自訂底部 Sheet
- 顯示資訊：App 名稱、版本、目前使用的 AI 模型

**顯示內容**：
```
AI Chat
版本 1.0.0 (build 1)

AI 模型：Gemini 2.5 Flash
提供商：Google Firebase AI
```

**版本取得方式**：使用 `package_info_plus` 套件（需新增依賴）

```dart
// pubspec.yaml 新增
package_info_plus: ^8.1.2

// 使用
final info = await PackageInfo.fromPlatform();
// info.version → "1.0.0"
// info.buildNumber → "1"
```

**替代方案（不加套件）**：直接硬編碼版本字串常數，下次改版時手動更新。建議先用此方式，避免增加依賴。

```dart
// lib/features/foundation/constants/app_constants.dart（新增）
class AppConstants {
  const AppConstants._();
  static const appVersion = '1.0.0';
  static const buildNumber = '1';
  static const aiModel = 'Gemini 2.5 Flash';
  static const aiProvider = 'Google Firebase AI';
}
```

---

## i18n 字串新增

### `intl_zh_TW.arb`

```json
"menuNewChat": "新對話",
"menuClearChat": "清除對話",
"menuCopyAll": "複製對話",
"menuAbout": "關於",
"clearChatTitle": "清除所有對話？",
"clearChatContent": "此操作無法復原，所有對話記錄將被永久刪除。",
"clearChatConfirm": "清除",
"copiedToClipboard": "已複製對話記錄",
"aboutDialogVersion": "版本 {version} (build {build})",
"@aboutDialogVersion": {
  "placeholders": {
    "version": { "type": "String" },
    "build": { "type": "String" }
  }
},
"aboutDialogModel": "AI 模型：{model}",
"@aboutDialogModel": {
  "placeholders": {
    "model": { "type": "String" }
  }
}
```

### `intl_en.arb`

```json
"menuNewChat": "New Chat",
"menuClearChat": "Clear Chat",
"menuCopyAll": "Copy All",
"menuAbout": "About",
"clearChatTitle": "Clear all messages?",
"clearChatContent": "This action cannot be undone. All conversation history will be permanently deleted.",
"clearChatConfirm": "Clear",
"copiedToClipboard": "Conversation copied",
"aboutDialogVersion": "Version {version} (build {build})",
"@aboutDialogVersion": {
  "placeholders": {
    "version": { "type": "String" },
    "build": { "type": "String" }
  }
},
"aboutDialogModel": "AI Model: {model}",
"@aboutDialogModel": {
  "placeholders": {
    "model": { "type": "String" }
  }
}
```

---

## 受影響的檔案

| 檔案 | 異動類型 | 說明 |
|------|---------|------|
| `lib/pages/widgets/ai_chat_view.dart` | 修改 | 實作 `PopupMenuButton`，加入 4 個 menu 項目 |
| `lib/bloc/gemini_api/gemini_api_event.dart` | 修改 | 新增 `GeminiApiNewChatEvent`、`GeminiApiClearAllEvent` |
| `lib/bloc/gemini_api/gemini_api_bloc.dart` | 修改 | 新增 `_newChat`、`_clearAll` handler；調整 `_init` 支援 session 邊界 |
| `lib/data/chat_repository.dart` | 修改 | `loadMessages` 加 `since` 參數；新增 `clearAll()` interface + 實作 |
| `lib/l10n/intl_zh_TW.arb` | 修改 | 新增 8 個字串 |
| `lib/l10n/intl_en.arb` | 修改 | 新增 8 個字串 |
| `lib/features/foundation/constants/app_constants.dart` | 新增 | App 版本、模型名稱常數 |
| `pubspec.yaml` | 修改 | 新增 `shared_preferences` 依賴 |

---

## 實作順序

```
1. pubspec.yaml                ← 新增 shared_preferences 依賴
2. app_constants.dart          ← 無依賴，先建
3. chat_repository.dart        ← loadMessages 加 since 參數；加 clearAll()
4. gemini_api_event.dart       ← 加 2 個 Event
5. gemini_api_bloc.dart        ← 調整 _init 支援 session 邊界；加 _newChat、_clearAll handler
6. intl_zh_TW.arb / intl_en.arb ← 加 i18n 字串
7. make intl                   ← 重新生成 l10n
8. ai_chat_view.dart           ← 最後實作 UI
```

---

## 驗證清單

- [ ] 點擊 `more_vert` 顯示 4 個選項
- [ ] 新對話：畫面清空，DB 資料保留
- [ ] 新對話：重啟 App 後，舊訊息不會出現（session 時間戳正確寫入 SharedPreferences）
- [ ] 清除對話：Dialog 出現 → 取消不刪除 → 確認後清空畫面 + DB
- [ ] 複製對話：SnackBar 出現，剪貼簿內容格式正確（時間順序、前綴可讀）
- [ ] 複製對話：chatList 為空時，複製結果為空字串，SnackBar 仍出現
- [ ] 關於：版本號與 `pubspec.yaml` 一致
- [ ] 所有文字符合 zh_TW / en 雙語
- [ ] `make analyze_lint` 無新增警告
