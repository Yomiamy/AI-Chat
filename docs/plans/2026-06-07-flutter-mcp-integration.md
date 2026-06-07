# 實作計畫：整合 flutter-mcp 至 Antigravity CLI MCP 配置

- **日期**：2026-06-07
- **狀態**：已執行完成

## 核心設計決策

### 1. 使用 `npx -y` 而非全域安裝
**理由**：
- `npx -y flutter-mcp` 每次啟動會自動解析最新版本，無需手動 `npm update`。
- 不污染全域 `node_modules`，保持環境乾淨。
- 與團隊其他成員共享配置時，無需額外安裝步驟。

### 2. 配置在全域 `mcp_config.json` 而非專案層級
**理由**：
- `flutter-mcp` 是通用的 Flutter/Dart 文檔查詢工具，不限於特定專案。
- 全域配置 (`~/.gemini/config/mcp_config.json`) 讓所有 Flutter 專案都能受惠。
- 專案層級已有 `dart-mcp-server`（透過 Flutter plugin 的 `mcp_config.json`），職責分離清晰。

### 3. 不與 `dart-mcp-server` 合併或取代
**理由**：
- `dart-mcp-server`（官方）負責**專案工具鏈**：分析、格式化、測試、熱重載。
- `flutter-mcp`（社群）負責**文檔查詢**：最新 API 文檔、pub.dev 套件資訊。
- 兩者功能正交，互不干擾，合併只會增加不必要的耦合。

---

## 檔案異動清單

| 檔案路徑 | 異動類型 | 說明 |
| :--- | :--- | :--- |
| `~/.gemini/config/mcp_config.json` | MODIFIED | 新增 `flutter-mcp` 條目至 `mcpServers` |
| `docs/features/2026-06-07-flutter-mcp-integration.md` | NEW | 功能規格文件 |
| `docs/plans/2026-06-07-flutter-mcp-integration.md` | NEW | 本實作計畫 |

---

## 任務拆分

### Task 1：修改全域 MCP 配置〔複雜度：低〕
- 讀取 `~/.gemini/config/mcp_config.json`。
- 在 `mcpServers` 物件中新增 `flutter-mcp` 條目。
- 寫回檔案，確保 JSON 格式正確且不破壞既有條目。

### Task 2：撰寫 Feature 文件〔複雜度：低〕
- 依循 `docs/features/` 既有格式（日期、狀態、What & Why、使用者故事、驗收條件、範圍邊界）。
- 說明 `flutter-mcp` 的定位與 `dart-mcp-server` 的分工。

### Task 3：撰寫 Plan 文件〔複雜度：低〕
- 依循 `docs/plans/` 既有格式（日期、狀態、設計決策、檔案異動、任務拆分、驗證方式、風險點）。

---

## 驗證方式

1. **配置驗證**：讀取 `mcp_config.json`，確認 `flutter-mcp` 條目存在且 JSON 語法合法。
2. **既有配置完整性**：確認 `dart-mcp-server`、`GitKraken`、`codebase-memory-mcp` 三個既有條目未被修改或刪除。
3. **執行驗證**：重啟 Antigravity CLI，確認 `flutter-mcp` 出現在 MCP Server 列表中（需使用者手動驗證）。

---

## 風險點

- **`npx` 首次冷啟動延遲**：第一次執行 `npx -y flutter-mcp` 會下載套件，可能需要 10-30 秒。後續執行會有 cache，啟動速度正常。如果延遲不可接受，可改為 `npm install -g flutter-mcp` 全域安裝。
- **Node.js 版本相容**：`flutter-mcp` 是 Node.js 套件，需要系統安裝 Node.js。本專案環境已有 `npx`（透過 Node.js），不需額外處理。
- **MCP Server 命名衝突**：配置中的 key 為 `flutter-mcp`，與 Flutter plugin 層的 `dart`（在 `plugins/flutter/mcp_config.json`）不衝突。
