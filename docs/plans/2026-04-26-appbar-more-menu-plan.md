# AppBar more_vert Menu Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 實作 `ai_chat_view.dart` AppBar 內 `more_vert` IconButton 的 4 個 menu 項目（New Chat / Clear Chat / Copy All / About），讓使用者能管理對話 session、複製對話、查看 App 資訊。

**Architecture:** 採 BLoC 事件驅動：UI 觸發 menu → dispatch event → BLoC 操作 `ChatRepository` 與 SharedPreferences → emit 新 state。「新對話」用 `session_start_ms` 時間戳寫入 SharedPreferences 作為 session 邊界，`_init` 載入訊息時根據此時間戳過濾。

**Tech Stack:** Flutter / Dart / flutter_bloc / ObjectBox / shared_preferences / intl_utils

**Spec Reference:** `docs/features/20260416-02-25-37-menu-feature-spec.md`

**Pre-existing Code Notes（避免錯誤假設）:**
- `ChatEntryPrefix` 實際前綴是 `'Prompt: '`、`'AI reply: '`、`'Error: '`，**非** spec 寫的 `[PROMPT]` / `[AI_REPLY]` / `[ERROR]`。轉換時用 `ChatEntryPrefix.strip()`。
- `_chatList` 為 newest-first（最新訊息在 index 0），複製時要 `reversed` 才是時間順序。
- `_init` 目前是 `async` 但用 `void` 回傳；新版改為 `Future<void>` 以正確 await SharedPreferences。
- `ChatMessage.timestamp` 型別為 `int`（millisecondsSinceEpoch）。

---

## Task 1: 新增 `shared_preferences` 依賴

**Files:**
- Modify: `pubspec.yaml`（在 `dependencies:` 區塊）

**Step 1: 在 pubspec.yaml 新增依賴**

在 `collection: ^1.19.1` 之後新增：

```yaml
  shared_preferences: ^2.3.3
```

**Step 2: 執行 pub get**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && flutter pub get`
Expected: `Got dependencies!` 且無錯誤

**Step 3: 確認 import 可解析**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && dart -e "import 'package:shared_preferences/shared_preferences.dart';"` 失敗也沒關係，主要看 pub get 是否成功。

執行：`cd /Users/yomiry/AiWorkspace/AI-Chat && grep shared_preferences pubspec.lock | head -3`
Expected: 出現 `shared_preferences:` entry

**Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add shared_preferences dependency for session boundary"
```

---

## Task 2: 建立 `app_constants.dart`

**Files:**
- Create: `lib/features/foundation/constants/app_constants.dart`
- Modify: `lib/features/foundation/foundation.dart`（加 export）
- Test: `test/app_constants_test.dart`

**Step 1: 寫失敗測試**

建立 `test/app_constants_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat/features/foundation/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('appVersion is non-empty', () {
      expect(AppConstants.appVersion, isNotEmpty);
    });

    test('buildNumber is non-empty', () {
      expect(AppConstants.buildNumber, isNotEmpty);
    });

    test('aiModel is non-empty', () {
      expect(AppConstants.aiModel, isNotEmpty);
    });

    test('aiProvider is non-empty', () {
      expect(AppConstants.aiProvider, isNotEmpty);
    });

    test('cannot be instantiated', () {
      // const private constructor — 編譯時就限制；此處純文件用。
      expect(AppConstants.appVersion, equals('1.0.0'));
      expect(AppConstants.buildNumber, equals('1'));
    });
  });
}
```

**Step 2: 執行測試確認失敗**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && flutter test test/app_constants_test.dart`
Expected: FAIL（檔案不存在 / import 找不到）

**Step 3: 建立 `app_constants.dart`**

建立 `lib/features/foundation/constants/app_constants.dart`：

```dart
class AppConstants {
  const AppConstants._();

  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String aiModel = 'Gemini 2.5 Flash';
  static const String aiProvider = 'Google Firebase AI';
}
```

**Step 4: 在 foundation barrel 加 export**

