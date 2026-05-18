---
name: gen-ticket-workflow
description: 當使用者輸入 `gen ticket-workflow <TICKET-ID>` 或想要從 YouTrack ticket 一條龍完成「讀取 ticket → 理解 → 建立 worktree → 代碼分析 → 釐清修改範圍 → 提供修改建議 → 寫入 issue / spec 文件 → 實作 → commit」全流程時，請使用此技能。整合多個既有 skill，採用 Claude orchestrator + Gemini generator + Haiku scout 的混合架構以節省 token。
---

# Gen Ticket Workflow

## 觸發條件

- 使用者輸入：`gen ticket-workflow <TICKET-ID>`
- 範例：`gen ticket-workflow BUG-2351`

---

## 流程總覽圖

```
╔══════════════════════════════════════════════════════════════════╗
║  Input: YouTrack Ticket ID (e.g., BUG-2351)                      ║
║  主流程 Model: 🤖 Sonnet 4.6 (orchestrator)                       ║
╚══════════════════════════════════════════════════════════════════╝
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Phase 1+2a: 上下文收集 + 代碼調查         🟢 2 條並行              │
│                                                                    │
│   ┌──────────────────────────┐ ┌──────────────────────────────┐  │
│   │ A: context-collector     │ │ B: ticket-code-investigator  │  │
│   │ 🤖 Haiku 4.5              │ │ 🔵 Opus 4.7                   │  │
│   │                          │ │                              │  │
│   │ • YouTrack ticket        │ │ • 驗證問題存在性              │  │
│   │ • QA report              │ │ • 搜尋相關代碼路徑            │  │
│   │ • User brief             │ │ • 列出受影響檔案 / 函式        │  │
│   │ • 純彙整、無代碼搜尋      │ │ • Reproduction steps         │  │
│   └─────────────┬────────────┘ └──────────────┬───────────────┘  │
│                 └──────────────┬─────────────┘                    │
│                                ↓                                  │
│         產出: .agent-output/context/<ticket-id>.md                │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Phase 2b: 解決方案建議                    🔴 序列                  │
│ 🔵 Opus 4.7 (主) + 💎 Gemini (建議方向長文)                         │
│                                                                    │
│   → branch-ticket-solution-advisor                                │
│     ✨ Gemini 優先：mcp__gemini-cli__ask-gemini                     │
│     🔍 驗證 fallback：格式 + 分層提示 + 具體檔案路徑                 │
│                                                                    │
│   產出: implementation brief                                       │
└──────────────────────────────────────────────────────────────────┘
                              ↓
                  ╔═══════════════════════╗
                  ║ 🛑 Checkpoint #1      ║
                  ║ 使用者確認 brief      ║
                  ╚═══════════════════════╝
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Phase 3: 建立隔離工作區                   🔴 序列                  │
│ 🤖 Sonnet 4.6                                                      │
│                                                                    │
│   → ticket-id-dev-prep                                            │
│     • prepare_ticket_dev_workspace.sh                              │
│     • git worktree add + 新 branch                                 │
│     • 同步 local config / melos bs / intl_utils                    │
│                                                                    │
│   ⚠️ 切換工作目錄到新 worktree                                     │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Phase 4+5: 寫入 Issue + Spec 文件         🔴 序列（合併委派）       │
│ 🤖 Sonnet 4.6 (主) + 💎 Gemini (單次雙產出)                         │
│                                                                    │
│   → branch-ticket-issue-doc + issue-spec-prep                     │
│     ✨ Gemini 單次委派產出兩份文件（節省 1 次 context 傳輸）          │
│     🔍 驗證 fallback：                                              │
│       SECTION-A (issue doc): ## 問題描述 + ## 已知事實               │
│       SECTION-B (spec)     : ## 背景 + ## AC + 分層 + 檔案路徑       │
│                                                                    │
│   產出:                                                            │
│     docs/issues/<ticket-id>.md                                     │
│     docs/issues/specs/<ticket-id>.md                               │
└──────────────────────────────────────────────────────────────────┘
                              ↓
                  ╔═══════════════════════╗
                  ║ 🛑 Checkpoint #2      ║
                  ║ 使用者確認 spec       ║
                  ╚═══════════════════════╝
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Phase 6: Commit 文件                      🔴 序列                  │
│ 🤖 Sonnet 4.6（直接生成，❌ 不委派 Gemini）                         │
│                                                                    │
│   → gen-commit                                                     │
│     • Sonnet 依 diff 直生 gitmoji commit message                   │
│     • 保留 DETECTED_SECRETS 檢測                                    │
│                                                                    │
│   產出: 📝 新增 <TICKET-ID> issue 與 spec 文件                      │
└──────────────────────────────────────────────────────────────────┘
                              ↓
        ╔═══════════════════════════════════════════╗
        ║ 解析 spec → 判斷實作並行模式               ║
        ║ 🔵 Opus 4.7（避免 worker 寫入路徑衝突）    ║
        ╚═══════════════════════════════════════════╝
                              ↓
        ┌─────────────────────┴─────────────────────┐
        ↓                                           ↓
┌──────────────────────────────┐    ┌──────────────────────────────┐
│ Phase 7 - 模式 B             │    │ Phase 7 - 模式 C             │
│ 🟢 feature slice 並行         │    │ 🟢 實作 + 測試並行            │
│                              │    │                              │
│  ┌─────────┐ ┌─────────┐    │    │  ┌──────────────────────┐   │
│  │feature- │ │feature- │    │    │  │ feature-worker       │   │
│  │worker A │ │worker B │ ...│    │  │ 🤖 Sonnet 4.6        │   │
│  │🤖 Sonnet │ │🤖 Sonnet │    │    │  └──────────┬───────────┘   │
│  │  4.6    │ │  4.6    │    │    │             │                │
│  └────┬────┘ └────┬────┘    │    │  ┌──────────┴───────────┐   │
│       └─────┬─────┘          │    │  │ test-worker          │   │
│             │                │    │  │ 🤖 Sonnet 4.6        │   │
│   寫入 scope 互不重疊         │    │  └──────────────────────┘   │
└──────────────┬───────────────┘    └──────────────┬───────────────┘
               └──────────────┬─────────────────────┘
                              ↓
        適用時呼叫 gen-data-* / gen-domain / gen-bloc / gen-ui
        🤖 Sonnet 4.6（主 orchestrator 執行）
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Phase 8: 完成前驗證                       🟡 指令並行               │
│ 🤖 Sonnet 4.6                                                      │
│                                                                    │
│   → verification-before-completion                                │
│   ┌─────────────────┐ ┌─────────────────┐ ┌──────────────────┐   │
│   │ flutter test    │ │ flutter analyze │ │ make analyze_lint│   │
│   └─────────────────┘ └─────────────────┘ └──────────────────┘   │
│                                                                    │
│   失敗 → systematic-debugging (🤖 Sonnet 4.6)                      │
└──────────────────────────────────────────────────────────────────┘
                              ↓
                  ╔═══════════════════════╗
                  ║ 🛑 Checkpoint #3      ║
                  ║ AC 全綠、無 lint 錯誤 ║
                  ╚═══════════════════════╝
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Phase 9: Commit 實作                      🔴 序列                  │
│ 🤖 Sonnet 4.6（直接生成，❌ 不委派 Gemini）                         │
│                                                                    │
│   → gen-commit × N（依變更性質拆分）                                │
│     • Sonnet 依 diff 直生每個 gitmoji commit message               │
│                                                                    │
│     ✨ feat(data):    新增 OrderRepo 與 ApiGw DTO                  │
│     ✨ feat(domain):  新增 FetchOrderUC                            │
│     ✨ feat(present): 新增 OrderBloc 與 OrderPage                  │
│     ✅ test:          補上對應測試                                  │
│     🐛 fix:           修正既有 firstWhereOrNull                    │
└──────────────────────────────────────────────────────────────────┘
                              ↓
╔══════════════════════════════════════════════════════════════════╗
║  ✅ 完成                                                            ║
║     後續銜接（保留 Gemini 委派，長文 PR description 值得）           ║
║     gen-pr (💎) → pr-publish-main-zh-tw (💎)                       ║
║     → ticket-fix-progress-report (💎)                              ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## Model 分配總覽

| Phase | Skill / Agent | Model | Gemini 委派 |
|---|---|---|---|
| 1 | context-collector | 🤖 **Haiku 4.5** | ❌ |
| 1 | ticket-code-investigator | 🔵 **Opus 4.7**（跨層依賴追蹤、代碼判定） | ❌ |
| 2b | branch-ticket-solution-advisor | 🔵 **Opus 4.7**（最高槓桿決策，錯了後面全錯） | ✨ **是**（建議方向段落） |
| 3 | ticket-id-dev-prep | 🤖 Sonnet 4.6 | ❌ |
| 4+5 | branch-ticket-issue-doc + issue-spec-prep | 🤖 Sonnet 4.6 | ✨ **是**（單次雙產出） |
| 6 | gen-commit (docs) | 🤖 Sonnet 4.6 | ❌（短文直生） |
| 7 | spec 解析 → 並行模式判斷 | 🔵 **Opus 4.7**（避免 worker 寫入路徑衝突） | ❌ |
| 7 | feature-worker × N | 🤖 Sonnet 4.6 | ❌ |
| 7 | test-worker × N | 🤖 Sonnet 4.6 | ❌ |
| 7 | gen-data-* / gen-domain / gen-bloc / gen-ui | 🤖 Sonnet 4.6 | ❌ |
| 8 | verification-before-completion | 🤖 Sonnet 4.6 | ❌ |
| 8 | systematic-debugging | 🤖 Sonnet 4.6 | ❌ |
| 9 | gen-commit × N (code) | 🤖 Sonnet 4.6 | ❌（短文直生） |

---

## Gemini 委派點摘要（共 2 個 Phase）

| Phase | 委派內容 | 預估字數 | MCP Tool |
|---|---|---|---|
| 2b | implementation brief「建議方向」 | 300-500 字 | `mcp__gemini-cli__ask-gemini` |
| 4+5 | issue doc + spec（單次雙產出） | 800-1500 字 | `mcp__gemini-cli__ask-gemini` |

**委派策略**：「**優先策略 + Sonnet fallback**」
- 先呼叫 Gemini 生成內容
- 驗證結構 + 內容雙重檢查
- 任一未通過 → Sonnet 自行撰寫

**委派門檻**：**輸出 > 300 字才委派 Gemini**，否則 Sonnet 直生。

---

## Gemini Fallback 驗證規則

### Phase 2b 驗證
- ✅ 結構 heading 存在
- ✅ 含「判斷依據」「建議做法」
- ✅ 含分層提示（Data/Domain/BLoC/UI）
- ✅ 含具體檔案路徑

### Phase 4+5 驗證

**SECTION-A (issue doc)：**
- ✅ 含 `## 問題描述` 與 `## 已知事實`
- ✅ 含具體症狀與影響範圍

