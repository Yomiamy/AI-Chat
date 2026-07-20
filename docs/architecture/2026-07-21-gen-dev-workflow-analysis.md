# gen-dev-workflow 全階段分析報告

## 總覽

`gen-dev-workflow` 是一個**全自動開發流程編排器**，負責 AI-Chat 專案從使用者說「幫我做 X 功能」到 PR 建立的全自動化流程，包含 6 個 stage（0a → 0b → 1 → 2 → 3 → 4），外加獨立入口的 STAGE 5（回覆 PR review）與 STAGE 6（PR 合併後清理 worktree），以及單暫停點的小修正 **quick 模式**。

核心機制是 **Claude 做總指揮 + `agy` CLI 做委派執行**。自 STAGE 1 起，整條流程搬進一個獨立的 worktree 執行，確保了不同分支任務的絕對隔離。

---

## 各階段詳細分析

### STAGE 0a：功能規格（What & Why）
* **Agent**: planner (最強推論 `opus` + `effort: xhigh`)
* **執行**: 讀取專案內容、調查類似實作，輸出功能規格，暫停等待確認。

### STAGE 0b：實作計畫（How）
* **Agent**: planner (最強推論 `opus` + `effort: xhigh`)
* **執行**: 分析規格，產出實作計畫，包含資料結構設計、任務拆分與複雜度標記。

### STAGE 1：建立 Issue + Worktree
* **Agent**: brancher (輕量 `sonnet` + `effort: high`)
* **執行**: 產生 issue body，決定分支名稱，交由 agy 建立 Github Issue 與本地 `git worktree`。這是專案隔離的護城河。

### STAGE 2：實作（核心 Stage）
* **Agent**: implementer (動態分級) / verifier (最強推論 `opus` + `effort: xhigh`)
* **執行**: agy 負責代碼與測試的撰寫，可條件式並行任務。完成後交由 verifier 做規格與品質兩階段驗收。

### STAGE 3：審查
* **Agent**: reviewer (最強推論 `opus` + `effort: xhigh`)
* **執行**: reviewer 親自審查（不可外包給 agy），產出審查報告。不通過則退回 STAGE 2 重做。確保不自己審自己的品味。

### STAGE 4：發布
* **Agent**: publisher (輕量 `sonnet` + `effort: high`)
* **執行**: agy 產生 PR 描述草稿，使用者確認後推播發布 Github PR。

### STAGE 5 & 6 (獨立入口)
* **STAGE 5 (PR Review Response)**: 串連 responder → reviewer → publisher 處理 PR review。
* **STAGE 6 (清理 Worktree)**: 呼叫 `worktree-close-cleanup` skill 清理 STAGE 1 建立的 worktree。

---

## Model 與委派策略總覽

推論分級與委派是成本優化與品質保證的關鍵：
* **最強推論 (Opus)**：用於 STAGE 0 (規劃)、STAGE 3 (審查)、STAGE 2 驗收。
* **標準/輕量 (Sonnet)**：用於 STAGE 1 (建立分支)、STAGE 4 (PR 草稿)、STAGE 5 (Responder)。
* **快/便宜 (agy 內部 model)**：用於 STAGE 2 機械性的實作。

---

## 狀態持久化與隔離

* **Per-worktree 狀態檔**：自 STAGE 1 開始，狀態 JSON 儲存於各自 worktree 的 `.claude/workflow-state/` 內。同一 Repo 可同時跑多個 workflow，徹底解決並發寫入衝突。
* **Token Budget Gate**：當對話 context 暴漲時 (如超過 150k tokens)，系統會強制 checkpoint，告知使用者另開 session，然後以最新狀態檔續接。

> **Linus 式總結**：將 Token Budget 視為真實存在的物理限制，並用實體檔案持久化狀態以實現中斷續接。利用 worktree 隔離完全消滅了多任務的特殊狀態管理。這是一套具備高度實用主義的 Workflow。