修改 `lib/features/foundation/foundation.dart`：

```dart
export 'constants/app_constants.dart';
export 'extension/extensions.dart';
export 'style/style.dart';
```

**Step 5: 執行測試確認通過**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && flutter test test/app_constants_test.dart`
Expected: PASS（5 tests passed）

**Step 6: Commit**

```bash
git add lib/features/foundation/constants/app_constants.dart \
        lib/features/foundation/foundation.dart \
        test/app_constants_test.dart
git commit -m "feat(foundation): add AppConstants for version and AI model info"
```

---

## Task 3: 擴充 `ChatRepository`：`loadMessages(since:)` 與 `clearAll()`

**Files:**
- Modify: `lib/data/chat_repository.dart`
- Test: `integration_test/chat_repository_test.dart`（若不存在則建立；ObjectBox 需 native lib，無法在 unit test 跑）

**Step 1: 修改 `ChatRepository` interface**

在 `lib/data/chat_repository.dart` 修改 abstract interface：

```dart
abstract interface class ChatRepository {
  /// Returns up to [_maxMessages] messages ordered newest-first.
  /// If [since] is provided, only messages with `timestamp > since` are returned.
  List<ChatMessage> loadMessages({int? since});

  void saveMessage({required ChatMessageRoleEnum role, required String content});

  /// Removes ALL messages from the store. Irreversible.
  void clearAll();

  void dispose();
}
```

**Step 2: 修改 `ChatRepo` 實作**

替換 `loadMessages` 方法：

```dart
@override
List<ChatMessage> loadMessages({int? since}) {
  final builder = since != null
      ? _box.query(ChatMessage_.timestamp.greaterThan(since))
      : _box.query();
  final query = (builder
        ..order(ChatMessage_.timestamp, flags: Order.descending))
      .build()
    ..limit = _maxMessages;
  try {
    return query.find();
  } finally {
    query.close();
  }
}
```

新增 `clearAll`（放在 `dispose` 之前）：

```dart
@override
void clearAll() => _box.removeAll();
```

**Step 3: 執行 analyze 確認無語法錯誤**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && dart analyze lib/data/chat_repository.dart`
Expected: 無 error（warnings 可接受）

**Step 4: 加 integration test（若已有檔案則 append）**

檢查 `integration_test/chat_repository_test.dart` 是否存在：
Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && ls integration_test/ 2>/dev/null`

若**不存在**，跳過此 step（單元測試覆蓋率不要求）。
若**存在**，append 以下兩個 test case：

```dart
test('loadMessages with since filters older messages', () async {
  final repo = await ChatRepo.create();
  final t0 = DateTime.now().millisecondsSinceEpoch;
  repo.saveMessage(role: ChatMessageRoleEnum.prompt, content: 'old');
  await Future.delayed(const Duration(milliseconds: 10));
  final boundary = DateTime.now().millisecondsSinceEpoch;
  await Future.delayed(const Duration(milliseconds: 10));
  repo.saveMessage(role: ChatMessageRoleEnum.aiReply, content: 'new');

  final filtered = repo.loadMessages(since: boundary);
  expect(filtered.length, 1);
  expect(filtered.first.content, 'new');

  repo.clearAll();
  repo.dispose();
});

test('clearAll removes all messages', () async {
  final repo = await ChatRepo.create();
  repo.saveMessage(role: ChatMessageRoleEnum.prompt, content: 'a');
  repo.saveMessage(role: ChatMessageRoleEnum.aiReply, content: 'b');
  expect(repo.loadMessages().length, greaterThanOrEqualTo(2));

  repo.clearAll();
  expect(repo.loadMessages(), isEmpty);

  repo.dispose();
});
```

**Step 5: 全專案 analyze**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && make analyze_lint`
Expected: 無新增 error

**Step 6: Commit**

```bash
git add lib/data/chat_repository.dart integration_test/ 2>/dev/null || \
  git add lib/data/chat_repository.dart
git commit -m "feat(data): add since filter to loadMessages and clearAll method"
```

---