**SECTION-B (spec)：**
- ✅ 含 `## 背景` 與 `## Acceptance Criteria`
- ✅ 含分層標示（Data/Domain/BLoC/UI）
- ✅ 含具體檔案路徑
- ✅ 若涉及 BLoC：含 `status` enum 規範

任一驗證項未通過 → 該段落由 Sonnet 自行撰寫。

---

## Phase 4+5 合併委派 Prompt 結構

```
請依以下資料同時產出兩份文件，以 markdown 分段：

【SECTION-A: ISSUE-DOC】
## 問題描述
## 已知事實

【SECTION-B: SPEC】
## 背景
## 修改範圍（含分層 Data/Domain/BLoC/UI）
## Acceptance Criteria

【Context】
- YouTrack ticket: {ticket}
- 代碼觀察: {code observation}
- Implementation brief: {brief}
```

---

## Token Budget Gate（全域監控）

每次 phase 切換前評估主對話 context 用量：

| Context 用量 | 行為 |
|---|---|
| < 60k | 正常流程 |
| 60-100k | ⚠️ 警告，建議精簡 Phase 1+2 的 raw output |
| > 100k | ⚠️ 強制走 Gemini 委派路徑（無 fallback） |
| > 150k | ⛔ 強制 checkpoint，建議切新 session |

