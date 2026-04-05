# ObjectBox Chat History Cache Design

## 目標

將目前存在記憶體的對話歷史（`_chatList: List<String>`）透過 ObjectBox 持久化，
使對話在 app 重開或 BLoC 重建後仍可還原，同時保持上限 100 筆、圖片 bytes 不落地。

---

## 資料模型

**檔案位置：** `lib/data/chat_message.dart`

```dart
import 'package:objectbox/objectbox.dart';

@Entity()
class ChatMessage {
  @Id()
  int id = 0;

  String content;   // 訊息本文（圖片已替換為佔位符，見 Base64 過濾規則）
  int timestamp;    // Unix ms，用於排序與裁切（DateTime.now().millisecondsSinceEpoch）
  String role;      // "prompt" | "ai_reply" | "error"

  ChatMessage({
    this.id = 0,
    required this.content,
    required this.timestamp,
    required this.role,
  });
}
```

### Role 對應表

| role | 原 `_chatList` 前綴 | 寫入時機 |
|------|------------------|---------|
| `prompt` | `Prompt: ...` | `_query` 開頭，使用者送出後 |
| `ai_reply` | `AI reply: ...` | `Status.success` emit 前，stream 全數收完後 |
| `error` | `Error: ...` | catch 區塊 |

### ObjectBox 產生檔案位置

```
lib/generated/objectbox/          ← objectbox.output_dir（已設定於 pubspec.yaml）
  objectbox.g.dart
  objectbox-model.json
```

---

## 架構

```
main.dart
  └─ openStore() → ChatRepository → GetIt.instance.registerSingleton
       └─ BlocProvider<GeminiApiBloc>(
            create: (_) => GeminiApiBloc(GetIt.instance<ChatRepository>())
          )
```

`GetIt` 作為 service locator，`Store` 與 `ChatRepository` 在 `main()` 中註冊為 singleton，BLoC 直接從 `GetIt` 取用，不依賴 widget tree 傳遞。

**檔案結構（新增）：**

```
lib/
  data/
    chat_message.dart          ← @Entity 定義
    chat_repository.dart       ← 封裝 Box<ChatMessage> 操作
  di/
    injection.dart             ← GetIt 初始化與所有 singleton 註冊
  generated/
    objectbox/                 ← build_runner 產生，勿手動編輯
      objectbox.g.dart
      objectbox-model.json
```

---

## 實作細節

### 1. DI 初始化（`lib/di/injection.dart`）

#### `openStore()` 說明

`openStore()` 是 build_runner 在 `objectbox.g.dart` 自動產生的便利函式，等同於：

```dart
final dir = await getApplicationDocumentsDirectory();
final store = Store(
  getObjectBoxModel(),
  directory: '${dir.path}/objectbox',
);
```

- **`getObjectBoxModel()`**：由 codegen 產生，描述所有 `@Entity` 的 schema
- **`directory`**：資料庫實際落地路徑，位於 app sandbox 內（`Documents/objectbox/`）
- **`Store`**：ObjectBox 的資料庫連線實例，整個 app 生命週期只應存在一個
- 需要 `await` 因為取路徑涉及 async IO（`path_provider`）

`Store` 必須在 app 關閉時呼叫 `store.close()` 釋放資源。透過 GetIt 管理 singleton 後，在 `WidgetsBindingObserver` 或 `runApp` 後的 dispose 時機處理。

```dart
import 'package:get_it/get_it.dart';
import '../data/chat_repository.dart';
import '../generated/objectbox/objectbox.g.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final store = await openStore();   // 取 app Documents 路徑並開啟/建立資料庫
  getIt.registerSingleton<Store>(store);
  getIt.registerSingleton<ChatRepository>(ChatRepository(store));
}

/// app 終止時呼叫，釋放 Store 持有的檔案鎖
void disposeDependencies() {
  getIt<Store>().close();
}
```

### 2. `main.dart` 呼叫 DI 初始化

```dart
import 'di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initLocale();
  await configureDependencies();     // GetIt 註冊完成後才 runApp

  runApp(const MyApp());
}
```

`MyApp` 恢復為無參數的 `const` widget，不需傳入任何依賴。

`Store` 的關閉在 `MyApp` 透過 `WidgetsBindingObserver` 處理：

```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    disposeDependencies();   // store.close()
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ... 其餘不變
      home: const AiChatPage(),
    );
  }
}

### 2. AiChatPage（`lib/pages/ai_chat_page.dart`）

```dart
import 'package:get_it/get_it.dart';
import '../data/chat_repository.dart';

BlocProvider(
  create: (_) => GeminiApiBloc(GetIt.instance<ChatRepository>()),
  child: const AiChatView(),
)
```

### 3. ChatRepository（`lib/data/chat_repository.dart`）

```dart
import 'package:objectbox/objectbox.dart';
import '../generated/objectbox/objectbox.g.dart';
import 'chat_message.dart';

class ChatRepository {
  final Box<ChatMessage> _box;

  ChatRepository(Store store) : _box = store.box<ChatMessage>();

  /// 讀取最新 100 筆，依 timestamp 降序（對應 _chatList.insert(0,...) 的倒序排列）
  List<ChatMessage> loadMessages() {
    return _box
        .query()
        .order(ChatMessage_.timestamp, flags: Order.descending)
        .build()
        .find()
        .take(100)
        .toList();
  }