## Task 4: 新增 BLoC events `GeminiApiNewChatEvent` 與 `GeminiApiClearAllEvent`

**Files:**
- Modify: `lib/bloc/gemini_api/gemini_api_event.dart`

**Step 1: 在 event 檔尾端新增兩個 event 類別**

修改 `lib/bloc/gemini_api/gemini_api_event.dart`，在 `class GeminiApiRemoveFileEvent extends GeminiApiEvent {}` 之後新增：

```dart
class GeminiApiNewChatEvent extends GeminiApiEvent {}

class GeminiApiClearAllEvent extends GeminiApiEvent {}
```

**Step 2: 執行 analyze 確認語法**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && dart analyze lib/bloc/gemini_api/gemini_api_event.dart`
Expected: 無 error

**Step 3: Commit**

```bash
git add lib/bloc/gemini_api/gemini_api_event.dart
git commit -m "feat(bloc): add GeminiApiNewChatEvent and GeminiApiClearAllEvent"
```

---

## Task 5: 修改 `_init` 支援 session 邊界

**Files:**
- Modify: `lib/bloc/gemini_api/gemini_api_bloc.dart`

**Step 1: 在檔頂新增 import**

在 `lib/bloc/gemini_api/gemini_api_bloc.dart` 的 imports 區塊新增：

```dart
import 'package:shared_preferences/shared_preferences.dart';
```

**Step 2: 在 class 內新增 SharedPreferences key 常數**

在 `class GeminiApiBloc` 內、`_base64ImagePattern` 之後新增：

```dart
static const String _sessionStartKey = 'session_start_ms';
```

**Step 3: 修改 `_init` 函式（讀取 session 邊界）**

替換 `_init` 內容：

```dart
void _init(GeminiApiInitEvent event, Emitter<GeminiApiState> emit) async {
  final prefs = await SharedPreferences.getInstance();
  final sessionStartMs = prefs.getInt(_sessionStartKey);

  _chatList = _repo.loadMessages(since: sessionStartMs).map((m) {
    return switch (m.roleEnum) {
      ChatMessageRoleEnum.prompt  => ChatEntryPrefix.prompt.wrap(m.content),
      ChatMessageRoleEnum.aiReply => ChatEntryPrefix.aiReply.wrap(m.content),
      _                           => ChatEntryPrefix.error.wrap(m.content),
    };
  }).toList();

  await _initFirebaseAiLogic();
  emit(state.copyWith(chatList: _chatList.isEmpty ? null : _chatList));
}
```

**Step 4: 執行 analyze**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && dart analyze lib/bloc/gemini_api/gemini_api_bloc.dart`
Expected: 無 error

**Step 5: Commit**

```bash
git add lib/bloc/gemini_api/gemini_api_bloc.dart
git commit -m "feat(bloc): filter loaded messages by session_start_ms boundary"
```

---

## Task 6: 新增 `_newChat` handler

**Files:**
- Modify: `lib/bloc/gemini_api/gemini_api_bloc.dart`

**Step 1: 註冊 event handler**

在 `GeminiApiBloc` constructor 中、`on<GeminiApiRemoveFileEvent>(_removeFile);` 之後新增：

```dart
on<GeminiApiNewChatEvent>(_newChat);
```

**Step 2: 實作 `_newChat`**

在 `_removeFile` 之後新增：

```dart
Future<void> _newChat(
  GeminiApiNewChatEvent event,
  Emitter<GeminiApiState> emit,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_sessionStartKey, DateTime.now().millisecondsSinceEpoch);
  _chatList = [];
  emit(state.copyWith(
    status: Status.initial,
    chatList: null,
    clearFile: true,
  ));
}
```

