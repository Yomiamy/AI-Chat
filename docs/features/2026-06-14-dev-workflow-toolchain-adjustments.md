# Dev Workflow 工具鏈調整

- 日期：2026-06-14
- 分支：`feature/202605/adjust-project-skill-and-agent-4`
- 性質：逆向補檔（事後撰寫的功能規格，描述已完成的 5 個 commit）

## 功能概述

本批變更針對 dev workflow 的**工具鏈**（`.claude/` 下的 agents 與 skills）做了五項調整，整體目的是讓開發流程的產出規範、執行載體、commit 慣例、branch 生命週期與模型選用更貼合期望：

1. 強制 spec/plan 文件以繁體中文撰寫。
2. 為三個高負載 stage 加入 opt-in 的 Claude Workflow 並行層。
3. 移除 commit template 中的 `Co-Authored-By` AI attribution trailer。
4. 流程結束時永不刪除本地 branch。
5. 最高推論等級的環節優先改用 Fable 模型。
6. 在 `gen-commit` 的 Message rules 明文禁止任何 attribution trailer。

前五項為原本 5 個 commit 已完成的變更；第 6 項為本次流程中追加的後續強化。本文件如實描述各項做了什麼、為什麼，而非規劃新功能。

## 各項變更的 What & Why

### 變更 1：強制 spec/plan 文件使用繁體中文

- **What**：在 `.claude/agents/planner.md` 的工作原則新增規則——spec（`docs/features/`）與 plan（`docs/plans/`）文件一律以繁體中文撰寫；程式碼、識別字、指令、技術術語保留原文。
- **Why**：統一文件語言，降低閱讀與維護成本，同時避免把技術原文翻譯成中文造成歧義。
- **對應 commit**：`feat(gen-dev-workflow): adjust the planner agent to force spec/plan document used in Tradition Chinese`
- **動到的檔案**：`.claude/agents/planner.md`

### 變更 2：新增可選的 Claude Workflow 並行層

- **What**：在 `.claude/skills/gen-dev-workflow/SKILL.md` 新增一個 opt-in 的加速層，讓三個特定 stage 透過 Claude Workflow 工具 fan-out，取代原本的序列 Task 呼叫：
  - STAGE 0a：雙線 context 收集
  - STAGE 2：同批獨立任務
  - STAGE 3：多 angle 對抗式審查
- **不變的部分**：暫停點（pause points）仍由主 orchestrator 掌控；state、model、委派語意維持不變。Workflow 只是換掉「並行執行的載體」，不改變流程語意。
- **Why**：在不犧牲既有控制流的前提下，為高負載 stage 提供可選的並行加速。預設行為不變，使用者需主動 opt-in。
- **對應 commit**：`feat(gen-dev-workflow): add optional Claude Workflow parallel layer`
- **動到的檔案**：`.claude/skills/gen-dev-workflow/SKILL.md`

### 變更 3：移除 commit template 的 Co-Authored-By trailer

- **What**：在 `.claude/skills/gen-commit/SKILL.md` 移除 commit template 中的 `Co-Authored-By: Claude ...` trailer 行，並移除「Always append the Co-Authored-By trailer」規則。
- **Why**：commit message 不應帶 AI attribution trailer。
- **對應 commit**：`chore(gen-commit): drop Co-Authored-By trailer from commit template`
- **動到的檔案**：`.claude/skills/gen-commit/SKILL.md`

### 變更 4：流程結束時永不刪除本地 branch

- **What**：
  - `.claude/agents/publisher.md`：description 從「closing out development branches / branch cleanup」改為「closing out development work / Never deletes the local branch」；新增工作原則「保留 branch：流程結束時不刪除本地 branch（不執行 `git branch -d`/`-D`）」；完成條件從「本地環境已根據使用者選擇完成清理」改為「本地 branch 保留不刪除」。
  - `.claude/skills/finishing-a-development-branch/SKILL.md`：Option 1（本地 merge）移除 `git branch -d <feature-branch>`，改為明確「Keep the feature branch — do NOT run `git branch -d`」；表格 Cleanup Branch 欄——Option 1 從 ✓ 改為 -（keep branch）、Option 4 從 ✓ (force) 改為 ✓ (force, explicit confirm only)；Common Mistakes 新增「Delete the feature branch at the end of the workflow (only Option 4, with typed confirmation, may delete it)」。
  - `.claude/skills/gen-dev-workflow/SKILL.md`：澄清 state-file cleanup 只針對 JSON state，絕不刪 git branch 本身。
