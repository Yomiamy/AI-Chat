# AI-Chat 專案開發機會分析報告

**生成時間**：2026-04-16 02:16:07  
**分析方式**：3 個平行 Agent 從不同角度同時分析，最後彙整

---

## 分析架構

| Agent | 負責面向 | 執行時間 |
|-------|---------|---------|
| **Agent 1** — 核心功能 & 架構 | 已實現功能、功能缺口、架構改進機會 | 124s |
| **Agent 2** — UX & 行動平台 & CI/CD | 平台整合、CI/CD 差距、UX 優化 | 138s |
| **Agent 3** — AI 能力 & 第三方整合 | AI 提供商、已實現 AI 功能、整合機會 | 93s |

---

## 現況總覽（3 Agent 共識）

AI-Chat 是一個 **Firebase Gemini AI 驅動的單線程聊天應用**。架構清晰、BLoC 模式規範，但功能集中在基礎聊天，企業級能力明顯不足。

**技術棧**：Flutter + Firebase AI (Gemini 2.5 Flash) + ObjectBox + BLoC + GetIt

---

## Agent 1：核心功能 & 架構分析

### 已實現功能

- **Gemini 2.5 Flash** 串流回應（`firebase_ai: ^3.9.0`）
- **多媒體支援**：圖片（Base64）+ 檔案（上限 5MB）
- **ObjectBox 本地持久化**：最多 100 筆訊息，重啟後可還原（文字部分）
- **Markdown 渲染**：`flutter_markdown ^0.7.7+1`，含程式碼區塊
- **BLoC 狀態管理**：7 個精細化 Status enum
- **多語言**：繁中 (zh_TW) + 英文
- **DI 框架**：GetIt Service Locator

### 功能缺口（有代碼證據）

#### 1. 多對話會話管理（高優先級）
- `ChatMessage` entity 缺少 `sessionId`、`sessionTitle` 欄位
- `ChatRepository` 只有全局 `_chatList`，無會話隔離
- 設計文件 `docs/plans/20-objectbox-chat-cache-design.md` 第 388-393 行明確標為「YAGNI 範圍外」
- **建議**：新增 `ChatSession` Entity + 修改 `ChatRepository` 加入 `createSession()`、`switchSession()`

#### 2. 設定面板（高優先級）
- `ai_chat_view.dart` line 71-74：Menu IconButton `onPressed: () {}` 完全空白
- 無溫度（temperature）、TopP、模型版本等 API 參數調整
- 主題寫死為單一 `colorScheme.fromSeed()`
- **建議**：新建 `SettingsBloc` + `SettingsPage`，用 SharedPreferences 儲存偏好

#### 3. 附件本地化儲存（中優先級）
- `_stripBase64()` 方法（`chat_repository.dart` line 240-247）把圖片 Base64 替換為文字佔位符
- App 重啟後圖片無法還原
- **建議**：新增 `ChatAttachment` Entity，使用 `path_provider` 存入應用沙箱

#### 4. 對話搜尋與匯出（中優先級）
- `ChatRepository` 只有 `loadMessages()` 和 `saveMessage()`，無查詢功能
- **建議**：新增 `searchMessages(String query)`、`exportChat(session, format)`

#### 5. 錯誤恢復與重試（中優先級）
- `Status.noInternetConnection` 定義但從未被觸發
- 無離線佇列機制
- **建議**：指數退避重試 + `connectivity_plus` 離線偵測

### 架構改進機會

| 項目 | 現況問題 | 建議方向 |
|------|---------|---------|
| `GeminiApiBloc` | 混合模型初始化、檔案選取、訊息發送 | 抽出 `FilePickerBloc` 獨立管理 |
| `ChatRepository` | 無分頁、無事件流 | 加入 `loadMessages(page, pageSize)` + Stream |
| DI 層 | 只有 `ChatRepository` 在 `injection.dart` | 補上 `GeminiService`、`PreferencesRepository`、`ConnectivityService` |
| 連線層 | 直接在 Bloc 呼叫 Firebase AI | 新建 `GeminiService` 抽象介面，封裝重試與流量控制 |