**Step 3: 執行 analyze**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && dart analyze lib/bloc/gemini_api/gemini_api_bloc.dart`
Expected: 無 error

**Step 4: Commit**

```bash
git add lib/bloc/gemini_api/gemini_api_bloc.dart
git commit -m "feat(bloc): add _newChat handler writes session_start_ms and clears UI"
```

---

## Task 7: 新增 `_clearAll` handler

**Files:**
- Modify: `lib/bloc/gemini_api/gemini_api_bloc.dart`

**Step 1: 註冊 event handler**

在 constructor 中、`on<GeminiApiNewChatEvent>(_newChat);` 之後新增：

```dart
on<GeminiApiClearAllEvent>(_clearAll);
```

**Step 2: 實作 `_clearAll`**

在 `_newChat` 之後新增：

```dart
void _clearAll(
  GeminiApiClearAllEvent event,
  Emitter<GeminiApiState> emit,
) {
  _repo.clearAll();
  _chatList = [];
  emit(state.copyWith(
    status: Status.initial,
    chatList: null,
    clearFile: true,
  ));
}
```

**Step 3: 執行 analyze**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && dart analyze lib/bloc/gemini_api/gemini_api_bloc.dart`
Expected: 無 error

**Step 4: Commit**

```bash
git add lib/bloc/gemini_api/gemini_api_bloc.dart
git commit -m "feat(bloc): add _clearAll handler removes all DB messages and clears UI"
```

---

## Task 8: 新增 i18n 字串（zh_TW + en）

**Files:**
- Modify: `lib/l10n/intl_zh_TW.arb`
- Modify: `lib/l10n/intl_en.arb`

**Step 1: 修改 `intl_zh_TW.arb`**

在最後一個 entry 後（`"goToSettings"` 之後）插入：

```json
,
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

**Step 2: 修改 `intl_en.arb`**

在最後一個 entry 後（`"goToSettings"` 之後）插入：

```json
,
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

**Step 3: 確認 JSON 合法**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && python3 -c "import json; json.load(open('lib/l10n/intl_zh_TW.arb'))" && python3 -c "import json; json.load(open('lib/l10n/intl_en.arb'))"`
Expected: 無輸出（=合法 JSON）

**Step 4: 重新生成 l10n**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && make intl`
Expected: 重新生成 `lib/generated/l10n.dart`，無 error

**Step 5: 確認 generated key 存在**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && grep -c "menuNewChat\|clearChatTitle\|copiedToClipboard\|aboutDialogVersion" lib/generated/l10n.dart`
Expected: 數字 ≥ 4

**Step 6: Commit**

```bash
git add lib/l10n/intl_zh_TW.arb lib/l10n/intl_en.arb lib/generated/l10n.dart
git commit -m "feat(i18n): add menu and dialog strings for zh_TW and en"
```

---

## Task 9: 在 `ai_chat_view.dart` 實作 `PopupMenuButton` 骨架

**Files:**
- Modify: `lib/pages/widgets/ai_chat_view.dart`

**Step 1: 新增 imports**

在現有 imports 區塊新增（注意已有 `flutter/material.dart`）：

```dart
import 'package:flutter/services.dart'; // Clipboard
```

**Step 2: 在 `_AiChatViewState` 上方新增 menu action enum**

在檔案 line 12（`class AiChatView extends StatefulWidget` 之前）新增：

```dart
enum _MenuAction { newChat, clearChat, copyAll, about }
```

**Step 3: 替換 `more_vert` IconButton 為 PopupMenuButton**

把 `actions: [...]` 內的 IconButton（line 71-74）替換為：

```dart
actions: [
  PopupMenuButton<_MenuAction>(
    icon: const Icon(Icons.more_vert, color: ColorName.color8a000000),
    onSelected: (action) => _onMenuSelected(context, action),
    itemBuilder: (_) => [
      PopupMenuItem(
        value: _MenuAction.newChat,
        child: Row(children: [
          const Icon(Icons.add_comment_outlined),
          const SizedBox(width: Sizes.paddingS),
          Text(S.current.menuNewChat),
        ]),
      ),
      PopupMenuItem(
        value: _MenuAction.clearChat,
        child: Row(children: [
          const Icon(Icons.delete_outline),
          const SizedBox(width: Sizes.paddingS),
          Text(S.current.menuClearChat),
        ]),
      ),
      PopupMenuItem(
        value: _MenuAction.copyAll,
        child: Row(children: [
          const Icon(Icons.copy_outlined),
          const SizedBox(width: Sizes.paddingS),
          Text(S.current.menuCopyAll),
        ]),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: _MenuAction.about,
        child: Row(children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: Sizes.paddingS),
          Text(S.current.menuAbout),
        ]),
      ),
    ],
  ),
],
```

**Step 4: 在 `_AiChatViewState` 加入 `_onMenuSelected` 路由（先放空殼）**

在 `_scrollToBottom` 之前（或檔尾、build 方法外）新增：

```dart
void _onMenuSelected(BuildContext context, _MenuAction action) {
  switch (action) {
    case _MenuAction.newChat:
      context.read<GeminiApiBloc>().add(GeminiApiNewChatEvent());
      break;
    case _MenuAction.clearChat:
      _confirmClearChat(context);
      break;
    case _MenuAction.copyAll:
      _copyAllMessages(context);
      break;
    case _MenuAction.about:
      _showAboutDialog(context);
      break;
  }
}

