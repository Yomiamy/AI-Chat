# Dev Workflow 工具鏈調整 — 實作計畫

- 日期：2026-06-14
- 分支：`feature/202605/adjust-project-skill-and-agent-4`
- 對應 spec：`docs/features/2026-06-14-dev-workflow-toolchain-adjustments.md`
- 性質：**逆向補檔**（reverse-documented plan）

## 計畫概述

本文件為**逆向補檔**：所有 code 變更皆已完成並 commit（分支上共 6 個 commit），本計畫並非待執行的任務清單，而是逆向描述「已完成的變更如何組織成實作單元、各動了哪些檔、如何驗證已正確落地」。

本批變更全部落在 `.claude/agents/` 與 `.claude/skills/` 兩個目錄，屬於 dev workflow 工具鏈（流程定義與規範）的調整，**不涉及任何應用程式碼**。總計 6 個 code 檔、104 insertions / 21 deletions（不含本 spec/plan 兩份文件本身）。

實作單元與 spec 的 6 項變更一對一對應；其中前 5 項各對一個 commit，第 6 項為本次流程追加的後續強化（單獨一個 commit）。

## 實作單元拆分

### 單元 1：強制 spec/plan 文件使用繁體中文

- **對應 spec 變更**：變更 1
- **commit**：`151b2b6` — `feat(gen-dev-workflow): adjust the planner agent to force spec/plan document used in Tradition Chinese`（原 message 拼字 `Tradition` 為 `Traditional` 之誤，因不改寫歷史故保留原樣）
- **動到的檔案**：`.claude/agents/planner.md`（+1）
- **變更性質**：設計判斷（語言規範決策）
- **複雜度**：低（單行規則新增）
- **說明**：於 planner 工作原則新增一條——spec（`docs/features/`）與 plan（`docs/plans/`）一律繁體中文；程式碼、識別字、指令、技術術語保留原文。

### 單元 2：新增可選的 Claude Workflow 並行層

- **對應 spec 變更**：變更 2
- **commit**：`e0eafd1` — `feat(gen-dev-workflow): add optional Claude Workflow parallel layer`
- **動到的檔案**：`.claude/skills/gen-dev-workflow/SKILL.md`（+68 / -2）
- **變更性質**：整合（為既有流程加入 opt-in 並行載體，不改流程語意）
- **複雜度**：中（本批最大單筆異動；需精準描述 STAGE 0a / STAGE 2 / STAGE 3 的 fan-out 邊界與「不變的部分」）
- **說明**：為三個高負載 stage 提供 opt-in 的 Claude Workflow fan-out，取代序列 Task 呼叫。暫停點仍由主 orchestrator 掌控；state、model、委派語意維持不變。

### 單元 3：移除 commit template 的 Co-Authored-By trailer

- **對應 spec 變更**：變更 3
- **commit**：`fc6356c` — `chore(gen-commit): drop Co-Authored-By trailer from commit template`
- **動到的檔案**：`.claude/skills/gen-commit/SKILL.md`（-3）
- **變更性質**：機械性（刪除 template trailer 行與對應規則）
- **複雜度**：低（純刪除）
- **說明**：移除 commit template 的 `Co-Authored-By: Claude ...` 行，並移除「Always append the Co-Authored-By trailer」規則。

### 單元 4：流程結束時永不刪除本地 branch

- **對應 spec 變更**：變更 4
- **commit**：`6eda549` — `feat(workflow): never delete local branch at end of dev workflow`
- **動到的檔案**：
  - `.claude/agents/publisher.md`（+3 / -2）
  - `.claude/skills/finishing-a-development-branch/SKILL.md`（+5 / -5）
  - `.claude/skills/gen-dev-workflow/SKILL.md`（+3）
- **變更性質**：設計判斷（branch 生命週期策略）+ 跨檔整合（三處規範需保持一致）
- **複雜度**：中（單一決策橫跨 agent description、SKILL 表格、Common Mistakes、state-file cleanup 多處，需逐處對齊「唯一例外 = Option 4 + typed confirmation」）
- **說明**：
  - `publisher.md`：description、工作原則（保留 branch）、完成條件三處皆改為「不刪本地 branch」。
  - `finishing-a-development-branch/SKILL.md`：Option 1 移除 `git branch -d`；表格 Cleanup Branch 欄 Option 1 改 `-`、Option 4 改 `✓ (force, explicit confirm only)`；Common Mistakes 新增對應條目。
  - `gen-dev-workflow/SKILL.md`：澄清 state-file cleanup 只針對 JSON state，絕不刪 git branch。

### 單元 5：最高推論等級環節優先採用 Fable 模型

