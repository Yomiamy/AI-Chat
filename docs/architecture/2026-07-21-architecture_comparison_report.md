# AI-Chat 架構與代碼風格對比報告 (更新於 2026-07-21)

本報告參考了通用的 Flutter 專案架構與「Linus 模式」的工程準則，對比當前 `AI-Chat` 的 `lib` 目錄，旨在評估其代碼品味、職責拆分、命名慣例，並記錄已落地的架構實作與核心設計權衡。

---

## 🐧 核心審查與品味評級 (Linus' Taste Rating)

### 🟢 好的部分 (Good Taste)
* **資料與表現分離 (Clean Architecture)**：`GeminiApiBloc` 完美隔離了複雜的串流（Streaming）狀態與視圖（UI）。`AiChatView` 完全不需要知道底層是如何透過 `Stream` 將字元一個個吐出，它只負責將 `GeminiApiState` 渲染到畫面上。
* **無縫的本地持久化**：歷史訊息的 JSON 序列化與反序列化操作，全數收斂於 `ChatRepositoryImpl` 之中，且進行了嚴謹的 `try-catch` 防護。即使遇到結構不相容的舊資料，也會安全地降級並重置，貫徹「Never break userspace (絕不破壞用戶空間)」的理念。
* **統一注入與依賴反轉**：透過 `di/injection.dart` 配置 `get_it`，所有依賴項在啟動時即準備就緒。需要調用 Repository 的 Bloc 可以藉由依賴注入解耦，使得未來替換資料庫或切換 AI 服務提供商時，成本降至最低。

### 🔴 已解決的壞品味與平庸部分 (Resolved Bad Taste & Flaws)
* **臃腫的 Page 視圖 (God Widget) 解耦**：早期的 Flutter 開發容易將所有佈局與輸入框堆疊在單一的 `AiChatPage`。本專案將元件徹底拆分為 `AiChatView`（對話列表）、`InputAreaWidget`（輸入控制）與 `MessageBubbleWidget`（單則訊息渲染），將單一檔案的複雜度與巢狀縮排層級大幅降低，實踐了「超過三層縮排就重寫」的準則。
* **寫死的樣式 (Hardcoded Styles)**：UI 的配色與間距將逐步收斂至集中的佈景主題管理，而非散落於程式碼之中，這讓未來實作 Dark Mode 變得輕而易舉。

---

## 🔍 架構與職責對比分析

### 1. 專案結構 (Structure)

| 維度 | 傳統 MVC / 麵條式架構 | 當前專案 (AI-Chat) |
| :--- | :--- | :--- |
| **架構模式** | **耦合架構** | **Feature-First Clean Architecture** |
| **層級隔離** | UI 直接持有業務狀態與 API 呼叫 | `Presentation` $\rightarrow$ `BLoC` $\rightarrow$ `Repository` $\rightarrow$ `Data Source`。嚴格單向。 |
| **實體隔離** | 混用 UI 狀態物件與資料庫物件 | `ChatMessage` 作為統一的 Domain Entity，清晰界定邊界。 |

> **Linus 實用主義評註**：為了打造流暢的串流對話體驗，引入 BLoC 是有價值的。但我們避免了過度工程：沒有引入不必要的 UseCase 層，讓 BLoC 直接與 Repository 溝通，在實用與嚴謹之間取得了完美的「好品味」平衡。

### 2. 狀態管理與職責 (State Management)

* 串流的累加（字串拼接）是此專案中運算最頻繁的操作。我們選擇將這段邏輯放置於 BLoC 中而非 UI，這確保了 UI 重繪（Rebuild）時僅僅是反映資料變化，而不會重複執行無意義的字串運算。
* **防護性設計**：`GeminiApiError` 狀態統一了網路失敗、超時或 API 金鑰失效的錯誤。UI 只需對此狀態作出一元化的視覺回饋。

---

## ⚖️ 架構權衡與折衷 (Architectural Trade-offs)

### 持久化儲存：Shared Preferences vs Local Database (SQLite)
* **現狀**：採用 `shared_preferences` 將整個對話陣列序列化為 JSON 字串儲存。
* **優點**：實作極其簡單，對於單一 Session、少數訊息的場景，讀寫效能已非常足夠（符合 YAGNI 原則）。
* **缺點**：未來若要擴展「多個對話工作區 (Multiple Sessions)」，每次新增訊息都需要讀寫龐大的 JSON 字串，效能將會雪崩。
* **決策**：在當前需求下，簡單的 JSON 快取是最佳解。當確立要實作多對話管理時，應重構 `ChatRepositoryImpl`，無縫切換為 `sqflite` 或 `Isar`，而上層 BLoC 與 UI 無需更改。
