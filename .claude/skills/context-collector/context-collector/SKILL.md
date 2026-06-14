---
name: context-collector
description: 當 Codex 需要在撰寫 issue 文件、spec、工作區準備、實作或工作流程路由之前，從 YouTrack ticket、使用者說明、QA 報告、分支脈絡或聚焦的 repo 證據收集正規 issue 脈絡時使用。產出或刷新 .agent-output/context/<issue-id-or-slug>.md 作為主要的 facts/inference/open-questions 來源，且不修改 source、tests、specs、PRs 或 YouTrack 狀態。
---

# Context Collector

將此 skill 作為正規的 issue 脈絡來源。

## 角色

- 角色：issue 脈絡收集者。
- 策略：facts 收集一次，讓下游 skill 讀取同一份來源。

## 可修改

- `.agent-output/context/*`。

## 不可修改

- Production code。
- Tests。
- `docs/issues/*`。
- `docs/issues/specs/*`。
- PRs。
- YouTrack 留言或 State。

## 輸入

接受任何 issue 來源：

- YouTrack issue id。
- 使用者提供的 issue 說明。
- QA 報告。
- Feature request。
- 當前分支脈絡。
- 既有 issue 文件或 spec 刷新請求。

## 工作流程

1. 解析 subject。
2. 視情況從 YouTrack、使用者說明、分支脈絡、QA 證據與聚焦的 repo 檢視讀取來源事實。
3. 區分 facts、inference 與 open questions。
4. 只檢視理解可能受影響區域所需的程式碼。
5. 撰寫或刷新 `.agent-output/context/<subject>.md`。
6. 在同一檔案中保留精簡的 `History` 表格。
7. 回報脈絡檔路徑，以及它是否已就緒可進行 issue doc、workspace prep，或被 blocked。

## 路徑規則

每個 subject 使用一份正規檔案：

- 有 issue id：`.agent-output/context/<ISSUE-ID>.md`
- 無 issue id：`.agent-output/context/<slug>.md`

不要在檔名加上 `-context`，因為資料夾已定義 artifact 類型。

若刷新同一 subject，覆寫同一檔案並更新 `History`。不要建立 `history/` 資料夾。

## 必要段落

使用此結構：

```markdown
# <Subject> Context

## Source

## Summary

## Facts

## Code Observations

## Inference

## Open Questions

## Suggested Slug

## Handoff

## History

| Time | Change | Source | Notes |
| --- | --- | --- | --- |
```

`Handoff` 必須是以下其一：

- `issue-doc-ready`
- `workspace-prep-ready`
- `blocked`

被 blocked 時附上 blocker 原因。

## History 規則

- 每次脈絡刷新加一列表格。
- 摘要該變更、來源與注意事項。
- 不要貼上完整舊內容或完整來源文字。

## 輸出規則

- 主要語言：`zh-tw`。
- 保留必要的 `en-us` 技術術語。
- 只回報脈絡路徑、就緒度、blocker 與建議的下一個 skill。
