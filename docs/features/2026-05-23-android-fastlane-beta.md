# 功能規格：Android Fastlane Beta 打包流程

- **日期**：2026-05-23
- **狀態**：待確認
- **參考**：`/Users/yomiry/Eslite/Eslite-v3/eslite-monorepo-app/eslite_v3/android/fastlane/Fastfile`、本專案 `ios/fastlane/Fastfile`

## What & Why

### 背景
AI-Chat 是 Flutter 專案，iOS 端已有 fastlane beta 流程（cocoapods → 版號同步 → 簽章 → gym → Firebase App Distribution）。Android 端目前**完全沒有 fastlane**，每次出測試包都要手動 `flutter build apk` 再手動上傳，流程不可重現、容易出錯。

### 目標
在 `android/` 下建立與 iOS 端對齊的 fastlane beta 流程，讓 Android 測試包能用單一指令打包並上傳 Firebase App Distribution，供 QA/RD 取用。

### 為什麼是 beta-only、不動簽名（範圍邊界）
- **不動簽名**（使用者明確指示）：現有 `build.gradle.kts` 的 release 仍用 debug 簽金，beta 測試包用 debug 簽章即可運作，不需要 keystore。Play Store 正式上架（需正式簽名）**不在本次範圍**。
- **beta-only**：對齊 iOS 端現況（iOS 也只有 beta lane），先把測試發佈閉環打通。prod（AAB + Play Store 上架）留待後續。

## 使用者故事

1. **作為 RD**，我想執行 `fastlane android beta`，就能自動打出 Android 測試 APK 並上傳 Firebase App Distribution，不必記憶手動步驟。
2. **作為 RD**，我想讓 Android 的 app 版號自動從 `pubspec.yaml` 同步（與 iOS 行為一致），不必在兩處手動維護版號。
3. **作為 QA**，我想在 Firebase App Distribution 的 qa&rd 群組收到新測試包通知，附帶 release notes。
4. **作為新進成員**，我想看 README 就能知道需要哪些環境變數與憑證檔，自行把流程跑起來。

## 驗收條件

- [ ] `android/fastlane/Fastfile` 存在，提供 `beta_build`、`beta_deploy`、`beta` 三條 lane（與 iOS 對齊）。
- [ ] `beta_build` 能用 Flutter Gradle 打出 APK（沿用現有 debug 簽章，不需 keystore）。
- [ ] `beta_build` 自動從 `pubspec.yaml` 讀取 `version` 與 build number 套用到 Android 建置（行為對齊 iOS Fastfile 第 11-15 行）。
- [ ] `beta_deploy` 透過 `firebase_app_distribution` 上傳 APK 到指定 Firebase App，群組 `qa&rd`，支援 `FIREBASE_RELEASE_NOTES` 環境變數。
- [ ] `android/Gemfile` 宣告 `fastlane` 與 `fastlane-plugin-firebase_app_distribution`。
- [ ] `android/.gitignore` 排除憑證檔（service credentials json）與 fastlane 產出物（report.xml、README.md）、Gemfile.lock，比照 Eslite/iOS 慣例。
- [ ] `android/fastlane/README.md` 說明所需環境變數（`FIREBASE_APP_ID`、`FIREBASE_RELEASE_NOTES`、`FIREBASE_GROUPS`）與 service credentials 檔放置位置。
- [ ] 敏感檔（service credentials json）**不**進版控。

## 範圍邊界

### 包含
- Android beta 打包（APK）+ Firebase App Distribution 上傳
- 版號從 pubspec.yaml 同步
- Gemfile、.gitignore、README 配套

### 不包含（明確排除）
- ❌ Release 簽名設定（keystore / key.properties / build.gradle.kts release signingConfig）
- ❌ prod_build（AAB 打包）
- ❌ prod_deploy（Google Play Store 上架）
- ❌ CI（GitHub Actions / fastlane 自動觸發）整合
- ❌ 多 flavor / 多環境（stg/prod applicationId 切換）

## 關鍵設計差異備註

- Eslite 用 `build_type: "Profile"` + `gradle` action 直接打 Android 原生 task；AI-Chat 是標準 Flutter 專案，APK 產出路徑為 `build/app/outputs/flutter-apk/`，需確認用 `flutter build apk` 或 Flutter Gradle task 哪種較穩（實作計畫處理）。
- 版號同步邏輯可直接複用 iOS Fastfile 的 pubspec 解析寫法。