---

## Phase 7 並行模式判斷

```
                spec 解析完成
                     ↓
         ┌──────────────────────┐
         │ spec 含 ≥ 2 個獨立    │
         │ feature 且寫入路徑    │
         │ 不重疊？              │
         └──────────────────────┘
            是 ↓        ↓ 否
       ┌────────┐  ┌──────────────┐
       │ 模式 B  │  │ spec 是單一  │
       │ feature │  │ feature？    │
       │ slice   │  └──────────────┘
       │ 並行    │     是 ↓
       └────────┘  ┌──────────────┐
                   │ 模式 C        │
                   │ 實作+測試     │
                   │ 並行          │
                   └──────────────┘
```

### 模式 B：Feature Slice 並行
- 條件：spec 有 ≥ 2 個獨立 feature，寫入路徑互不重疊
- Skill：`dispatching-parallel-agents` + `subagent-driven-development`
- Worker：N 個 `feature-worker`（每個自含 Data→Domain→BLoC→UI）

### 模式 C：實作 + 測試並行
- 條件：單一 feature
- Skill：`test-driven-development` + `subagent-driven-development`
- Worker：1 個 `feature-worker` + 1 個 `test-worker`

### 並行注意事項
- ✅ 每個 worker 給明確的寫入 scope（檔案清單）
- ✅ 共享資源（如 `pubspec.yaml`、`di_module.dart`）指定唯一 worker 修改
- ❌ 避免兩個 worker 同時改 `getIt.registerSingleton(...)`
- ❌ 避免兩個 worker 同時修改 generated files

