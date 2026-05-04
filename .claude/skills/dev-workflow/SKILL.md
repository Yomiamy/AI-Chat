---
name: dev-workflow
description: |
  完整開發流程編排器。使用者說「幫我做 X 功能」時觸發，自動依序驅動所有 agent 直到 PR 建立，只在關鍵決策點暫停確認。
  觸發條件：dev workflow, 開始開發, 新功能開發, 幫我做 X 功能, 繼續, 繼續上次, 繼續開發, /dev-workflow
---

# Dev Workflow（自動編排模式）

你是整個開發流程的**總指揮**。使用者給你一個需求，你自動驅動所有 agent 跑完整個週期，只在必要時暫停。

> **建議安裝 gemini-cli MCP** 以啟用 Gemini 委派模式（brancher、implementer、publisher 均依賴此工具）。
> 安裝方式：`claude mcp add gemini-cli -- npx -y gemini-mcp-tool`
> 未安裝時各 agent 會自動退回 Fallback 模式，功能仍可運作但不會委派給 Gemini。

## 編排流程

```text
    使用者：「幫我做 X 功能」
           │
           ▼
    ┌─────────────────────────────────────────────────┐
    │  STAGE 0a：功能規格                              │
    │  → 呼叫 planner agent                           │
    │  → 產出 docs/features/YYYY-MM-DD-<feature>.md   │
    │    （What & Why：使用者故事、驗收條件、範圍邊界） │
    │  ⏸ 暫停：展示功能規格，等使用者確認              │
    └──────────────────────┬──────────────────────────┘
                           │ 使用者確認
                           ▼
    ┌─────────────────────────────────────────────────┐
    │  STAGE 0b：實作計畫                              │
    │  → 呼叫 planner agent（依據已確認的功能規格）    │
    │  → 產出 docs/plans/YYYY-MM-DD-<feature>.md      │
    │    （How：資料結構、檔案異動、任務拆分）          │
    │  ⏸ 暫停：展示實作計畫，等使用者確認              │
    └──────────────────────┬──────────────────────────┘
                           │ 使用者確認
                           ▼
    ┌─────────────────────────────────────────────────┐
    │  STAGE 1：建立分支                               │
    │  → 呼叫 brancher agent 產出草稿                  │
    │  ⏸ 暫停：展示 Issue 標題/內容 + 分支名稱         │
    │          等使用者確認或修改                       │
    │  → Gemini 執行 gh issue create + git checkout   │
    └──────────────────────┬──────────────────────────┘
                           │ 使用者確認
                           ▼
    ┌─────────────────────────────────────────────────┐
    │  STAGE 2：實作                                   │
    │  → 呼叫 implementer agent                       │
    │  → Gemini 實作任務，Claude 兩階段驗收            │
    │  ⏸ 每個任務完成後暫停：                          │
    │      展示變更檔案 + 測試結果摘要                  │
    │      問「確認繼續下一個任務嗎？」                  │
    │  ⏸ 遇到模糊需求：問使用者後繼續                  │
    └──────────────────────┬──────────────────────────┘
                           │ 所有任務確認完成
                           ▼
    ┌─────────────────────────────────────────────────┐
    │  STAGE 3：審查                                   │
    │  → 呼叫 reviewer agent                          │
    │  ⏸ 暫停：展示審查報告，問「確認繼續嗎？」         │
    │  ┌─ 使用者確認（通過）                      ─┐   │
    │  └─ 不通過 / 使用者要求修正                   │   │
    │       → 退回 STAGE 2 修正 → 再回 STAGE 3 ───┘   │
    └──────────────────────┬──────────────────────────┘
                           │ 使用者確認通過
                           ▼
    ┌─────────────────────────────────────────────────┐
    │  STAGE 4：發布                                   │
    │  → 呼叫 publisher agent                         │
    │  → Gemini 分析 Diff，Claude 校對草稿             │
    │  ⏸ 暫停：展示 PR 草稿，等使用者確認發布          │
    └──────────────────────┬──────────────────────────┘
                           │ 使用者確認
                           ▼
                      PR 建立完成 ✦
                      流程結束，Claude 停止。

    ──────────────────────────────────────────────────
    STAGE 5：回覆 PR Review（獨立入口，由你手動觸發）
    ──────────────────────────────────────────────────
    觸發方式：你說「PR #42 有新的 review 意見」
    → 呼叫 responder agent 處理每條意見
    → 處理完畢 → 呼叫 reviewer agent 重新審查
    → 審查通過 → 呼叫 publisher agent 更新 PR
    → 完成後流程再次結束，Claude 停止等待。
```

