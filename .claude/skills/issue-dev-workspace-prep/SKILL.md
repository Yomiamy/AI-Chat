---
name: issue-dev-workspace-prep
description: 在 context-collector 已產出 issue 脈絡、且使用者想準備開發分支或 worktree 之後使用。以 .agent-output/context/* 作為 issue id、slug、工作類型與 blocker 的來源；建立新 worktree 時，必須在任何 issue-doc-writer 或 issue-spec-writer 執行之前，將當前脈絡輸出複製進新 worktree。
---

# Issue Dev Workspace Prep

使用此 skill 從脈絡輸出準備開發工作區。

## 可修改

- Git branch / worktree 狀態。
- 目標 worktree 中 `.agent-output/context/*` 底下本地複製的脈絡檔。

## 不可修改

- Production code。
- Tests。
- `docs/issues/*`。
- `docs/issues/specs/*`。
- PRs。
- YouTrack 留言或 State。

## 必要輸入

- `.agent-output/context/*` 底下一份當前的 `context-collector` 輸出檔。

若缺少，路由至 `context-collector`。

## 工作流程

1. 讀取脈絡檔。
2. 確認 `Handoff` 為 `workspace-prep-ready`。
3. 解析 issue id（若存在）、工作類型、slug 與 blocker。
4. 檢視當前 branch/status 與既有 worktree。
5. 選擇 `current-branch`、`current-worktree-new-branch`、`new-worktree` 或 `no-prep`。
6. 執行所選的工作區策略。
7. 若建立 `new-worktree`，將當前脈絡檔複製進目標 worktree。
8. 驗證複製的脈絡檔存在於目標 worktree。
9. 回報工作區結果與下一個 skill。

## 新 Worktree 腳本

建立新 worktree 時優先使用內附腳本：

```bash
scripts/prepare_ticket_dev_workspace.sh --ticket-id "<ISSUE-ID>" --prefix "<fix/|feature/|chore/>" --slug "<slug>"
```

無 ticket 的 issue 省略 `--ticket-id`：

```bash
scripts/prepare_ticket_dev_workspace.sh --prefix "<fix/|feature/|chore/>" --slug "<slug>"
```

該腳本也會將僅限本地的開發設定同步進目標 worktree，包括：

- 根目錄 `.env` 與 `.env.*`
- `android/key.properties`
- `android/app/google-services.json`
- Android 簽章檔，例如 `*.keystore` 與 `*.jks`
- `ios/Runner/GoogleService-Info.plist`
- iOS / Android `fastlane` 私有簽章或憑證檔

只有在使用者明確不要複製本地設定時才使用 `--skip-local-config-sync`。

## 強制脈絡交接

若策略為 `new-worktree`：

```text
copy .agent-output/context/<subject>.md from source workspace to target worktree
verify target .agent-output/context/<subject>.md exists
stop if copy or verification fails
```

在執行 `issue-doc-writer` 或 `issue-spec-writer` 之前完成此事。

## 命名

存在時使用 issue id。否則使用 slug。

Branch 範例：

- `fix/<ISSUE-ID>-<slug>`
- `feature/<ISSUE-ID>-<slug>`
- `chore/<ISSUE-ID>-<slug>`
- 無 issue id：`<type>/<slug>`

## 輸出規則

回報：

- 使用的脈絡檔。
- 策略。
- branch。
- worktree。
- 脈絡複製結果。
- blocker。
- 下一個 skill：通常是 `issue-doc-writer`。

主要語言：`zh-tw`。
