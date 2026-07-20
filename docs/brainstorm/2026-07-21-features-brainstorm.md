# AI-Chat 產品與架構演進腦力激盪 (Features & Workflow Brainstorm)

**日期**: 2026-07-21  
**目標**: 探討 AI-Chat 專案未來的擴展方向，在保持簡潔架構 (Linus 模式與好品味) 的前提下，引入高價值的現代化功能。

---

## 💡 潛在功能擴展 (Feature Ideas)

### 1. 多模態輸入支援 (Multimodal Input)
*   **需求痛點**: 使用者經常需要上傳圖片、螢幕截圖或文件讓 AI 分析。
*   **實作構想**:
    *   **資料結構變更**: `ChatMessage` 需擴展，不再僅含 `text`，可引入 `List<Attachment>`。
    *   **UI 調整**: `InputAreaWidget` 左側新增「回紋針」按鈕，呼叫 `image_picker`。
    *   **複雜度控制**: Firebase Gemini API 原生支援多模態。只要將選取的圖片轉換為 Base64 或 `Uint8List` 附加上去即可。這需要確保 Payload 輕量化，避免記憶體溢出 (OOM)。

### 2. 多對話工作區 (Chat Sessions / Workspaces)
*   **需求痛點**: 目前所有歷史紀錄都在同一個線性時序中，無法開啟「新對話」討論不同主題。
*   **實作構想**:
    *   **資料結構變更**: 引入 `ChatSession` 實體，包含 `sessionId`, `title`, `List<ChatMessage>`。
    *   **持久化設計**: `shared_preferences` 變為儲存 `List<String>` 的 sessionId，每個 sessionId 再對應一組詳細內容，或者升級為輕量本地資料庫 (如 `sqflite` 或 `Isar`)。
    *   **UI 調整**: 側邊欄 (Drawer) 顯示歷史對話列表。
    *   **架構決策**: 若引入本地資料庫，`ChatRepositoryImpl` 需大幅重構，但介面合約不變，能完美體現依賴注入的價值。

### 3. 對話分支與重試 (Regenerate / Branching)
*   **需求痛點**: AI 回答不好時，希望能針對特定回答點擊「重新生成」，或編輯原本的提示詞。
*   **實作構想**:
    *   將對話陣列結構重構為樹狀結構 (Tree Structure)，或簡單地在 UI 允許「截斷並重新發送」。
    *   **好品味原則**: 樹狀結構會讓狀態管理爆炸。最簡單的解法是「編輯並重發」，點擊舊訊息時，把該訊息以後的所有對話丟棄，重新生成。這維持了資料庫一維陣列的簡單性。

### 4. 系統提示詞設定 (System Prompt / Persona Configuration)
*   **需求痛點**: 希望 AI 扮演特定角色（如程式碼審查員、翻譯官）。
*   **實作構想**:
    *   在 AppBar 新增一個設定按鈕。
    *   設定頁面允許寫入一個 System Instruction，存入 `shared_preferences`。
    *   初始化 `firebase_ai` 的 `GenerativeModel` 時傳入該 instruction。這是一個低成本、高回報的功能。

---

## 🏗️ 內部工程與架構優化 (Technical Debt & Architecture)

### 1. 錯誤處理機制的強化
*   **現狀**: 目前網路錯誤可能僅在 ChatMessage 內加上錯誤提示。
*   **改進方向**: 實作統一的錯誤攔截器，在 `GeminiApiBloc` 中發出 `GeminiApiError` 時，利用 `ScaffoldMessenger` 顯示 Snackbar，同時允許一鍵重試 (Retry) 該請求。

### 2. Token 使用量觀測
*   **現狀**: 無法得知對話成本。
*   **改進方向**: 攔截 Gemini 的 Metadata，提取 Token 計數，並以微小字體顯示在 `MessageBubbleWidget` 底部。

## 結論與優先級

1.  **高優先級 (Low Effort, High Impact)**: 系統提示詞設定 (System Prompt) 與 錯誤 Snackbar 重試機制。不會破壞現有資料結構。
2.  **中優先級 (Medium Effort, High Impact)**: 多對話工作區 (Chat Sessions)。需要將底層儲存升級為本地資料庫，但這對於長期應用是必須的。
3.  **探索性 (High Effort)**: 多模態輸入。需要考量圖片壓縮、快取清理等繁雜邊界問題。應在上述基礎穩定後再行開發。