---

## Agent 2：UX & 行動平台 & CI/CD 分析

### 已實現的平台功能

**iOS**
- Firebase 4 環境配置（Dev / Beta / Prod）
- 相片庫 `NSPhotoLibraryUsageDescription` 權限宣告
- Fastlane ad-hoc 自動化（`local_build`、`beta_build`、`beta_deploy`）

**Android**
- `READ_MEDIA_IMAGES` + `READ_EXTERNAL_STORAGE` 權限宣告
- Kotlin 1.7+ / Java 17 Gradle 配置
- Firebase Google Play Services

### 缺失的平台功能

| 功能 | iOS | Android | 影響 |
|------|-----|---------|------|
| 推送通知（FCM） | ❌ | ❌ | 無法提醒用戶 AI 回覆完成 |
| 深連結（Deep Linking） | ❌ | ❌ | 無法從外部跳轉到特定對話 |
| 後台處理 | ❌ | ❌ | 無離線同步或後台 AI 任務 |
| 生物辨識鎖定 | ❌ | ❌ | 無隱私保護 |
| App Shortcuts / App Links | ❌ | ❌ | 快速操作入口缺失 |
| 訊息分享 | ❌ | ❌ | 無法分享對話記錄 |
| 暗色模式完整支援 | ⚠️ | ⚠️ | `main.dart` 無 `ThemeData.dark()` |

### CI/CD 缺口

| 項目 | 狀態 | 建議 |
|------|------|------|
| **GitHub Actions** | ❌ 無 `.github/workflows/` | 建立自動化測試 + 構建 + 發布流程 |
| **Android Fastlane** | ❌ 無 | 對稱 iOS，實現自動簽名 + Firebase Distribution |
| **自動化測試 in CI** | ⚠️ test 目錄存在但幾乎空 | 加入 widget / integration test CI gate |
| **版本自動化** | ⚠️ 手動 | 無自動版本 bump、Changelog 生成 |
| **代碼品質掃描** | ❌ 無 | SonarQube 或 GitHub CodeQL |
| **App Store / Google Play 發行** | ❌ 無 | 只有 Firebase Distribution，缺正式商店上架流程 |

### UX 改進空間

| 項目 | 現況 | 建議 |
|------|------|------|
| 聊天搜尋 | ❌ 無 | `SearchDelegate` 搜尋歷史訊息 |
| 多對話支援 | ❌ 單線程 | 對話列表 + 快速切換 |
| 訊息長按選單 | ⚠️ 僅複製 | 加入分享、收藏、刪除 |
| 草稿自動儲存 | ❌ 無 | 自動儲存未發送輸入 |
| 語音輸入/輸出 | ❌ 無 | `speech_to_text` + `flutter_tts` |
| 骨架屏 / 漸進式載入 | ⚠️ 簡單旋轉 | Shimmer 效果提升感知效能 |
| 動畫過渡 | ⚠️ 基礎 | Material 3 精緻頁面切換動畫 |

---

## Agent 3：AI 能力 & 第三方整合分析

### 目前整合的 AI 提供商

- **唯一提供商**：Google Gemini（透過 `firebase_ai: ^3.9.0`）
- **模型**：硬編碼為 `gemini-2.5-flash`（`gemini_api_bloc.dart` 第 188 行）
- **整合方式**：Firebase AI Logic（`_initFirebaseAiLogic()` 第 186-195 行）

### 已實現的 AI 功能

| 功能 | 狀態 | 位置 |
|------|------|------|
| 串流回應 | ✅ | `gemini_api_bloc.dart` 第 80-117 行 |
| 多模態輸入（文字 + 圖片 + 檔案） | ✅ | 第 196-225 行 |
| 多種回應內容解析（Text/Code/InlineData） | ✅ | 第 87-101 行 |
| Markdown 渲染 | ✅ | `message_bubble_widget.dart` |
| 本地持久化 | ✅ | `chat_repository.dart` |

