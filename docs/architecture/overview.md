# AI-Chat (Gemini AI Assistant) - 整體架構概覽 (Overview)

> 「好品味就是消滅邊界條件，用最簡單的資料結構解決最核心的問題。」 —— 借鑒 Linus Torvalds 的思維

AI-Chat 是一個整合 Google Gemini 模型的現代化 Flutter AI 聊天應用程式。本專案以實用主義為核心，確保流暢的「Streaming (串流)」對話體驗，並採用「功能優先 (Feature-First)」與 Clean Architecture 分層原則。

---

## 🏗️ 核心架構分層

本應用將整體架構劃分為三個主要層次：表現層 (Presentation Layer)、狀態控制層 (Business Logic / BLoC Layer) 與資料層 (Data Layer)。

```text
  ┌────────────────────────────────────────────────────────────┐
  │                 表現層 (Presentation Layer)                │
  │  [AiChatPage]    [AiChatView]    [InputAreaWidget]         │
  │  [MessageBubbleWidget]  [EmptyWidget]                      │
  └─────────────────────────────┬──────────────────────────────┘
                                │ 觸發事件 (Events) / 訂閱狀態 (States)
                                ▼
  ┌────────────────────────────────────────────────────────────┐
  │                 狀態控制層 (Business Logic)                │
  │                      [GeminiApiBloc]                       │
  │ (處理 GeminiSendMessage, GeminiClearChat, GeminiLoadChat)  │
  └─────────────────────────────┬──────────────────────────────┘
                                │ 依賴注入 (get_it)
                                ▼
  ┌────────────────────────────────────────────────────────────┐
  │                   資料擷取與領域模型層                     │
  │                     [ChatRepository]                       │
  │           [ChatMessage] (Domain Entity / Model)            │
  └─────────────────────────────┬──────────────────────────────┘
                                │ API 呼叫與本地快取
                                ▼
  ┌────────────────────────────────────────────────────────────┐
  │                   外部服務 (External API)                  │
  │    [firebase_ai (Gemini)]         [shared_preferences]     │
  └────────────────────────────────────────────────────────────┘
```

### 1. 表現層 (Presentation Layer)
- 遵循「UI 純淨原則」，`build` 方法僅用來聲明佈局，無業務邏輯。
- **`AiChatPage`**：應用的主入口與框架，負責 Scaffold 佈局與 AppBar 設置。
- **`AiChatView`**：核心對話列表元件，負責監聽 `GeminiApiBloc` 狀態，處理自動滾動 (Auto-scrolling) 與渲染 `MessageBubbleWidget`。
- **`InputAreaWidget`**：響應式輸入框組件，支援實體鍵盤 (Enter 傳送，Shift+Enter 換行)，與送出事件綁定。

### 2. 狀態控制層 (Business Logic)
- 採用 **BLoC** (Business Logic Component) 模式，落實單向數據流。
- **`GeminiApiBloc`**：
  - 專注於管理 Gemini AI 的對話生命週期。
  - 核心狀態包括：初始狀態、讀取狀態、Streaming (串流生成中) 狀態與錯誤狀態。
  - 將 UI 的送出意圖轉換為對 `ChatRepository` 的呼叫，並將串流回傳的 Token 即時拼接（累加）後發送給 UI，以實現平滑的打字機效果。

### 3. 資料與領域模型層 (Data Layer)
- **`ChatMessage`**：不可變 (Immutable) 的核心領域模型，定義了一則訊息的 `role` (user/model)、`text` (內容)、與 `timestamp`。
- **`ChatRepository` (抽象介面)** 與 **`ChatRepositoryImpl`**：
  - 將底層 `firebase_ai` 的實作細節與 BLoC 隔離。
  - 處理對話紀錄的本地持久化 (`shared_preferences`) 與讀取。
  - 封裝與 Gemini API 的串流連接邏輯。

### 4. 基礎設施與注入 (DI / Core)
- **Dependency Injection (`di/injection.dart`)**：使用 `get_it` 提供 `ChatRepository` 與 `GeminiApiBloc` 的全域實例管理，達到解耦目的。
- **國際化 (l10n)**：使用 Flutter 內建的 `.arb` 檔案達成多語系支持（英、繁中）。

---

## 🛠️ 架構設計原則與「好品味」

### 1. 串流處理的極簡主義
處理 AI 生成的 Streaming 文本時，`GeminiApiBloc` 不維護複雜的中間緩衝區。它直接接收 `ChatRepository` 吐出的串流片段 (chunk)，進行字串相加，並透過 `emit` 刷新最新狀態。這種無條件分支的就地更新，使得記憶體使用率穩定，且完全消除了邊界拼湊的問題。

### 2. UI/邏輯絕對隔離
`InputAreaWidget` 不包含任何與 Gemini 相關的網路請求與錯誤捕捉，僅僅透過 `context.read<GeminiApiBloc>().add(...)` 派發事件。這樣當底層從 Gemini Flash 換成其他模型時，UI 元件不需要更動哪怕一行程式碼。

### 3. 資料庫的容錯處理
歷史訊息採用輕量級的 JSON 序列化存入 `shared_preferences`。在啟動時若發現資料損毀或反序列化失敗，會靜默清空並重新開始，嚴格遵守「Never break userspace (不讓用戶遇到崩潰白屏)」的鐵律，確保了核心業務（AI 對話）的順暢進行。
