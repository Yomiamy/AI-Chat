# 實作計畫：啟動 Timeline Profiling 與 Integration Test 修正

- **日期**：2026-06-07
- **分支**：`feature/202605/test_widget`
- **對應功能規格**：`docs/features/2026-06-07-test-and-startup-timeline.md`
- **定位**：本分支變更**已全部完成並 commit**。本文件為「實作紀錄（How it was done）」加「收尾建議」，非待辦清單。

## 資料結構與設計決策

### `traceCode` extension（核心抽象）
量測能力以 extension on `Function` 的形式存在，而非工具類別或全域函式：

| Extension | 適用 | 底層機制 |
| :--- | :--- | :--- |
| `TraceCode<T> on T Function()` | 同步 callable | `Timeline.startSync` / `finishSync` |
| `TraceCodeAsync<T> on Future<T> Function()` | 非同步 callable | `TimelineTask().start` / `finish` |

設計理由：同步與非同步的 Timeline event 邊界機制不同（async 需 `TimelineTask` 才能正確跨 await 標界），故拆兩個 extension 而非一個。掛在 `Function` 上讓任何 callable 都能 `.traceCode()`，零樣板、可重用。

### `main()` 啟動拓樸
```
ensureInitialized (sync, traceCode)
        │
        ▼
   Future.wait([                    ← 並行
     Firebase.initializeApp,
     _initLocale,
     configureDependencies,
   ])  (各自 traceCodeAsync)
        │ .then
        ▼
   runApp (sync, traceCode)
```

## 已完成的變更對照（依 commit）

| Commit | 檔案 | 內容 | 規格類別 |
| :--- | :--- | :--- | :--- |
| `efe3fea` | `lib/extensions/trace_code.dart`（新）<br>`lib/extensions/extensions.dart`（新 barrel）<br>`lib/main.dart` | 新增 traceCode/traceCodeAsync；main 改用 extension + 並行初始化 | 🎯 主軸一 |
| `2e7df4e` | `lib/main.dart` | （前置）初始化 callback 對應修正、循序啟動 | 🎯 主軸一前身 |
| `226c748` | `test/integration_test/integration_test_1.dart` | await main、測試正名、pump 取代 pumpAndSettle、補註解 | 🎯 主軸二 |
| `3b035c8`/`d406247` | `scripts/gen_test_coverage.sh` | coverage 腳本（branch coverage + 隨機 seed + genhtml） | 📎 附註 |
| `db5412f` | `.claude/hooks/cbm-reindex-on-pr.sh` | Claude cbm 重索引 hook（push/pull/PR） | 📎 附註 |
| `cfdd4fa` | `.agents/hooks.json`、`cbm-reindex-on-sync.sh` | Antigravity cbm hook | 📎 附註 |
| `13d828a` | `docs/...flutter-mcp-integration.md` | ⚠️ 前一工作夾帶，非本次主題 | 切割標注 |

## 收尾建議（非強制，依規格決議「不修碼」故僅列為備查）

依使用者決議，以下兩項**僅標註不修正**，列此供 PR reviewer 與未來追蹤：

1. **並行初始化 race**：`configureDependencies` 與 `Firebase.initializeApp` 並行。若日後 DI 出現依賴 Firebase 就緒的 provider，需改回讓 DI 排在 Firebase 之後。目前接受現狀。
2. **main 提早返回 vs 測試 await**：`main()` 未回傳 `Future.wait`，`integration_test_1.dart` 的 `await app.main()` 實際等不到初始化完成。若該測試在 CI 偶發失敗，優先處理此處（讓 main 回傳 Future 是最小修正）。目前接受現狀。

## 驗證方式

- **Timeline**：`flutter run --profile` → DevTools → Performance，確認啟動期出現 `WidgetsFlutterBinding`、`Firebase.initializeApp`、`initLocale`、`configureDependencies`、`runApp` 五個具名 event。
- **測試**：`flutter test test/integration_test/integration_test_1.dart`（或 `scripts/gen_test_coverage.sh` 跑全套含覆蓋率）。
- **靜態檢查**：`flutter analyze` 應無新增 warning。

## 範圍邊界（同功能規格）
- 不改動業務邏輯 / UI 行為。
- flutter-mcp docs 屬夾帶，PR 描述時與本主軸切割說明。
