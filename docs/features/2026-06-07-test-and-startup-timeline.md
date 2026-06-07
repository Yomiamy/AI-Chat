# 功能規格：啟動 Timeline Profiling 與 Integration Test 修正

- **日期**：2026-06-07
- **分支**：`feature/202605/test_widget`
- **狀態**：變更已完成並 commit，本規格為事後補述（What & Why）

## What & Why

本分支聚焦兩條主軸：**App 啟動流程的 Timeline 量測** 與 **AppBar 搜尋 Integration Test 的修正**。其餘為開發工具鏈的輔助變更，附註說明。

---

## 主軸一：啟動 Timeline Profiling（`lib/main.dart` + `lib/extensions/trace_code.dart`）

### 背景與痛點
原本 `main()` 的初始化是一串裸 `await`：

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();
await _initLocale();
await configureDependencies();
runApp(const MyApp());
```

各階段耗時不可見。當啟動變慢時，無法分辨是 Firebase 初始化、依賴注入、還是 locale 載入造成的，只能靠猜。

### 目標
1. 為每個啟動階段加上 Timeline event，讓 DevTools Timeline / Performance view 能逐段量測耗時。
2. 把「量測一段程式碼耗時」抽成可重用的 extension，而非散落各處手寫 `Timeline` 呼叫。

### 變更內容

**(1) 新增 `traceCode` extension（`lib/extensions/trace_code.dart`）**
把 Timeline 量測抽象成掛在 callable 上的擴充方法：
- `TraceCode<T> on T Function()` → `traceCode(name)`：包 `Timeline.startSync` / `finishSync`，量測同步區段。
- `TraceCodeAsync<T> on Future<T> Function()` → `traceCodeAsync(name)`：用 `TimelineTask().start/finish`，正確量測非同步區段（async 區段不能用 sync 版，否則 event 邊界錯亂）。

呼叫風格從 `Timeline.timeSync('name', fn)` 改為 `fn.traceCode('name')` / `fn.traceCodeAsync('name')`，更乾淨且可重用於任何 callable。透過 barrel `lib/extensions/extensions.dart` 匯出。

**(2) `main()` 改用 extension 並改為並行初始化**
```dart
WidgetsFlutterBinding.ensureInitialized.traceCode('WidgetsFlutterBinding');

