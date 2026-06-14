---
name: ticket-id-dev-prep
description: 當使用者提供 YouTrack ticket id 連同已解析的 ticket brief、並希望 Codex 從安全的 base 建立新的 git 分支與 worktree、保留既有命名規則並完成最小開發設定、且不依賴當前分支名稱時使用此 skill。
---

# Ticket Id Dev Prep

當使用者給出明確的 YouTrack ticket id（例如 `BUG-2351`）連同已解析的 ticket brief、且想要分支/worktree 準備而非全新的端到端 ticket 調查時，使用此 skill。

## 目標

將貼上的已解析 ticket brief 轉成安全、可立即開工的工作區：

1. 從已解析的 ticket brief 開始
2. 將 ticket 濃縮成一個簡短的英文 slug 供命名
3. 建立新的 worktree
4. 建立新的分支
5. 完成務實的設定檢查，使開發能立即開始

## 工作流程

1. 從使用者訊息讀取 ticket id。
2. 優先使用使用者在當前對話中貼上的已解析 ticket brief。
3. 若同一對話稍早已存在可靠的解析 brief，可重複使用。
4. 若尚無可靠的解析 brief，在進行任何命名或 git 寫入工作之前，先執行或請求 `ticket-code-investigator` 的等效調查流程。
5. 所有命名與設定決策都以解析結果為依據，特別是：
   - 問題或目標
   - 可能的實作區域
   - 此工作是 bug 修復、feature 或維護任務
   - 任何可能使命名不可靠的曖昧之處
6. 將該解析結果濃縮成一份 `zh-tw` 的簡短實作 brief。
7. 產出一個精簡的英文命名片語，可同時作為：
   - branch slug
   - worktree suffix
8. 從解析出的 ticket 意圖選擇分支前綴：
   - `fix/` 用於 bug、回歸、錯誤、不一致或 validator 問題
   - `feature/` 用於新能力或使用者可見的擴充
   - `chore/` 用於重構、維護、內部工具或非使用者可見的清理
9. base 分支預設為 `origin/main`，除非使用者明確要求其他 base。
10. 從該 base 建立 worktree，並同時建立新分支。
11. 執行確認新工作區就緒所需的最小設定檢查：
   - 確認分支與路徑
   - 檢視 repo 狀態
   - 當來源 worktree 存在時，同步真實開發與本地 build 所需的僅限本地設定檔，例如 `.env`、Android 簽章 / Firebase 設定，以及 iOS Firebase / fastlane 簽章設定
   - 當來源 worktree 存在時，驗證 `android/app/google-services.json` 與 `ios/Runner/GoogleService-Info.plist` 已複製；若任一缺少，在 bootstrap 前明確回報
   - 在本地設定同步後，以 `flutter pub get` 執行此 repo 的依賴 bootstrap
12. 回報結果，附上已解析的 ticket brief、所選 slug、分支名稱、worktree 路徑與任何後續備註。

## 解析 Brief 規則

貼上的已解析 ticket brief 是以下事項的真實來源：

- 實作 brief
- 分支前綴選擇
- slug 生成
- 應在準備結果中保持可見的不確定性

若貼上的 brief 與當前對話脈絡衝突，提及該不一致，並在任何 git 寫入工作前詢問是否要刷新調查。

## 解析輸入規則

將已解析的 ticket brief 視為設定決策的真實來源。

永遠區分：

- 來自解析結果的 fact
- 準備過程中所做的命名 inference
- 仍需確認的待解曖昧

Brief 應涵蓋：

- 問題或目標
- 對使用者可見的影響
- 解析過程中已辨識的明確需求
- 解析過程中已觀察的技術線索
- 風險或缺漏的細節

不要發明不存在的 acceptance criteria。

若解析結果表明此 issue 可能不存在或仍需驗證，將該不確定性保持在準備輸出中可見，而非藏在一個看似篤定的 slug 之後。

## Slug 規則

英文命名片語應簡短、具體且可複用。

要求：

- 以已解析的 ticket brief 為依據，而非只憑 issue key
- 偏好 2 到 6 個英文單字
- 最終 slug 形式為小寫 kebab-case
- 保持與實作相關，不過度寬泛
- 避免填充詞，例如 `handle`、`update`、`improve`、`fix-issue`、`ticket-work`
- 偏好仍能清楚辨識工作的最短片語

好的範例：

- `password-fields-validator-error`
- `member-card-expired-state`
- `checkout-delivery-note`
- `apple-login-token-refresh`

避免：

- `bug-2351`
- `misc-fix`
- `update-something`
- `temporary-change`

## 分支與 Worktree 規則

依此順序建構名稱：

1. 分支名稱：`<prefix><TICKET-ID>-<slug>`
2. worktree 目錄名稱：`<repo-name>-<TICKET-ID-lowercase>-<slug>`

範例：

- branch：`fix/BUG-2351-password-fields-validator-error`
- worktree：`../ai-chat-bug-2351-password-fields-validator-error`