- **Why**：避免在流程結束時意外刪除本地 branch 而失去復原能力。唯一例外是 Option 4，且必須經過明確的 typed confirmation 才可（force）刪除。
- **對應 commit**：`feat(workflow): never delete local branch at end of dev workflow`
- **動到的檔案**：`.claude/agents/publisher.md`、`.claude/skills/finishing-a-development-branch/SKILL.md`、`.claude/skills/gen-dev-workflow/SKILL.md`

### 變更 5：最高推論等級環節優先採用 Fable 模型

- **What**：
  - `.claude/agents/planner.md`：model 從 `claude-opus-4-5` 改為 `fable`。
  - `.claude/agents/reviewer.md`：model 從 `claude-opus-4-5` 改為 `fable`。
  - `.claude/skills/gen-dev-workflow/SKILL.md`：新增「Fable 優先原則」——需要最高推論等級的環節（planning、review、STAGE 2 最強 model 分級）一律優先用 Fable（`model: "fable"`），僅在 Fable 不可用時 fallback 回 Opus（單次，不再降級）；Sonnet 等級的 stage 不受影響。
- **Why**：在最需要推論能力的環節採用 Fable 模型，同時保留 Opus 作為單次 fallback，確保不可用時仍可運作。
- **對應 commit**：`feat(agents): prefer Fable model for highest-reasoning stages`
- **動到的檔案**：`.claude/agents/planner.md`、`.claude/agents/reviewer.md`、`.claude/skills/gen-dev-workflow/SKILL.md`

### 變更 6：gen-commit 明文禁止 attribution trailer

- **What**：在 `.claude/skills/gen-commit/SKILL.md` 的 Message rules 新增一條規則——`Do NOT append any attribution trailer (no Co-Authored-By, no Generated with ...)`。
- **Why**：變更 3 雖已從 commit template 移除 `Co-Authored-By` 範例行，但 Message rules 未明文禁止；新增此規則後，意圖從「範本不放」升級為「規則明確禁止」，避免日後任何 attribution trailer（含 `Generated with ...`）再次出現。此規則與全域 `~/.claude/skills/gen-commit/SKILL.md` 的措辭一致。
- **性質**：本次流程中追加的後續強化（非原本 5 個 commit 之一）。
- **動到的檔案**：`.claude/skills/gen-commit/SKILL.md`

## 範圍邊界

- **只動 `.claude/` 下的 agents 與 skills**：本批變更全部落在 `.claude/agents/` 與 `.claude/skills/` 兩個目錄內，純屬流程定義與工具鏈規範的調整。
- **不碰應用程式碼**：不涉及任何 application code、不改變產品功能、不動 build/test/部署管線本身。
- **變更檔案清單**（共 6 檔，103 insertions / 21 deletions）：
  - `.claude/agents/planner.md`
  - `.claude/agents/publisher.md`
  - `.claude/agents/reviewer.md`
  - `.claude/skills/finishing-a-development-branch/SKILL.md`
  - `.claude/skills/gen-commit/SKILL.md`
  - `.claude/skills/gen-dev-workflow/SKILL.md`

## 驗收條件

以「文件規則是否正確落地」為驗收角度：

1. **繁體中文規範**：`planner.md` 工作原則明載 spec/plan 須以繁體中文撰寫，且註明程式碼、識別字、指令、技術術語保留原文。
2. **Claude Workflow 並行層**：`gen-dev-workflow/SKILL.md` 描述 STAGE 0a / STAGE 2 / STAGE 3 的 opt-in fan-out；並明確聲明暫停點由主 orchestrator 掌控、state/model/委派語意不變。
3. **移除 Co-Authored-By**：`gen-commit/SKILL.md` 已無 `Co-Authored-By` trailer 行，且已無「Always append the Co-Authored-By trailer」規則。
6. **明文禁止 attribution trailer**：`gen-commit/SKILL.md` 的 Message rules 含 `Do NOT append any attribution trailer (no Co-Authored-By, no Generated with ...)`，且措辭與全域版本一致。
4. **永不刪 branch**：
   - `publisher.md` description、工作原則、完成條件皆反映「不刪本地 branch」。
   - `finishing-a-development-branch/SKILL.md` Option 1 不含 `git branch -d`；表格 Cleanup Branch 欄為 Option 1 = `-`、Option 4 = `✓ (force, explicit confirm only)`；Common Mistakes 含對應條目。
   - `gen-dev-workflow/SKILL.md` 澄清 state-file cleanup 僅限 JSON state，不刪 git branch。
5. **Fable 優先**：
   - `planner.md` 與 `reviewer.md` 的 `model` 為 `fable`。
   - `gen-dev-workflow/SKILL.md` 載明「Fable 優先原則」——planning / review / STAGE 2 最強分級優先用 Fable，僅 Fable 不可用時單次 fallback 回 Opus；Sonnet 等級 stage 不受影響。