Future.wait([
  Firebase.initializeApp.traceCodeAsync('Firebase.initializeApp'),
  _initLocale.traceCodeAsync('initLocale'),
  configureDependencies.traceCodeAsync('configureDependencies'),
]).then((_) {
  (() => runApp(const MyApp())).traceCode('runApp');
});
```

- binding 初始化（同步）用 `traceCode`。
- Firebase / locale / DI 三者用 `traceCodeAsync` 並以 `Future.wait` **並行**執行，三者完成後才 `runApp`。
- 較舊版（`2e7df4e` 的循序 await）改為並行，理論上可縮短總啟動時間。

### 使用者故事
1. **作為 RD**，我想在 DevTools Timeline 看到每個啟動階段的耗時，這樣排查啟動效能時能直接定位瓶頸，而不是逐行加 log 猜測。
2. **作為 RD**，我想要一個可重用的量測工具，這樣未來要 profile 其他程式區段時直接 `.traceCode()` 即可，不必重寫 Timeline 樣板。

### 驗收條件
- [x] `traceCode` / `traceCodeAsync` extension 存在並由 barrel 匯出。
- [x] `main()` 各初始化階段產生具名 Timeline event。
- [x] DevTools Timeline 可見各段 event。

### ⚠️ 待驗證的技術疑慮（須在審查/PR 中釐清）
1. **並行初始化的相依安全性**：`configureDependencies`（DI）與 `Firebase.initializeApp` 現在並行執行。若 DI 註冊過程中有任何 provider 依賴「Firebase 已初始化」，會構成 race condition。需確認三者彼此真正獨立，否則並行不安全。
2. **`main()` 提早返回**：新版以 `.then()` 串接 `runApp`，`main()` 本身不再 `await` `Future.wait`。這會影響呼叫端對「main 完成 = App 就緒」的假設——特別是下面主軸二的 integration test 寫了 `await app.main()`，但 await 一個沒回傳該 Future 的 main 等於沒等到初始化完成（見主軸二的衝突備註）。

---

## 主軸二：AppBar 搜尋 Integration Test 修正（`test/integration_test/integration_test_1.dart`）

### 背景與痛點
既有測試 `test appbar title` 有兩個會導致不穩定／失敗的問題：
1. `app.main()` 沒有 `await`——但 `main()` 是 async（內含 `Firebase.initializeApp` 等 await），不等它完成就往下跑，初始化時序不確定。
2. 點擊搜尋後用 `pumpAndSettle()` 等待——但 chat 初始畫面有 `CircularProgressIndicator`（無限動畫），永遠 settle 不了，測試會卡死／逾時。

### 目標
讓這條 integration test 穩定、語意正確地驗證「點搜尋 icon → 顯示 `SearchAppBar`」的行為。

### 變更內容
- `app.main()` → `await app.main()`，正確等待 async 初始化完成。
- 測試名稱正名：`test appbar title` → `tapping search icon shows SearchAppBar`，名稱如實反映斷言。
- 點擊後的等待由 `pumpAndSettle()` 改為 `pump()`——`_isSearching` 由 `setState` 同步切換，pump 一幀即完成 AppBar 替換，不需也不能 settle。
- 補上關鍵註解，說明「為何必須 await」與「為何不能用 pumpAndSettle」，避免後人踩同一個坑。

### 使用者故事
1. **作為 RD**，我想要一條穩定不卡死的 integration test 來守護 AppBar 搜尋功能，這樣改動 AppBar 時能即時抓到回歸。

### 驗收條件
- [x] `await app.main()` 正確等待初始化。
- [x] 測試不再因無限動畫卡在 `pumpAndSettle`。
- [x] 斷言 `find.byType(SearchAppBar)` 在點擊搜尋 icon 後通過。
- [x] 關鍵時序決策有註解佐證。

### ⚠️ 與主軸一的潛在衝突
測試寫 `await app.main()` 預期等到初始化完成，但主軸一新版 `main()` 改用 `Future.wait(...).then(...)` 且**不回傳該 Future**——`await` 一個提早返回的 `main()` 形同沒等。在 `IntegrationTestWidgetsFlutterBinding` 下測試可能在初始化未完成時就開始 pump，造成偶發失敗。兩個 commit（`226c748` 測試、`efe3fea` main）需在審查時一併評估：要嘛讓 `main()` 回傳可 await 的 Future，要嘛測試改用其他就緒訊號。

---

## 附註：輔助工具鏈變更（非本次主軸，簡述）

以下變更屬開發工具鏈強化，與上述兩條主軸獨立，列此備查：

| 變更 | 檔案 | 說明 |
| :--- | :--- | :--- |
| Test coverage 腳本 | `scripts/gen_test_coverage.sh` | 一鍵產生覆蓋率報告：`flutter test --coverage --branch-coverage` 搭配隨機測試順序 seed，`genhtml` 輸出 HTML 並開啟。 |
| Claude cbm hook | `.claude/hooks/cbm-reindex-on-pr.sh` | Claude Code 的 PostToolUse(Bash) hook，偵測 `git push`／`git pull`／`gh pr create` 後背景重新索引 codebase-memory（fast mode）。用 shlex tokenize 避免誤判 commit message 內的 "push"。 |
| Antigravity cbm hook | `.agents/hooks.json`、`.claude/hooks/cbm-reindex-on-sync.sh` | 同等功能的 Antigravity (`agy`) 版本，差別在讀取 `agy` 的 `toolCall.args.CommandLine` schema（matcher 為 `run_command`）。 |

## 範圍邊界

### 包含
- `lib/main.dart` 啟動 Timeline 量測（並行初始化）
- `lib/extensions/trace_code.dart` + `extensions.dart` barrel（`traceCode` / `traceCodeAsync` extension）
- `integration_test_1.dart` 測試修正
- 上述三項工具鏈附註變更

### 不包含 / 既有夾帶
- ⚠️ `docs/features/2026-06-07-flutter-mcp-integration.md` 與 `docs/plans/2026-06-07-flutter-mcp-integration.md`：屬**前一個無關工作**（flutter-mcp MCP 配置）留下的文件，雖在本分支 diff 中，**不屬本次主題**。PR 描述時應與本次主軸切割說明，或考慮另行歸屬。
- ❌ 不改動任何業務邏輯 / UI 行為（main.dart 為純量測包覆）。
