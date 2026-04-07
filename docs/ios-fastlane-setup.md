# iOS Fastlane 打包指南

## 概述

使用 Fastlane 將 AI-Chat iOS app 打包並分發至 Firebase App Distribution（Ad Hoc）。

---

## 目錄結構

```
ios/
├── fastlane/
│   ├── Fastfile                    ← Fastlane 設定
│   ├── .gitignore                  ← 排除敏感檔案
│   ├── stg-distribution.p12        ← 手動放置（已 gitignore）
│   ├── stg-profile.mobileprovision ← 手動放置（已 gitignore）
│   └── stg-credentials.json        ← 手動放置（已 gitignore）
├── Gemfile                         ← Ruby 依賴
└── Gemfile.lock                    ← bundle install 產生（已 gitignore）
```

---

## 首次設定

### 1. 安裝依賴

```bash
cd ios
bundle install
```

### 2. 準備敏感檔案（不進版控）

將以下三個檔案放入 `ios/fastlane/` 目錄：

| 檔案 | 來源 | 說明 |
|------|------|------|
| `stg-distribution.p12` | Keychain Access 匯出 | Apple Distribution 憑證 + 私鑰 |
| `stg-profile.mobileprovision` | Apple Developer Portal → Profiles | Ad Hoc profile，Bundle ID: `com.flutter.ai-chat` |
| `stg-credentials.json` | Firebase Console → Project Settings → Service Accounts | Firebase 服務帳號 JSON |

#### 匯出 `stg-distribution.p12` 的正確步驟

1. 打開 **Keychain Access**
2. 找到 **Apple Distribution: Li-Sheng Hsu (H2724L9BS5)**
3. **展開**憑證（點左側三角形），確認底下有私鑰
4. 同時選取憑證與私鑰（或僅選憑證行，確保私鑰包含在內）
5. 右鍵 → Export → 儲存為 `stg-distribution.p12`，設定密碼

> **注意**：必須匯出 **Apple Distribution**，不是 Apple Development。

---

## 環境變數

執行任何 lane 前，需設定以下環境變數：

| 變數 | 說明 | 範例 |
|------|------|------|
| `CERTIFICATE_PASSWORD` | `.p12` 匯出時設定的密碼 | `my-p12-password` |
| `KEYCHAIN_NAME` | macOS Keychain 名稱 | `login` |
| `KEYCHAIN_PASSWORD` | Keychain 密碼（通常是電腦登入密碼） | `my-mac-password` |
| `TEAM_ID` | Apple Developer Team ID | `H2724L9BS5` |
| `FIREBASE_APP_ID` | Firebase iOS App ID | `1:719921143375:ios:73a03008b4782986f0543a` |
| `FIREBASE_RELEASE_NOTES` | 發布備註（可選，留空也可） | `Fix login crash` |
| `FIREBASE_GROUPS` | Firebase 分發群組（可選，預設 `qa&rd`） | `qa&rd` |

### 設定環境變數範例

```bash
export CERTIFICATE_PASSWORD="你的p12密碼"
export KEYCHAIN_NAME="login"
export KEYCHAIN_PASSWORD="你的電腦登入密碼"
export TEAM_ID="H2724L9BS5"
export FIREBASE_APP_ID="1:719921143375:ios:73a03008b4782986f0543a"
export FIREBASE_RELEASE_NOTES="beta build"
export FIREBASE_GROUPS="qa&rd"   # 需與 Firebase Console 上建立的群組名稱一致
```

---

## Lanes 說明

### `local_build` — 本地打包

本地驗證 Ad Hoc 打包流程，不上傳 Firebase。

```bash
cd ios
bundle exec fastlane local_build
```

**執行步驟：**
1. 匯入 Distribution 憑證到 Keychain
2. 安裝 Provisioning Profile
3. 關閉 Xcode Automatic Signing，指定手動簽名
4. gym 打包 → 輸出 `build/ios/profile/ai_chat.ipa`

---

### `beta_build` — Beta 打包

與 `local_build` 相同，單獨打包步驟（給 CI 拆分使用）。

```bash
bundle exec fastlane beta_build
```

---

### `beta_deploy` — 上傳 Firebase

將已打好的 IPA 上傳至 Firebase App Distribution。

```bash
bundle exec fastlane beta_deploy
```

**需要：**
- `build/ios/profile/ai_chat.ipa` 已存在
- `FIREBASE_APP_ID` 環境變數
- `fastlane/stg-credentials.json`

---

### `beta` — 完整流程（推薦）

打包 + 上傳一鍵完成。

```bash
bundle exec fastlane beta
```

---

## 專案資訊

| 項目 | 值 |
|------|-----|
| Bundle ID | `com.flutter.ai-chat` |
| Team ID | `H2724L9BS5` |
| Firebase App ID | `1:719921143375:ios:73a03008b4782986f0543a` |
| Xcode Workspace | `Runner.xcworkspace` |
| Build Configuration | `Profile`（beta）|
| IPA 輸出路徑 | `build/ios/profile/ai_chat.ipa` |
| Firebase 分發群組 | `qa&rd` |

---

## 常見錯誤排查

### ❌ `Provisioning profile doesn't include signing certificate`

**錯誤訊息**：
```
error: Provisioning profile "(Adhoc)Ai Chat" doesn't include signing certificate "Apple Development: ..."
```

**原因**：Xcode Automatic Signing 介入，用了本機的 Apple Development 憑證，但 Ad Hoc profile 綁定的是 Apple Distribution 憑證，兩者不符。

**調整**：在 Fastfile 加入 `update_code_signing_settings` 強制關閉 Automatic Signing：

```ruby
update_code_signing_settings(
    use_automatic_signing: false,
    path: "Runner.xcodeproj",
    team_id: ENV["TEAM_ID"],
    code_sign_identity: "Apple Distribution",
    profile_name: "(Adhoc)Ai Chat",
    targets: ["Runner"],
    build_configurations: ["Profile"],
)
```

**前置條件**：
- `stg-distribution.p12` 必須匯出 **Apple Distribution**（非 Apple Development）
- 設定 `TEAM_ID` 環境變數（`H2724L9BS5`）

---

### ❌ `The authenticated user does not have the required permissions`

**錯誤訊息**：
```
The authenticated user does not have the required permissions on the Firebase project
```

**原因**：`stg-credentials.json` 的 Google 服務帳號缺少 Firebase App Distribution 上傳權限。

**解法**：
1. 開啟 [Google Cloud Console - IAM](https://console.cloud.google.com/iam-admin/iam)
2. 找到 `stg-credentials.json` 裡的服務帳號 email（`cat fastlane/stg-credentials.json | grep client_email`）
3. 新增角色：**Firebase App Distribution Admin**

---

### ❌ `Invalid request`（distribute 階段）

**錯誤訊息**：
```
Invalid request  ← 出現在 distribute_release，非 upload_binary
```

**原因**：IPA 上傳成功，但指定分發的群組名稱在 Firebase 專案中不存在。

**解法**：
1. 開啟 Firebase Console → **App Distribution** → **Testers & Groups**
2. 建立群組，名稱與 Fastfile 中的 `groups` 一致（預設 `qa&rd`）

或透過環境變數指定已存在的群組：
```bash
export FIREBASE_GROUPS="你的群組名稱"
bundle exec fastlane beta_deploy
```

---

### ❌ `No profile for team ... matching ...`

**原因**：Profile 未安裝或 Bundle ID 不符。

**解法**：確認 `stg-profile.mobileprovision` 的 Bundle ID 是 `com.flutter.ai-chat`，且類型為 **Ad Hoc**（非 Development 或 App Store）。