### 明顯缺失的 AI 功能

| 功能 | 說明 |
|------|------|
| **函數調用（Function Calling）** | 完全未實現，無法讓 AI 主動調用 App 功能 |
| **對話上下文管理** | 每次請求獨立，不傳送對話歷史，AI 無記憶 |
| **模型選擇與切換** | 硬編碼，無法在 runtime 切換 Gemini 版本 |
| **提示詞工程** | 提示硬編碼（第 219-236 行），無範本系統 |
| **多 AI 提供商支援** | 無 OpenAI / Anthropic Claude / LLaMA 等 |
| **RAG（檢索增強生成）** | 無向量資料庫、無本地知識庫 |

### 第三方整合現狀

**已整合（但未完整使用）**

| 套件 | 用途 | 備註 |
|------|------|------|
| `firebase_app_check` | 安全驗證 | 已安裝，未啟用 |
| `firebase_auth` 相關 | 身份驗證 | DI 有位置預留但未實現 |

**明顯缺失的整合**

| 類別 | 建議整合 | 用途 |
|------|---------|------|
| 身份驗證 | Firebase Auth | 用戶帳號 + 跨設備同步 |
| 雲端資料庫 | Firestore | 跨設備聊天記錄同步 |
| 錯誤追蹤 | Firebase Crashlytics | 生產環境 crash 監控 |
| 向量資料庫 | Pinecone / Supabase Vector | RAG 知識庫 |
| 搜尋引擎 | Typesense / Elasticsearch | 語義搜尋 |

---

## 綜合開發路線圖

### 短期（1-2 週）— 高影響、低複雜度

1. **設定面板** — 解鎖空白的 Menu 按鈕，實現模型選擇、溫度調整、暗色模式
2. **GitHub Actions 基礎流程** — Flutter test + build，自動觸發 Fastlane beta
3. **對話上下文傳送** — 在 `GeminiApiBloc` 傳送完整歷史，讓 AI 有記憶

### 中期（3-4 週）— 核心體驗提升

4. **多對話會話管理** — `ChatSession` Entity + 對話列表頁面
5. **推送通知（FCM）** — Firebase 已就緒，加入 `firebase_messaging`
6. **Android Fastlane** — 對稱 iOS，建立 Android beta 自動化
7. **訊息搜尋** — `ChatRepository.searchMessages()` + 搜尋 UI

### 長期（1-2 月）— 能力升級

8. **多模型支援** — 建立 `AIProviderAbstraction`，支援 Gemini Pro / Flash 切換
9. **Function Calling / Tool Use** — 讓 AI 調用 App 原生功能
10. **RAG 知識庫** — 向量資料庫整合，支援文件問答
11. **Firebase Auth + Firestore 同步** — 用戶帳號 + 跨設備資料同步
12. **附件本地快取** — `ChatAttachment` Entity + 圖片庫查看

---

## 優先級矩陣

| 功能 | 影響力 | 複雜度 | 建議順序 |
|------|--------|--------|---------|
| 設定面板 | 高 | 低 | ⭐ 第 1 |
| GitHub Actions CI | 高 | 低 | ⭐ 第 2 |
| 對話上下文傳送 | 高 | 低 | ⭐ 第 3 |
| 多對話會話 | 高 | 中 | ⭐ 第 4 |
| 推送通知 | 中 | 低 | 第 5 |
| Android Fastlane | 中 | 低 | 第 6 |
| 訊息搜尋 | 中 | 中 | 第 7 |
| 多模型支援 | 高 | 中 | 第 8 |
| Function Calling | 高 | 高 | 第 9 |
| RAG 系統 | 高 | 高 | 第 10 |
| Firebase Auth + 同步 | 中 | 高 | 第 11 |
