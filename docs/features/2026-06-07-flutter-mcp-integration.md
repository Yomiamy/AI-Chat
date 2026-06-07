# 功能規格：整合 flutter-mcp（Flutter/Dart 文檔即時查詢 MCP Server）

- **日期**：2026-06-07
- **狀態**：已完成 ✦

## What & Why

### 背景
AI-Chat 是 Flutter 專案，開發時大量依賴 AI 助手（Gemini CLI / Antigravity CLI）進行編碼、重構與問題排查。目前已配置官方 `dart-mcp-server`（Dart SDK 內建），提供分析、格式化、熱重載等核心工具。

然而，AI 助手在生成 Flutter/Dart 程式碼時，常因訓練資料時間差而使用**過時或已棄用的 API**，例如：
- 已移除的 `FlatButton`、`RaisedButton`（應為 `TextButton`、`ElevatedButton`）
- 過期的 `pub.dev` 套件版本或已更名的 API
- Material 2 vs Material 3 的 Widget 差異

### 目標
整合 [adamsmaka/flutter-mcp](https://github.com/adamsmaka/flutter-mcp)，讓 AI 助手在編碼時能**即時查詢最新 Flutter/Dart 官方文檔與 pub.dev 套件資訊**，從源頭消滅「API 幻覺」問題。

### 與 dart-mcp-server 的分工
| 工具 | 定位 | 核心功能 |
| :--- | :--- | :--- |
| `dart-mcp-server`（官方） | 專案生命週期工具 | 分析、格式化、測試、熱重載、Widget 樹檢視 |
| `flutter-mcp`（社群） | 文檔即時查詢 | 版本特定文檔、pub.dev 套件搜尋、API 變更追蹤 |

兩者互補，不重疊。

## 使用者故事

1. **作為 RD**，我想讓 AI 助手在寫 Flutter 程式碼時，能查到我目前 SDK 版本對應的最新 API 文檔，而不是用過時的 Widget。
2. **作為 RD**，我想讓 AI 助手搜尋 pub.dev 時，能取得套件的最新版本號、changelog 與 API 介面，避免推薦已棄用的套件。
3. **作為 RD**，我想在 AI 助手建議我使用某個 API 時，它能引用官方文檔作為依據，而不是單靠訓練資料猜測。

## 安裝方式

在全域 MCP 配置 (`~/.gemini/config/mcp_config.json`) 中新增：

```json
"flutter-mcp": {
    "command": "npx",
    "args": ["-y", "flutter-mcp"]
}
```

透過 `npx -y` 執行，無需全域安裝，每次啟動自動拉取最新版。

## 驗收條件

- [x] `~/.gemini/config/mcp_config.json` 包含 `flutter-mcp` 條目。
- [x] `command` 為 `npx`，`args` 為 `["-y", "flutter-mcp"]`。
- [x] 不影響既有 `dart-mcp-server`、`GitKraken`、`codebase-memory-mcp` 配置。
- [ ] 重啟 Antigravity CLI 後，`flutter-mcp` 出現在可用 MCP Server 列表中。

## 範圍邊界

### 包含
- 全域 MCP 配置新增 `flutter-mcp`
- Feature / Plan 文件撰寫

### 不包含（明確排除）
- ❌ `figma-flutter-mcp`（需 Figma API Key，待使用者提供後另行處理）
- ❌ `flutter-mcp-toolkit` / `mcp_flutter`（App 內 MCP runtime，本專案暫不需要）
- ❌ `flutter-dev-agents`（自動化測試 MCP，待需求出現再評估）
- ❌ 修改任何 Flutter 專案原始碼

## 關鍵備註

- `flutter-mcp` 使用 **stdio** transport，與 Antigravity CLI 原生相容。
- `npx -y` 策略確保每次啟動拉最新版，不需手動維護版本。
- 若日後需要離線使用，可改為 `npm install -g flutter-mcp` 全域安裝，並將 `command` 改為 `flutter-mcp`。
