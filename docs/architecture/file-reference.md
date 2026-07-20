# AI-Chat (Gemini AI Assistant) - 檔案用途與類型參考表 (File Reference)

本文件列出專案中所有核心源檔的單一職責、包含的關鍵類別與模組歸屬，幫助開發者快速掌握 `lib` 目錄下的架構配置。

---

## 📂 核心模組與檔案結構

### 1. 入口與依賴注入 (`lib/` 根目錄與 `lib/di/`)

| 檔案路徑 | 關鍵類別/方法 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/main.dart`](../../lib/main.dart) | `main()`, `MyApp` | 應用程式的進入點。負責 Firebase 初始化、DI 容器啟動、多語系設定與 Material 主題配置。 |
| [`lib/di/injection.dart`](../../lib/di/injection.dart) | `setupInjection()` | 負責配置 GetIt 依賴注入容器，註冊 `ChatRepository` 與 `GeminiApiBloc` 的全域實例，落實控制反轉。 |

### 2. 狀態控制層 (`lib/bloc/`)

遵循 BLoC 模式設計，分離業務邏輯與畫面。

| 檔案路徑 | 關鍵類別/列舉 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/bloc/gemini_api/gemini_api_bloc.dart`](../../lib/bloc/gemini_api/gemini_api_bloc.dart) | `GeminiApiBloc` | 負責處理所有與對話相關的意圖 (Events)，將其映射為狀態 (States)。處理串流字串累加與歷史紀錄持久化。 |
| [`lib/bloc/gemini_api/gemini_api_event.dart`](../../lib/bloc/gemini_api/gemini_api_event.dart) | `GeminiApiEvent` | 定義 BLoC 所接受的事件（發送訊息、清除對話、讀取歷史）。 |
| [`lib/bloc/gemini_api/gemini_api_state.dart`](../../lib/bloc/gemini_api/gemini_api_state.dart) | `GeminiApiState` | 定義 BLoC 的輸出狀態（Initial, Loading, Streaming, Success, Error）。 |
| [`lib/bloc/search/...`](../../lib/bloc/search/) | - | 保留用於未來或目前的對話內文搜尋功能狀態管理。 |

### 3. 資料與領域模型層 (`lib/data/`)

負責定義資料結構與外部資料源通訊。

| 檔案路徑 | 關鍵類別/列舉 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/data/chat_message.dart`](../../lib/data/chat_message.dart) | `ChatMessage` | 核心對話資料模型實體，包含身分角色 (user/model)、文字與時間戳記。 |
| [`lib/data/chat_repository.dart`](../../lib/data/chat_repository.dart) | `ChatRepository` | 資料層的抽象介面，定義獲取回覆串流與本地快取的合約，以便於進行單元測試與 Mock。 |
| [`lib/data/chat_repository_impl.dart`](../../lib/data/chat_repository_impl.dart) | `ChatRepositoryImpl` | 實作 `ChatRepository`，直接封裝 `firebase_ai` 的具體呼叫邏輯與 `shared_preferences` 的讀寫。 |

### 4. 表現層與 UI 元件 (`lib/pages/` 與其子目錄)

展示資料並捕捉用戶互動，絕不包含網路請求或資料庫邏輯。

| 檔案路徑 | 關鍵類別/元件 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/pages/ai_chat_page.dart`](../../lib/pages/ai_chat_page.dart) | `AiChatPage` | 主對話頁面。提供頂層 Scaffold 框架、AppBar (包含清空等動作選單) 與 BlocProvider 的依賴供給。 |
| [`lib/pages/widgets/ai_chat_view.dart`](../../lib/pages/widgets/ai_chat_view.dart) | `AiChatView` | 對話列表的核心容器。監聽 BLoC 狀態來構建 ListView，並處理新增訊息時的 Auto-scroll 到最底部的 UX 邏輯。 |
| [`lib/pages/widgets/input_area_widget.dart`](../../lib/pages/widgets/input_area_widget.dart) | `InputAreaWidget` | 獨立的文字輸入框元件。處理多行文本、實體鍵盤快捷鍵 (Enter 送出) 與發送按鈕的防呆機制。 |
| [`lib/pages/widgets/message_bubble_widget.dart`](../../lib/pages/widgets/message_bubble_widget.dart) | `MessageBubbleWidget` | 單則訊息對話泡泡。負責依據發送者 (User 或 AI) 決定對齊與顏色，並使用 `flutter_markdown` 渲染富文本。 |
| [`lib/pages/widgets/empty_widget.dart`](../../lib/pages/widgets/empty_widget.dart) | `EmptyWidget` | 剛啟動且無對話紀錄時顯示的空狀態提示組件，提供具有設計感的歡迎畫面。 |
| [`lib/pages/widgets/loading_indicator_widget.dart`](../../lib/pages/widgets/loading_indicator_widget.dart) | `LoadingIndicatorWidget` | 正在等待 AI 最早一個 Token 回應時的打字動畫指示器。 |

### 5. 基礎設施與工具 (`lib/services/` 與 `lib/features/`)

| 檔案路徑 | 關鍵類別/方法 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/services/export_service.dart`](../../lib/services/export_service.dart) | `ExportService` | 提供將對話紀錄匯出分享的功能（如複製到剪貼簿或分享 Markdown）。 |
| [`lib/features/utils/...`](../../lib/features/utils/) | - | 封裝專案中通用的工具函式庫。 |
| [`lib/features/foundation/...`](../../lib/features/foundation/) | - | 基礎性擴充功能。 |
