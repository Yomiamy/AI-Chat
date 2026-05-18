---
name: branch-ticket-solution-advisor
description: Use this skill when the user wants to detect a YouTrack ticket id from the current branch name, read that ticket, inspect the relevant code paths in the current repo, condense the ticket description into a clear implementation brief, and propose practical development, bug-fix, or improvement approaches without inventing missing requirements.
---

# Branch Ticket Solution Advisor

Use this skill when the task is to read the current git branch, extract a resolvable YouTrack issue key from the early branch name, fetch the ticket details, inspect the current repository for the most relevant implementation context, summarize the ticket into a concise working brief, and propose actionable implementation directions.

## Workflow

1. Read the current git branch name unless the user explicitly provides a branch name.
2. Inspect the early branch path or slug text and extract one or more issue-key candidates near the start.
3. Prefer a resolvable issue key over a hard-coded branch naming convention.
4. Resolve the ticket in YouTrack before summarizing anything.
5. Read the ticket title and description first.
6. Pull useful custom fields only when they help the recommendation, such as `Type`, `State`, `Priority`, `Assignee`, or `Subsystem`.
7. Inspect the repository before recommending implementation work whenever local code is available:
   - find likely modules, screens, routes, validators, services, tests, or shared utilities related to the ticket
   - prefer fast local discovery such as `rg`, targeted file reads, and existing project conventions
   - compare ticket expectations with the current implementation and note mismatches
   - if multiple flows are mentioned, check whether they share logic or duplicate it
8. Condense the ticket into a working brief:
   - problem or goal
   - user-facing impact
   - explicit requirements
   - constraints or edge cases
   - open ambiguities
9. Distinguish facts from inference. If the description is incomplete, say what is missing instead of inventing details.
10. **Gemini 優先策略**：收集完 ticket 資料與程式碼觀察後，優先委派 Gemini 生成「建議方向」段落：
    - 呼叫 `mcp__gemini-cli__ask-gemini`，傳入以下 prompt（以實際資料填入）：
      ```
      你是一位資深 Flutter 工程師，請根據以下 YouTrack ticket 資訊與程式碼觀察，用繁體中文提出 1 至 3 個具體的實作方向建議（保留英文技術術語）。

      Ticket: <ticket-id> - <ticket summary>
      Type: <Type>
      State: <State>
      Priority: <Priority>

      Ticket 描述摘要：
      <ticket description 摘要>

      程式碼觀察（已檢視的相關模組、現有邏輯、潛在衝突點）：
      <Claude 的 rg / file read 觀察摘要>

      每個建議方向請依照以下格式輸出：

      ### [類型]（開發 / 修正 / 改善 擇一）

      **判斷依據**：為何這個類型符合此 ticket

      **建議做法**：具體的實作方向，需提及影響的層級（Data / Domain / BLoC / UI）、可複用的現有邏輯、潛在風險

      **驗證方式**：測試方式、手動驗證步驟、或上線後確認項目

      **風險與待確認**：缺少的 context、migration 風險、跨團隊依賴、或不明確的需求

      規則：
      - 只輸出建議方向，不要重複 ticket 摘要
      - 建議必須有根據（來自 ticket 或程式碼觀察），不要憑空推測
      - 若有不確定的地方，在「風險與待確認」中說明，不要假設為需求
      ```
    - 若 Gemini 成功回傳包含 `**判斷依據**` 與 `**建議做法**` 的建議內容，直接採用作為「建議方向」段落。
    - 若 Gemini 呼叫失敗或回傳格式不合法，回退至步驟 11 自行生成建議方向。
11. （Fallback）自行 propose one or more solution directions under the most suitable category:
    - `開發` for new capability or workflow expansion
    - `修正` for bug, regression, mismatch, or broken behavior
    - `改善` for refactor, UX polish, performance, maintainability, or process optimization
12. If the best category is unclear, state the likely category and why.
13. Keep recommendations concrete: mention affected layers, validation ideas, likely risks, and whether the current implementation already has reusable logic.
14. If no issue key can be resolved from the branch, stop and report that no safe ticket summary was produced.

## Branch Detection

- Default source: `git branch --show-current`
- If the user supplies a branch name, use that instead.
- Search the early branch text for issue-key candidates that look like `ABC-1234`.
- Do not assume a fixed prefix such as `feature/` or `bugfix/`.
- Prefer the first candidate that YouTrack resolves exactly.

## Ticket Retrieval

Prefer YouTrack MCP tools when available.

Fallback to the bundled read-only script when MCP is unavailable or when a reusable deterministic path is better:

[`scripts/read_branch_ticket.sh`](./scripts/read_branch_ticket.sh)

Usage:

```bash
bash ./scripts/read_branch_ticket.sh
bash ./scripts/read_branch_ticket.sh "feature/APP-1234-improve-checkout"
bash ./scripts/read_branch_ticket.sh --extract-only "feature/APP-1234-improve-checkout"
```

Behavior:

- Reads the current branch when no branch argument is given.
- Extracts candidate issue keys from the early branch text.
- Resolves the first exact YouTrack match.
- Prints normalized JSON for downstream summarization.
- `--extract-only` skips network access and prints only branch and candidate keys.
- Accepts `AUTH_HEADER` from the current shell first, then falls back to `~/.codex/config.toml`.
- When reading config, support both a top-level `AUTH_HEADER` entry and `[mcp_servers.youtrack.env] AUTH_HEADER`.
- Prefer invoking the script with `bash` unless you already know the file is executable in the current repo.

## Summarization Rules

Summaries should help implementation, not restate the whole ticket verbatim.

Always capture:

- ticket id and summary
- current state when available
- condensed ticket description in plain `zh-tw`
- current-code observations when repository inspection was possible
- explicit acceptance points if present
- dependencies, assumptions, or unanswered questions

When the ticket description is long, compress it into a few clear bullets or a short paragraph.

## Recommendation Rules

Recommendations must be practical and bounded by the ticket content.
Prefer repo-aware recommendations over ticket-only speculation when the codebase is available.

For each proposed direction, prefer this structure:

- `類型`: `開發` / `修正` / `改善`
- `判斷依據`: why this category fits the ticket
- `建議做法`: concrete implementation direction
- `驗證方式`: tests, manual checks, or rollout checks
- `風險與待確認`: missing context, migration risk, cross-team dependency, or unclear requirement

Good recommendation patterns:

- identify likely modules or app layers
- point out existing validators, shared helpers, duplicated logic, or missing abstraction
- note data flow, API, state management, UI, analytics, or localization impact when relevant
- mention regression surfaces and test focus
- call out when a staged delivery is safer than a single large change

Avoid:

- pretending the ticket already contains technical design when it does not
- offering only vague advice such as `check logic` or `optimize code`
- converting unknowns into false requirements

## Output Rules

Keep the response concise but decision-useful.

Preferred output shape:

1. `Branch`: detected branch name
2. `Ticket`: resolved issue key and summary
3. `程式碼現況`: only when repository inspection was possible and relevant
4. `Ticket 摘要`: condensed problem statement and key requirements
5. `建議方向`: one to three concrete options, each labeled `開發` / `修正` / `改善`
6. `待確認`: only when meaningful gaps remain

## Style Rules

- Primary language: `zh-tw`
- Allowed exceptions: necessary `en-us` proper nouns and technical terms such as `YouTrack`, `State`, `API`, `UI`, `Backend`, `QA`, branch names, and issue keys
- Preferred tone: concise, analytical, and implementation-oriented