void _confirmClearChat(BuildContext context) {
  // Implemented in Task 10
}

void _copyAllMessages(BuildContext context) {
  // Implemented in Task 11
}

void _showAboutDialog(BuildContext context) {
  // Implemented in Task 12
}
```

**Step 5: 執行 analyze**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && dart analyze lib/pages/widgets/ai_chat_view.dart`
Expected: 可能會 warning「方法為空」，但無 error

**Step 6: Commit**

```bash
git add lib/pages/widgets/ai_chat_view.dart
git commit -m "feat(ui): add PopupMenuButton skeleton with 4 menu items and routing"
```

---

## Task 10: 實作「清除對話」確認 Dialog

**Files:**
- Modify: `lib/pages/widgets/ai_chat_view.dart`

**Step 1: 替換 `_confirmClearChat`**

```dart
void _confirmClearChat(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(S.current.clearChatTitle),
      content: Text(S.current.clearChatContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(S.current.cancel),
        ),
        TextButton(
          onPressed: () {
            context.read<GeminiApiBloc>().add(GeminiApiClearAllEvent());
            Navigator.of(dialogContext).pop();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(S.current.clearChatConfirm),
        ),
      ],
    ),
  );
}
```

**Step 2: 執行 analyze**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && dart analyze lib/pages/widgets/ai_chat_view.dart`
Expected: 無 error

**Step 3: Commit**

```bash
git add lib/pages/widgets/ai_chat_view.dart
git commit -m "feat(ui): add confirmation dialog for clear chat"
```

---

## Task 11: 實作「複製對話」

**Files:**
- Modify: `lib/pages/widgets/ai_chat_view.dart`

**Step 1: 在檔頂新增 import**

```dart
import '../../bloc/gemini_api/models/chat_entry_prefix.dart';
```

（若 `bloc/bloc.dart` 已 export `chat_entry_prefix.dart` 則跳過此 step——先檢查：`grep "chat_entry_prefix" lib/bloc/bloc.dart`）

**Step 2: 替換 `_copyAllMessages`**

```dart
void _copyAllMessages(BuildContext context) {
  final state = context.read<GeminiApiBloc>().state;
  final chatList = state.chatList ?? const <String>[];

  final buffer = StringBuffer();
  // chatList 為 newest-first，reversed 才是時間順序
  for (final entry in chatList.reversed) {
    final prefix = ChatEntryPrefix.of(entry);
    final readable = switch (prefix) {
      ChatEntryPrefix.prompt  => '👤 You: ${ChatEntryPrefix.prompt.strip(entry)}',
      ChatEntryPrefix.aiReply => '🤖 Gemini: ${ChatEntryPrefix.aiReply.strip(entry)}',
      ChatEntryPrefix.error   => '⚠️ Error: ${ChatEntryPrefix.error.strip(entry)}',
      _                       => entry,
    };
    buffer.writeln(readable);
    buffer.writeln();
  }

  Clipboard.setData(ClipboardData(text: buffer.toString()));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(S.current.copiedToClipboard)),
  );
}
```

**Step 3: 執行 analyze**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && dart analyze lib/pages/widgets/ai_chat_view.dart`
Expected: 無 error