---

## Phase 7 內呼叫 gen-* skill 對照

| Spec 涉及層級 | Skill |
|---|---|
| 新增 API DTO/Service (apigw) | `gen-data-apigw` |
| 新增 API DTO/Service (athena) | `gen-data-athena` |
| 新增 API DTO/Service (goons) | `gen-data-goons` |
| 新增 API DTO/Service (krakend) | `gen-data-krakend` |
| 新增本地 DB Table | `gen-data-db` |
| 新增 Entity / UseCase | `gen-domain` |
| 新增 BLoC | `gen-bloc` |
| 新增 Page / Widget | `gen-ui` |

---

## Checkpoints 總覽

| Phase | 自動執行 | 🛑 人為 checkpoint | 失敗處理 |
|---|---|---|---|
| 1+2a | ✅ | - | - |
| 2b | ✅ | **確認 brief 與修改範圍** | 回 Phase 1 補 context |
| 3 | ✅ | - | local config 同步檢查 |
| 4+5 | ✅ | **確認 spec 修改計畫** | 編輯 spec 後再進 Phase 6 |
| 6 | ✅ | - | - |
| 7 | ✅ | 每層完成後 mid-checkpoint | `systematic-debugging` |
| 8 | ✅ | **AC 全綠** | 回 Phase 7 補洞 |
| 9 | ✅ | - | - |

---

## 預估 Token 節省

| 項目 | 優化前 | 優化後 | 節省 |
|---|---|---|---|
| Phase 1+2 重複工作（移除 Explore subagent） | +30% | 0% | ~15k token |
| Phase 4+5 委派傳輸（合併單次） | 2 次 context | 1 次 context | ~8k token |
| Phase 6 commit msg（改 Sonnet 直生） | Gemini 8k | Sonnet 1k | ~7k token |
| Phase 9 N × commit（改 Sonnet 直生） | Gemini N×8k | Sonnet N×1k | ~35k token（5 次） |
| **總計** | **基準** | **-65k token** | **~30-35% 成本** |

---

## 後續銜接

實作完成（Phase 9）後，銜接既有 skill：

```
→ gen-pr           (產生 PR description，💎 Gemini)
→ pr-publish-main-zh-tw  (發布 PR，💎 Gemini)
→ ticket-fix-progress-report  (回報 YouTrack 並轉 To Verify，💎 Gemini)
→ finishing-a-development-branch  (收尾)
→ worktree-close-cleanup  (清理 worktree)
```

---

## 圖例

| 標記 | 意義 |
|---|---|
| 🟢 | 並行階段（multi-agent） |
| 🟡 | 部分並行（指令層級並跑） |
| 🔴 | 必須序列（單一檔案／git 寫入） |
| 🛑 | 人為 checkpoint（使用者確認） |
| ⚠️ | 環境切換注意點 |
| 🤖 | Claude Sonnet 4.6 |
| 🔵 | Claude Opus 4.7（高槓桿決策點） |
| 💎 | Gemini 委派點 |
| ✨ | 優化策略標示 |
| ❌ | 已移除或不適用 |
| ✅ | 已啟用或必要 |

---

## 執行注意事項

1. **每個 Phase 結束都要回報結果**（簡短一行）給使用者，讓使用者知道進度
2. **遇到 🛑 Checkpoint 必須暫停等使用者確認**，不可自動跳過
3. **Gemini 委派失敗時必須明確回報「fallback 到 Sonnet」**，不要靜默切換
4. **Phase 3 完成後務必確認工作目錄已切到新 worktree**，後續所有指令都在新 worktree 下執行
5. **若 spec 中出現 secrets 或敏感資訊**，立即警告並停止流程