額外規則：

- 在分支名稱中保留 ticket id 的大小寫
- 在 worktree 目錄 suffix 中使用小寫 ticket id
- 偏好在當前 repo 旁建立新 worktree，除非使用者要求其他位置
- 若目標分支已存在於本地，停下並回報，而非靜默地重用它
- 若目標 worktree 路徑已存在，停下並回報，而非覆寫任何東西

## Git 執行規則

優先使用內附腳本以取得確定性的設定：

[`scripts/prepare_ticket_dev_workspace.sh`](./scripts/prepare_ticket_dev_workspace.sh)

用法：

```bash
./scripts/prepare_ticket_dev_workspace.sh \
  --ticket-id "BUG-2351" \
  --prefix "fix/" \
  --slug "password-fields-validator-error"

./scripts/prepare_ticket_dev_workspace.sh \
  --ticket-id "APP-412" \
  --prefix "feature/" \
  --slug "member-card-expired-state" \
  --base "origin/main"
```

行為：

- 在任何 git 寫入前驗證必要輸入
- base 分支預設為 `origin/main`
- worktree 父目錄預設為當前 repo 的父目錄
- 當 base ref 指向 `origin/*` 時 fetch 它
- 若目標分支已存在於本地則停止
- 若目標 worktree 路徑已存在則停止
- 預設將常見的僅限本地設定檔從來源 worktree 複製進新 worktree
- 當當前 worktree 缺少本地設定檔時，回退至已有這些檔案的鄰近 git worktree
- 印出描述已建立或預定工作區的標準化 JSON

本地設定同步在存在時涵蓋此 repo 常見的僅限開發檔案，例如：

- 任何 `.env` 或 `.env.*` 檔案
- `android/key.properties`
- `android/app/google-services.json`
- Android 簽章檔，例如 `*.keystore` 與 `*.jks`
- `ios/Runner/GoogleService-Info.plist`
- iOS / Android `fastlane` 私有簽章或憑證檔，例如 `*.json`、`*.plist`、`*.p8`、`*.p12` 與 `*.mobileprovision`

若你明確想要一個不複製本地機密的乾淨 worktree，以 `--skip-local-config-sync` 執行腳本。

手動回退流程：

```bash
git fetch origin main --prune
git worktree add -b "<branch-name>" "<worktree-path>" "origin/main"
```

若使用者要求不同的 base 分支，相應替換 `origin/main`。

建立 worktree 後：

1. 驗證 `git branch --show-current`
2. 驗證 `git status --short`
3. 執行 `flutter pub get`

當目標是隔離的 ticket 開發時，不要在已經 dirty 的當前 worktree 內建立分支。

## 設定完成規則

此 skill 應以一個可用的開發工作區作結，而不只是命名建議。

預設完成檢查清單：

1. 新 worktree 存在
2. 新分支存在且已於該處 checkout
3. 新 worktree 中的 repo 狀態在新編輯前是乾淨的
4. 當來源 worktree 存在時，必要的本地設定檔已複製進新 worktree
5. `flutter pub get` 已成功完成
6. 若設定無法自動完成，記下任何必要的後續指令

對此 repo 有用時，也執行以下一項或多項：

- 檢視 package 或 workspace 依賴檔
- 確認是否需要 code generation 或其他 bootstrap 步驟

對此 repo，除非使用者明確要求跳過，否則偏好以下具體初始化流程：

1. 將僅限本地的設定同步進新 worktree
2. 在 repo 根目錄執行 `flutter pub get`

偏好能快速解除開發阻塞的最小安全設定。

## 安全規則

- 在此 skill 中絕不從當前分支推斷 ticket id；必須由使用者提供。
- 若尚無可靠的解析 brief，在任何 git 寫入操作前停下，並先執行或請求調查。
- 若 ticket 摘要太模糊而無法建立可靠 slug，產出你能給的最佳精簡 slug，並說明它是一個命名 inference。
- 若當前 repo 有無關的 dirty 變更，不要修改它們；建立獨立 worktree 仍是首選。
- 若 `git fetch` 或其他依賴網路的 git 指令因環境限制失敗，清楚回報。
- 不要覆寫既有目錄或強制建立分支。

## 輸出規則

讓回應精簡且以執行為導向。

偏好的輸出形狀：

1. `Ticket`：issue key 與摘要
2. `Ticket 摘要`：簡短實作 brief
3. `English Slug`：命名片語
4. `Branch`：最終分支名稱
5. `Worktree`：最終 worktree 路徑
6. `Setup`：建立了什麼，或什麼阻塞了建立
7. `待確認`：僅在仍有實質曖昧時

## 風格規則

- 主要語言：`zh-tw`
- 允許的例外：必要的 `en-us` 專有名詞與技術術語，例如 `YouTrack`、`State`、`branch`、`worktree`、`slug`、`API`、`UI`、`Backend` 與 issue key
- 偏好語氣：精簡、可靠、且可直接執行