**Step 4: Commit**

```bash
git add lib/pages/widgets/ai_chat_view.dart
git commit -m "feat(ui): implement copy all messages with readable prefixes"
```

---

## Task 12: 實作「關於」Dialog

**Files:**
- Modify: `lib/pages/widgets/ai_chat_view.dart`

**Step 1: 在 imports 加入 features barrel**

確認已 import（若無則加）：

```dart
import '../../features/features.dart';
```

或直接 import：

```dart
import '../../features/foundation/constants/app_constants.dart';
```

擇一即可（先用 `grep "features/features.dart\|app_constants.dart" lib/pages/widgets/ai_chat_view.dart` 檢查）。

**Step 2: 替換 `_showAboutDialog`**

```dart
void _showAboutDialog(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: S.current.appTitle,
    applicationVersion: S.current.aboutDialogVersion(
      AppConstants.appVersion,
      AppConstants.buildNumber,
    ),
    applicationIcon: const CircleAvatar(
      backgroundColor: ColorName.colorFf673ab7,
      child: Icon(
        Icons.auto_awesome,
        color: ColorName.colorFfffffff,
      ),
    ),
    children: [
      const SizedBox(height: Sizes.paddingM),
      Text(S.current.aboutDialogModel(AppConstants.aiModel)),
      const SizedBox(height: Sizes.paddingS),
      Text(AppConstants.aiProvider),
    ],
  );
}
```

**Step 3: 執行 analyze**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && dart analyze lib/pages/widgets/ai_chat_view.dart`
Expected: 無 error

**Step 4: Commit**

```bash
git add lib/pages/widgets/ai_chat_view.dart
git commit -m "feat(ui): implement about dialog with version and AI model info"
```

---

## Task 13: 全專案 lint + 手動驗證

**Files:**
- 無檔案異動，純驗證

**Step 1: 跑全專案 analyze**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && make analyze_lint`
Expected: 無新增 error/warning

**Step 2: 跑所有 unit tests**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && flutter test`
Expected: 全部 PASS

**Step 3: 手動驗證清單（在 device/simulator 上跑 app）**

Run: `cd /Users/yomiry/AiWorkspace/AI-Chat && flutter run`

逐項驗證（參考 `docs/features/20260416-02-25-37-menu-feature-spec.md` § 驗證清單）：

- [ ] 點擊 `more_vert` 顯示 4 個選項，About 與其他間有 Divider
- [ ] 新對話：畫面清空，DB 資料保留
- [ ] 新對話：重啟 App 後舊訊息**不**重新出現
- [ ] 清除對話：Dialog 出現 → 取消不刪除 → 確認後清空畫面 + DB（重啟後也是空）
- [ ] 複製對話：SnackBar 出現「已複製對話記錄」
- [ ] 複製對話：剪貼簿內容為時間順序（先 prompt 後 reply），且帶可讀前綴
- [ ] 複製對話：chatList 為空時，剪貼簿是空字串，SnackBar 仍出現
- [ ] 關於：Dialog 顯示版本號（與 `pubspec.yaml` 的 `1.0.0+1` 對應）、AI 模型「Gemini 2.5 Flash」、Provider「Google Firebase AI」
- [ ] 切換語系（zh_TW / en）皆顯示對應字串

**Step 4: 若全部通過，建立 verification commit（無檔案改動可跳過）**

若 manual QA 過程中發現微調，commit 修正；否則直接進 PR 流程。

---

## 完成後

實作全部完成後，執行：

1. `git log --oneline main..HEAD` 確認 commits 連貫
2. `gh pr create` 建立 PR，描述連結 Issue #23

---

## Plan complete

Plan complete and saved to `docs/plans/2026-04-26-appbar-more-menu-plan.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**