  /// 寫入一筆並裁切至 100 筆上限
  void saveMessage({required String role, required String content}) {
    _box.put(ChatMessage(
      content: content,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      role: role,
    ));
    _trimToLimit();
  }

  /// 超過 100 筆時刪除最舊的 1 筆
  void _trimToLimit() {
    const limit = 100;
    final count = _box.count();
    if (count > limit) {
      final oldest = _box
          .query()
          .order(ChatMessage_.timestamp)   // 升序，最舊在前
          .build()
          .findFirst();
      if (oldest != null) _box.remove(oldest.id);
    }
  }
}
```

### 4. GeminiApiBloc 變更（`lib/bloc/gemini_api/gemini_api_bloc.dart`）

**建構子改為接收 `ChatRepository`：**

```dart
class GeminiApiBloc extends Bloc<GeminiApiEvent, GeminiApiState> {
  late GenerativeModel _aiModel;
  late List<String> _chatList;
  final ChatRepository _repo;                // 新增

  GeminiApiBloc(this._repo) : super(const GeminiApiState()) {
    // handlers 不變
  }
```

**`_init` 載入歷史：**

```dart
void _init(GeminiApiInitEvent event, Emitter<GeminiApiState> emit) async {
  // 從 ObjectBox 載入，還原前綴格式
  _chatList = _repo.loadMessages().map((m) {
    switch (m.role) {
      case 'prompt':   return 'Prompt: ${m.content}';
      case 'ai_reply': return 'AI reply: ${m.content}';
      default:         return 'Error: ${m.content}';
    }
  }).toList();

  await _initFirebaseAiLogic();
  emit(state.copyWith(chatList: _chatList.isEmpty ? null : _chatList));
}
```

**`_query` 寫入時機（3 個點）：**

```dart
// ① 使用者送出後（成功進入 try 前）
_repo.saveMessage(role: 'prompt', content: _stripBase64(userMessage));

// ② stream 全數完成後（Status.success emit 前）
_repo.saveMessage(role: 'ai_reply', content: _stripContent(_chatList.first));

// ③ catch 區塊
_repo.saveMessage(role: 'error', content: e.toString());
```

### 5. Base64 過濾（私有 helper，置於 bloc 檔內）

```dart
static final _base64ImagePattern = RegExp(
  r'!\[.*?\]\(data:(image/[^;]+);base64,([A-Za-z0-9+/=]+)\)',
);

/// 使用者訊息：base64 圖片替換為帶大小的佔位符
String _stripBase64(String text) {
  return text.replaceAllMapped(_base64ImagePattern, (m) {
    final mime = m.group(1)!;
    final bytes = (m.group(2)!.length * 3 / 4).round();
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);
    return '[附件: $mime, 大小: $mb MB]';
  });
}

/// AI 回覆：base64 圖片替換為固定佔位符
String _stripAiBase64(String text) {
  return text.replaceAll(_base64ImagePattern, '[圖片回覆]');
}

/// 去除 _chatList 項目的前綴（"AI reply: " / "Prompt: "）再過濾
String _stripContent(String item) {
  final content = item.contains(': ') ? item.substring(item.indexOf(': ') + 2) : item;
  return _stripAiBase64(content);
}
```

---

## 資料流總覽

```
_query 觸發
  │
  ├─ 5MB 檢查失敗 → saveMessage(error) → return
  │
  ├─ userMessage = _buildUserMessage(...)
  ├─ _chatList.insert(0, 'Prompt: $userMessage')
  ├─ saveMessage(prompt, _stripBase64(userMessage))   ← ①
  ├─ emit(newPrompt)
  │
  ├─ try:
  │   ├─ stream 逐 chunk 累積 AI 回覆到 _chatList[0]
  │   ├─ emit(loading) per chunk
  │   ├─ stream 結束
  │   ├─ saveMessage(ai_reply, _stripContent(_chatList[0]))  ← ②
  │   └─ emit(success)
  │
  └─ catch:
      ├─ saveMessage(error, e.toString())              ← ③
      └─ emit(failure)
```

---

## 上限策略

- 每次 `saveMessage` → `_trimToLimit()` 檢查 `box.count()`
- `count > 100`：刪除 timestamp 最小（最舊）的 1 筆
- 每次只刪 1 筆（寫入也是 1 筆），保持 count ≤ 100

---

## pubspec.yaml 新增依賴

```yaml
dependencies:
  get_it: ^8.0.0        # service locator
  objectbox: ^5.2.0
  objectbox_flutter_libs: ^5.2.0
```

---

## build_runner 指令

```bash
# 首次產生 objectbox.g.dart
flutter pub run build_runner build --delete-conflicting-outputs

# 開發時持續監聽
flutter pub run build_runner watch --delete-conflicting-outputs
```

產生後 `lib/generated/objectbox/objectbox.g.dart` 與 `objectbox-model.json` 納入版控。

---

## 不在此次範圍內（YAGNI）

- 多對話 session（新建 / 切換歷史）
- 附件 bytes 本地化儲存
- 對話搜尋 / 匯出
