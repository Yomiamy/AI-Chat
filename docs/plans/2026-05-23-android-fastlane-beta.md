# 實作計畫：Android Fastlane Beta 打包流程

- **日期**：2026-05-23
- **對應規格**：`docs/features/2026-05-23-android-fastlane-beta.md`
- **狀態**：待確認

## 核心設計決策

### 1. 用 `sh "flutter build apk"` 而非 Eslite 的 `gradle` action
**理由**（Linus：用最笨但最清楚的方式）：
- AI-Chat 是標準 Flutter 專案，`flutter build apk` 直接產出 `build/app/outputs/flutter-apk/app-release.apk`，路徑固定、行為可預期。
- Eslite 用 `gradle(task:..., build_type:"Profile", properties:{...})` 是因為它要做 applicationId/appName 動態切換（多環境）——AI-Chat **不需要**多環境，套用會憑空引入複雜度。
- 沿用現有 debug 簽章：`flutter build apk` 的 release 模式會走 `build.gradle.kts` 的 release buildType（目前指向 debug 簽金），正好符合「不動簽名」。

### 2. 版號同步：複用 iOS Fastfile 的 pubspec 解析
iOS Fastfile 第 11-15 行已驗證可用的寫法：
```ruby
pubspec = File.read("../../pubspec.yaml")
version = pubspec.match(/^version:\s(.+)\+/)[1]
build = pubspec.match(/\+(\d+)$/)[1]
```
Android 端透過 `flutter build apk --build-name=#{version} --build-number=#{build}` 套用，無需改動 gradle 檔。

### 3. 產出檔名對齊
beta APK 路徑：`../build/app/outputs/flutter-apk/app-release.apk`（相對於 `android/` 目錄）。

## 檔案異動清單

| 檔案 | 動作 | 說明 |
|------|------|------|
| `android/fastlane/Fastfile` | 新增 | beta_build / beta_deploy / beta 三條 lane |
| `android/Gemfile` | 新增 | fastlane + firebase_app_distribution plugin |
| `android/.gitignore` | 修改 | 追加 fastlane 相關忽略項 |
| `android/fastlane/README.md` | 新增 | 環境變數與憑證放置說明 |

> 注意：`android/fastlane/stg-credentials.json`（Firebase service account）由使用者自行放置，**不**在本計畫產出，且被 .gitignore 排除。

## 任務拆分

### Task 1：建立 Gemfile 與 .gitignore 配套〔複雜度：低〕
- **寫入 scope**：`android/Gemfile`（新增）、`android/.gitignore`（修改）
- 內容：
  - `Gemfile` 比照 iOS：`fastlane` + `fastlane-plugin-firebase_app_distribution`
  - `.gitignore` 追加：`/Gemfile.lock`、`/fastlane/stg-credentials.json`、`/fastlane/report.xml`、`/fastlane/README.md`
- 驗收：`cat` 檢視內容正確；`.gitignore` 不重複既有項目

### Task 2：撰寫 Fastfile〔複雜度：中〕
- **寫入 scope**：`android/fastlane/Fastfile`（新增）
- 內容：三條 lane
  - `beta_build`：解析 pubspec 版號 → `sh "cd ../.. && flutter build apk --build-name=#{version} --build-number=#{build}"`
  - `beta_deploy`：`firebase_app_distribution`（app=`ENV["FIREBASE_APP_ID"]`、credentials=`fastlane/stg-credentials.json`、apk_path=`../build/app/outputs/flutter-apk/app-release.apk`、groups=`ENV["FIREBASE_GROUPS"] || "qa&rd"`、release_notes 支援 `FIREBASE_RELEASE_NOTES`）
  - `beta`：依序呼叫 `beta_build` + `beta_deploy`
- 驗收：`bundle exec fastlane android beta_build` 能成功打出 APK（deploy 因需真實憑證，僅做語法驗證 `fastlane lanes`）

### Task 3：撰寫 README〔複雜度：低〕
- **寫入 scope**：`android/fastlane/README.md`
- 內容：必要環境變數表（`FIREBASE_APP_ID`、`FIREBASE_RELEASE_NOTES`、`FIREBASE_GROUPS`）、`stg-credentials.json` 放置位置、`bundle install` + `bundle exec fastlane android beta` 使用範例
- 驗收：步驟可被新進成員照著跑

## 並行分析

- Task 1、Task 3 寫入路徑互不重疊（Gemfile/.gitignore vs README），**可並行**。
- Task 2（Fastfile）是核心，README（Task 3）需引用 Fastfile 的 lane 名稱與環境變數，建議 **Task 2 → Task 3 序列**。
- 結論：**Task 1 與 Task 2 可並行**（不同檔案，無依賴）→ 完成後做 Task 3。
- 實際執行採序列亦可（任務量小），並行非必要。

## 驗證方式

1. `cd android && bundle install`（安裝 fastlane）
2. `bundle exec fastlane android beta_build`（實打 APK，驗證 build lane）
3. `bundle exec fastlane lanes`（列出 lane，驗證 Fastfile 語法）
4. deploy lane 需真實 Firebase 憑證，本流程只驗證語法正確，不實際上傳。

## 風險點

- **flutter build apk 與 fastlane 工作目錄**：fastlane 在 `android/fastlane/` 執行，`flutter build` 需在專案根目錄跑，故 lane 內用 `cd ../..`。需確認相對路徑正確。
- **debug 簽章的 release APK**：`flutter build apk`（release 模式）會用 build.gradle.kts 的 release signingConfig（目前 = debug）。Firebase App Distribution 接受 debug 簽章 APK，無問題。
