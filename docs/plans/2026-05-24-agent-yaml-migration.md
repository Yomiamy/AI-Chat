# 實作計畫：將 Agent 設定檔轉換為 antigravity-cli 可接受的 YAML 格式

- **日期**：2026-05-24
- **狀態**：已執行完成

## 核心設計決策

### 1. 將 Markdown 檔案 (.md) 轉換為純 YAML 檔案 (.yaml)
**理由**：
- `antigravity-cli` (Gemini CLI) 的自訂 subagent 載入器基於 `LocalAgentConfig` 架構，原生支援純 YAML 格式（`.yaml` 或 `.yml`）。
- 舊的 `.md` 檔案採用 YAML frontmatter 加上 Markdown 系統提示詞的混合格式，而 `antigravity-cli` 的 YAML 解析器無法直接從 frontmatter 外部解析 `system_prompt` 屬性。
- 將檔案轉換為純 YAML，並將原 Markdown 系統提示詞內容對齊縮排，放入 YAML 的 `system_prompt:` 欄位（使用 `|` Block Scalar），可使 `antigravity-cli` 直接載入所有 subagent 參數。

---

## 檔案異動清單

對於 `.agents/agents/` 目錄下的 13 個自訂 Agent 檔案，我們將執行以下轉換：

| 舊檔案路徑 [DELETE] | 新檔案路徑 [NEW] | 異動說明 |
| :--- | :--- | :--- |
| `.agents/agents/architecture-reviewer.md` | `.agents/agents/architecture-reviewer.yaml` | 移除 `---` frontmatter 包圍，將內容整合入 `system_prompt` 欄位。 |
| `.agents/agents/brancher.md` | `.agents/agents/brancher.yaml` | 同上 |
| `.agents/agents/context-collector.md` | `.agents/agents/context-collector.yaml` | 同上 |
| `.agents/agents/feature-worker.md` | `.agents/agents/feature-worker.yaml` | 同上 |
| `.agents/agents/implementer.md` | `.agents/agents/implementer.yaml` | 同上 |
| `.agents/agents/interface-designer.md` | `.agents/agents/interface-designer.yaml` | 同上 |
| `.agents/agents/planner.md` | `.agents/agents/planner.yaml` | 同上 |
| `.agents/agents/publisher.md` | `.agents/agents/publisher.yaml` | 同上 |
| `.agents/agents/release-checker.md` | `.agents/agents/release-checker.yaml` | 同上 |
| `.agents/agents/responder.md` | `.agents/agents/responder.yaml` | 同上 |
| `.agents/agents/reviewer.md` | `.agents/agents/reviewer.yaml` | 同上 |
| `.agents/agents/sdd-planner.md` | `.agents/agents/sdd-planner.yaml` | 同上 |
| `.agents/agents/test-worker.md` | `.agents/agents/test-worker.yaml` | 同上 |

---

## 任務拆分

### Task 1：批次轉換檔案內容與副檔名〔複雜度：中〕
- 讀取每一個 `.agents/agents/<name>.md`。
- 解析 YAML frontmatter 與 Markdown 系統提示詞。
- 生成純 YAML 的屬性樹，並將系統提示詞以 `system_prompt: |` 縮排寫入。
- 將新內容寫入 `.agents/agents/<name>.yaml`。
- 刪除舊的 `.agents/agents/<name>.md`。

---

## 驗證方式

1. 檢查所有 `.agents/agents/` 目錄下的 `.md` 檔案皆已成功移除。
2. 檢查新產出的 `.yaml` 檔案內容語法是否為合法的 YAML，特別是 `system_prompt` 部分的縮排必須完全符合規格。
3. 可使用 Python 輕量測試腳本驗證 YAML 載入無誤。

---

## 風險點

- **YAML 縮排語法**：YAML 的多行純文字區塊（`|`）對縮排極為敏感，必須確保 `system_prompt` 底下的每一行都有正確的 2 格以上縮排，且不破壞原 Markdown 中的格式（如 `#`、`-` 等）。
- **Git 歷史**：此操作涉及刪除與新增檔案，請在執行前確認沒有未 commit 的其他暫存修改。
