---
name: dev-workflow
description: |
  完整開發流程入口。從構思到發 PR，依序調度 planner → brancher → implementer → reviewer → responder → publisher。
  觸發條件：dev workflow, 開始開發, 新功能開發, /dev-workflow
---

# Dev Workflow

完整開發流程，串接所有 subagents。依照當前階段跳入對應步驟。

## 流程總覽

### 執行過程區塊圖

```text
    [ 構思規劃 ]          [ 建立分支 ]          [ 代碼實作 ]
    +-----------+       +------------+       +---------------+
    |  Planner  | ----> |  Brancher  | ----> |  Implementer  |
    |  (Opus)   |       |  (Sonnet)  |       |   (Sonnet)    |
    +-----------+       +------------+       +---------------+
          ^                                          |
          |                                          v
          |            [ 修正回應 ]          [ 深度審查 ]
          |            +------------+       +---------------+
          +----------- |  Responder | <---- |   Reviewer    |
           (反饋循環)   |  (Sonnet)  |       |    (Opus)     |
                       +------------+       +---------------+
                                                     |
                                                     v
                                            [ 發布收尾 ]
                                            +---------------+
                                            |   Publisher   |
                                            |   (Sonnet)    |
                                            +---------------+
```

---

## 階段 0：構思規劃（@planner — Opus）

**核心：** 搞清楚「為什麼要做」以及「怎麼做」。
**觸發：** 有新功能想法、需求不清晰、需要設計決策

```
@planner <需求描述>
```

**輸出：**
- `docs/plans/YYYY-MM-DD-<feature>.md`（實作計畫）
- **強制執行：** 計畫完成後，Agent **必須主動引導**使用者呼叫 `@brancher` 以確保 Issue 與分支的自動化建立。

**哲學：** 寧可多花 10 分鐘設計數據結構，也不要花 10 小時修補爛代碼。

---

## 階段 1：建立分支（@brancher — Sonnet）

**核心：** 環境初始化。
**觸發：** 計畫文件已就緒

**有 plan 文件：**
```
@brancher gen issue-from-plan docs/plans/<filename>.md
```

**已有 Issue：**
```
@brancher gen-branch <ISSUE-NUMBER>
```

**輸出：**
- GitHub Issue URL
- 本地分支已 checkout（格式：`category/YYYYMM/ID-slug`）

**哲學：** 自動化瑣事，讓開發者專注於邏輯。

---

## 階段 2：實作（@implementer — Sonnet）

**核心：** 逐項執行計畫。
**策略：** TDD 先行，每步必測，語意化 Commit。
**觸發：** 分支已建立，plan 文件已就緒

```
@implementer 執行 docs/plans/<filename>.md
```

**輸出：**
- 所有任務完成
- 測試通過
- 語意化 commits

**哲學：** 實作超過三層縮進就重寫。

---

## 階段 3：審查（@reviewer — Opus）

**核心：** 嚴格的品質把關。
**準則：** 沒跑過測試 = 沒做。找出根因，拒絕症狀修復。
**觸發：** 實作完成

```
@reviewer 審查 <branch-name>
```

**輸出：**
- Terminal 審查報告（zh-tw）
- 測試驗證結果
- 通過後進入下一階段

**哲學：** 「好品味」是不可妥協的。

---

## 階段 4：回覆 Review（@responder — Sonnet）

**核心：** 處理 PR 反饋。
**動作：** 評估意見、修正代碼、回覆 inline comments。
**觸發：** GitHub PR 收到 reviewer 意見

```
@responder 處理 PR #<NUMBER> 的 review
```

**輸出：**
- 每條意見處理結果
- inline comments 已回覆

**哲學：** 只有技術理由能讓你 Pushback，不接受懶惰。

---

## 階段 5：發布（@publisher — Sonnet）

**核心：** 最後一哩路。
**觸發：** reviewer 審查通過

```
@publisher 發布 <branch-name>
```

**輸出：**
- PR 描述草稿（等待確認）
- PR URL
- Worktree 清理完畢

**哲學：** 完美的開發流程應終於乾淨的環境。

---

## 快速參考

| 階段 | Subagent | Model | 核心 Skills |
|------|----------|-------|-------------|
| 構思規劃 | @planner | Opus | superpowers:brainstorming, superpowers:writing-plans |
| 建立分支 | @brancher | Sonnet | gen-issue-from-plan, gen-branch |
| 實作 | @implementer | Sonnet | superpowers:subagent-driven-development, gen-commit |
| 審查 | @reviewer | Opus | gen-pr-code-review, superpowers:verification-before-completion |
| 回覆 Review | @responder | Sonnet | superpowers:receiving-code-review, gen-pr-reply |
| 發布 | @publisher | Sonnet | gen-pr, superpowers:finishing-a-development-branch |

---

## 跳入特定階段

不需要從頭開始，直接指定階段：

```
# 只需要審查
@reviewer 審查 feature/202605/42-new-feature

# 只需要發 PR
@publisher 發布 feature/202605/42-new-feature

# 只需要建分支
@brancher gen-branch 42
```