- **對應 spec 變更**：變更 5
- **commit**：`31593d2` — `feat(agents): prefer Fable model for highest-reasoning stages`
- **動到的檔案**：
  - `.claude/agents/planner.md`（model 改 `fable`）
  - `.claude/agents/reviewer.md`（model 改 `fable`）
  - `.claude/skills/gen-dev-workflow/SKILL.md`（+24 / -10，新增「Fable 優先原則」）
- **變更性質**：設計判斷（模型選用策略 + fallback 行為定義）
- **複雜度**：中（需明確定義 fallback 語意——僅在 Fable 不可用時單次 fallback 回 Opus、不再降級；且 Sonnet 等級 stage 不受影響）
- **說明**：planner 與 reviewer 的 `model` 由 `claude-opus-4-5` 改為 `fable`；於 gen-dev-workflow SKILL 載明 planning / review / STAGE 2 最強分級優先用 Fable。

### 單元 6：gen-commit 明文禁止 attribution trailer

- **對應 spec 變更**：變更 6（本次流程追加的後續強化，非原 5 commit 之一）
- **commit**：`81af9d0` — `chore(gen-commit): forbid any attribution trailer in message rules`
- **動到的檔案**：`.claude/skills/gen-commit/SKILL.md`（+1）
- **變更性質**：設計判斷（從「範本不放」升級為「規則明確禁止」）
- **複雜度**：低（單行規則新增）
- **說明**：於 Message rules 新增 `Do NOT append any attribution trailer (no Co-Authored-By, no Generated with ...)`，措辭與全域 `~/.claude/skills/gen-commit/SKILL.md` 一致。補上單元 3 未涵蓋的明文禁止規則。

## 資料結構 / 介面影響

**無。** 本批純屬文件規範與流程定義調整，不涉及任何資料結構、API 介面、設定 schema 或執行載體的程式變動。所有異動皆為 Markdown 文件（agents 與 SKILL 定義）的文字規則調整。

## 驗證方式

對齊 spec 驗收條件，以 grep / 檢視文件規則為主，逐單元驗證已正確落地：

| 單元 | 驗證方式 |
|------|----------|
| 1 | `grep` `planner.md` 工作原則含「繁體中文」規範，且註明程式碼/識別字/指令/技術術語保留原文 |
| 2 | 檢視 `gen-dev-workflow/SKILL.md` 含 STAGE 0a / STAGE 2 / STAGE 3 的 opt-in fan-out 描述，並明確聲明暫停點由主 orchestrator 掌控、state/model/委派語意不變 |
| 3 | `grep -c "Co-Authored-By" .claude/skills/gen-commit/SKILL.md` 為 0；確認已無「Always append the Co-Authored-By trailer」規則 |
| 4 | `grep` `publisher.md` description/工作原則/完成條件皆反映「不刪本地 branch」；`finishing-a-development-branch/SKILL.md` Option 1 不含 `git branch -d`、表格欄 Option 1 = `-` / Option 4 = `✓ (force, explicit confirm only)`、Common Mistakes 含對應條目；`gen-dev-workflow/SKILL.md` 澄清 state-file cleanup 僅限 JSON state |
| 5 | `grep "model:" .claude/agents/planner.md .claude/agents/reviewer.md` 皆為 `fable`；`gen-dev-workflow/SKILL.md` 載明「Fable 優先原則」與單次 fallback 回 Opus、Sonnet 等級 stage 不受影響 |
| 6 | `grep` `gen-commit/SKILL.md` Message rules 含 `Do NOT append any attribution trailer (no Co-Authored-By, no Generated with ...)`，且與全域版本措辭一致 |

整體驗證原則：因本批不含可執行邏輯，無單元測試或整合測試可跑；驗證即「文件規則是否如 spec 所述落地」，以靜態檢視與 grep 比對為準。

## 風險與回歸

- **影響範圍**：僅改 `.claude/` 流程定義，不影響任何應用程式碼、產品功能或 build/test/部署管線。對既有 runtime 行為無回歸風險。
- **唯一實質風險 — Fable 模型可用性（單元 5）**：當 planner / reviewer / STAGE 2 最強分級指定的 Fable 模型不可用時，須能正確 fallback 回 Opus（單次，不再降級）。
  - **此風險已於本次流程中實際觸發並驗證**：Fable 不可用時，流程依「Fable 優先原則」的 fallback 規則改用 Opus 完成 planning / review，行為符合預期。
  - Sonnet 等級的 stage 不受 Fable 優先原則影響，無連帶風險。
- **branch 生命週期（單元 4）**：策略改為「永不刪本地 branch」，方向上更保守（降低意外刪除風險），唯一例外 Option 4 仍需 typed confirmation 才會 force 刪除，無新增破壞性行為。