---

## 暫停點規則（只有三種）

| 暫停時機 | 你要做什麼 | 繼續條件 |
|---------|-----------|---------|
| 功能規格完成後 | 展示功能規格（使用者故事、驗收條件、範圍），問「確認嗎？」 | 使用者確認 |
| 實作計畫完成後 | 展示實作計畫（任務清單、檔案異動），問「確認開始實作嗎？」 | 使用者確認 |
| Issue + 分支建立前 | 展示 Issue 標題、描述內容、分支名稱，問「確認建立嗎？」 | 使用者確認或修改後確認 |
| 每個實作任務完成後 | 展示變更檔案清單 + 測試結果，問「確認繼續下一個任務嗎？」 | 使用者確認 |
| 審查報告完成後 | 展示完整審查報告，問「確認繼續發布嗎？或需要修正？」 | 使用者確認 → STAGE 4，或退回 STAGE 2 |
| 遇到模糊需求 | 問最小必要問題（≤ 2 個），不要問多 | 使用者回答後自動繼續 |
| PR 草稿完成後 | 展示草稿，問「確認發布嗎？」 | 使用者確認 |

**不應該暫停的情況：** 分支建立、任務切換、審查失敗退回、測試執行。這些全部自動處理。

---

## 執行方式

### 啟動完整流程
```
使用者：幫我做 <需求描述>

你：好，開始執行開發流程。
    Task("planner", "規劃 <需求描述>，產出 plan 文件")
    → [等 planner 完成] → 展示計畫摘要 → 暫停確認
    → Task("brancher", "執行 <plan 路徑>")
    → Task("implementer", "執行 <plan 路徑>")
    → Task("reviewer", "審查 <branch-name>")
    → [若不通過] Task("implementer", "修正以下問題：<reviewer 回報>")
    → Task("publisher", "發布 <branch-name>")
    → 暫停確認 → 完成
```

### 從特定階段繼續
```
使用者：從審查繼續 / 繼續發布 / 重新規劃

你：根據當前狀態跳入對應 stage，其餘流程照常自動執行。
```

---

## 狀態追蹤

每個 stage 開始前，輸出一行進度提示：

```
[1/5] 建立分支中...
[2/5] 實作中（共 N 個任務）...
[3/5] 審查中...
[4/5] 發布準備中...
[5/5] 完成 ✦ PR: <URL>
```

### 狀態檔：`.claude/workflow-state.json`

**每個 stage 完成後寫入狀態檔**，讓新 session 可以從中斷點繼續：

**sequence 模式**（正常流程跑到這裡）：
```json
{
  "stage": 2,
  "mode": "sequence",
  "spec": "docs/features/2026-05-03-cart.md",
  "plan": "docs/plans/2026-05-03-cart.md",
  "branch": "feature/202605/42-cart",
  "issue": 42,
  "pr": null,
  "completed_tasks": [1, 2],
  "total_tasks": 5
}
```

**jump 模式**（直接指定特定 stage 執行）：
```json
{
  "stage": 5,
  "mode": "jump",
  "pr": 42,
  "spec": null,
  "plan": null,
  "branch": null,
  "issue": null,
  "completed_tasks": [],
  "total_tasks": null
}
```

`mode` 的用途：
- `sequence` → 前面所有 stage 都有完整 context（spec、plan、branch），可以回頭參照
- `jump` → 只有當前 stage 的資訊，不應假設前面的 context 存在

**狀態檔檢查時機（三種觸發）：**

**三種觸發點，發現狀態檔時走同一套邏輯：**

| 觸發 | 關鍵字 |
|------|--------|
| A | `/dev-workflow` |
| B | 「幫我做 X 功能」/ 「開始開發」/ 「新功能開發」 |
| C | 「繼續」/ 「繼續上次」/ 「繼續開發」 |

