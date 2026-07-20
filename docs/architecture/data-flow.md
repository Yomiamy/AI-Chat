# AI-Chat (Gemini AI Assistant) - 數據流與功能流程 (Data Flow)

> 「資料流向哪裡？誰擁有它？誰修改它？理清這些，複雜度自然消失。」

本文件追蹤 AI-Chat 中最核心的對話數據流，從使用者按下送出按鈕，到 Gemini 模型回傳 Streaming 資料，最終更新於螢幕上的完整軌跡。

---

## 1. 核心對話資料流 (The Chat Data Flow)

本應用最複雜也最核心的操作為：發送訊息與即時串流顯示回應 (Real-time Streaming)。採用單向數據流 (Unidirectional Data Flow) 設計。

### 數據流時序圖

```text
  [ 用戶 UI ]                  [ BLoC 層 ]                   [ 資料層 (Repository) ]          [ 外部 API ]
 InputAreaWidget             GeminiApiBloc                 ChatRepositoryImpl            firebase_ai (Gemini)
       │                           │                                │                             │
       │── 1. 輸入文字 + 點擊送出 ──>│                                │                             │
       │   (發送 GeminiSendMessage)│                                │                             │
       │                           │── 2. 更新 State (加 User Msg)  │                             │
       │<── 3. UI 渲染 User Msg ───│                                │                             │
       │                           │                                │                             │
       │                           │── 4. 呼叫 sendMessageStream ──>│                             │
       │                           │                                │── 5. 打開 API Stream ──────>│
       │                           │                                │                             │
       ~                           ~                                ~   (等待網路回應)             ~
       │                           │                                │                             │
       │                           │                                │<── 6. chunk 1 (文字片段) ───│
       │                           │<── 7. yield 轉發 chunk 1 ──────│                             │
       │                           │── 8. 累加文字並 emit 新 State ─│                             │
       │<── 9. UI 渲染打字機效果 ──│                                │                             │
       │                           │                                │                             │
       │                           │                                │<── 10. chunk 2 (文字片段) ──│
       │                           │<── 11. yield 轉發 chunk 2 ─────│                             │
       │                           │── 12. 累加文字並 emit 新 State │                             │
       │<── 13. UI 渲染更新 ───────│                                │                             │
       │                           │                                │                             │
       ~                           ~                                ~                             ~
       │                           │                                │<── 14. Stream 結束 (Done) ──│
       │                           │── 15. 將最終完整訊息持久化 ──> │                             │
       │                           │       (儲存至快取)             │                             │
       │                           │── 16. emit 完成狀態 (Success)  │                             │
```

### 關鍵狀態變化 (State Transitions)

在上述流程中，`GeminiApiState` 的轉移如下：

1. **`GeminiApiSuccess` (待機)**：接收到使用者的新事件。
2. **`GeminiApiLoading`**：發出請求前，向對話列表中推入一則使用者訊息，以及一則空的 AI 訊息作為佔位符 (Placeholder)，觸發 UI 顯示 Loading 或準備滾動。
3. **`GeminiApiStreaming` (頻繁觸發)**：每當底層傳來一個 Token/Chunk，BLoC 就將新的字串疊加在佔位符 AI 訊息上，並 emit 這個狀態。這觸發 `AiChatView` 內的 `MessageBubbleWidget` 即時重繪 Markdown 內容。
4. **`GeminiApiSuccess` (結束)**：串流關閉後，回到待機狀態。
5. **`GeminiApiError` (例外)**：過程中發生網路斷線或 API 拒絕，將錯誤內容寫入 AI 訊息佔位符中或展示提示。

---

## 2. 歷史訊息快取與載入流程 (Session Persistence Flow)

為了保證用戶體驗，重啟 App 時應當保留先前的對話。

```text
  [ 啟動 App ]                 [ BLoC 初始化 ]                [ 資料層 (Repository) ]
  main.dart                  GeminiApiBloc                 ChatRepositoryImpl
       │                           │                                │
       │── 1. DI 注入與 Bloc 建立 ─>│                                │
       │                           │── 2. add(GeminiLoadChat) ──────│
       │                           │                                │
       │                           │── 3. loadMessages() ──────────>│
       │                           │                                │── 4. 讀取 shared_preferences
       │                           │                                │── 5. 反序列化 JSON 到 ChatMessage
       │                           │<── 6. 回傳 List<ChatMessage> ──│
       │                           │                                │
       │                           │── 7. emit(GeminiApiSuccess)    │
       │<── 8. UI 繪製歷史對話 ────│                                │
```

### 容錯與狀態修復
- **反序列化失敗**：若 JSON 結構變更或資料損毀，`ChatRepositoryImpl` 內的 `try-catch` 會捕捉異常，並回傳空的 List，而不是讓 App 在啟動時崩潰。這實踐了「好品味」中對特殊與邊緣情況的安全降級。