**狀態檔存在時（A / B / C 共用）：**
```
→ 讀取 .claude/workflow-state.json
→ 若 pr 欄位有值 → gh pr view <pr> --json state --jq '.state'
   ├─ MERGED → 自動刪除狀態檔，告知「PR 已合併，開發週期完成 ✦」
   ├─ CLOSED → 問使用者「PR 已關閉，要重新開 PR 還是放棄？」
   └─ OPEN   → 展示目前狀態（STAGE <N>），問「繼續還是開新流程？」
→ 若 pr 欄位為 null → 展示目前狀態（STAGE <N>），問「繼續還是開新流程？」
```

**狀態檔不存在時：**
```
→ 觸發 A → 問「要開始新的開發流程嗎？請描述需求」
→ 觸發 B → 直接用使用者描述的需求啟動新流程
→ 觸發 C → 告知「找不到未完成的流程，要開始新的嗎？」
```

**狀態檔刪除時機：**
- PR 狀態為 `MERGED` → 自動刪除
- 使用者說「放棄這個功能」→ 自動刪除
- 其他情況一律保留，直到明確完成

---

## Agent 職責速查

| Stage | Agent | Model | Gemini 委派 |
|-------|-------|-------|------------|
| 0 規劃 | planner | Opus | — |
| 1 建立分支 | brancher | Sonnet | ✦ gh issue create, git checkout |
| 2 實作 | implementer | Sonnet | ✦ 代碼+測試+commit（Claude 驗收）|
| 3 審查 | reviewer | Opus | — |
| 4 發布 | publisher | Sonnet | ✦ Diff 分析 → PR 草稿（Claude 校對）|
| 5 回覆 PR Review（循環） | responder | Sonnet | — |

---

## Quick Commands

| Command | Stage | Action |
|---------|-------|--------|
| `/dev-workflow` | — | 查看目前流程狀態 / 開始新流程 |
| `/dev-workflow spec <description>` | 0a | 撰寫功能規格 |
| `/dev-workflow plan <spec-path>` | 0b | 產出實作計畫 |
| `/dev-workflow branch <issue>` | 1 | 建立 Issue + 分支 |
| `/dev-workflow implement <plan-path>` | 2 | 執行實作 |
| `/dev-workflow code-review <branch>` | 3 | 執行代碼審查 |
| `/dev-workflow publish <branch>` | 4 | 建立 PR |
| `/dev-workflow review #<PR>` | 5 | 處理 PR review 意見 |

---

## 跳入特定階段

所有跳入指令都以 `mode: "jump"` 寫入狀態檔。

```
# 重新規劃功能規格（STAGE 0a）
/dev-workflow spec <需求描述>
→ 寫入狀態檔 { stage: "0a", mode: "jump" }
→ 呼叫 planner agent 產出功能規格

# 重新產出實作計畫（STAGE 0b）
/dev-workflow plan <spec 路徑>
→ 寫入狀態檔 { stage: "0b", mode: "jump", spec: "<spec 路徑>" }
→ 呼叫 planner agent 依規格產出實作計畫

# 只需要建分支（STAGE 1）
/dev-workflow branch <ISSUE-NUMBER>
→ 寫入狀態檔 { stage: 1, mode: "jump", issue: <ISSUE-NUMBER> }
→ 呼叫 brancher agent

# 繼續實作（STAGE 2）
/dev-workflow implement <plan 路徑>
→ 寫入狀態檔 { stage: 2, mode: "jump", plan: "<plan 路徑>" }
→ 呼叫 implementer agent

# 只需要審查（STAGE 3）
/dev-workflow code-review <branch-name>
→ 寫入狀態檔 { stage: 3, mode: "jump", branch: "<branch-name>" }
→ 呼叫 reviewer agent

# 只需要發 PR（STAGE 4）
/dev-workflow publish <branch-name>
→ 寫入狀態檔 { stage: 4, mode: "jump", branch: "<branch-name>" }
→ 呼叫 publisher agent

# 處理 PR review 意見（STAGE 5）
/dev-workflow review #<PR>
→ 寫入狀態檔 { stage: 5, mode: "jump", pr: <PR> }
→ 呼叫 responder agent 處理所有 review 意見
→ 處理完畢後呼叫 reviewer agent 重新審查
→ 審查通過後呼叫 publisher agent 更新 PR
```
