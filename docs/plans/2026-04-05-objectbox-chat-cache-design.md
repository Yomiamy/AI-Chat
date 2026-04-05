# ObjectBox Chat History Cache Design

## 目標

將目前存在記憶體的對話歷史（`_chatList`）透過 ObjectBox 持久化，使對話在 app 重開或 BLoC 重建後仍可還原，同時保持上限 100 筆、圖片內容不落地。

---

## 資料模型

```dart
@Entity()
class ChatMessage {
  @Id()
  int id = 0;

  String content;   // 訊息本文（圖片已替換為佔位符）
  int timestamp;    // Unix ms，用於排序與裁切
  String role;      // "prompt" | "ai_reply" | "error"
}
```

### Role 對應

| role | 原 _chatList 前綴 |
|------|------------------|
| `prompt` | `Prompt: ...` |
| `ai_reply` | `AI reply: ...` |
| `error` | `Error: ...` |

---

## 架構

```
GeminiApiBloc
  └─ ChatRepository          // 封裝 ObjectBox 讀寫，BLoC 唯一依賴
       └─ Box<ChatMessage>   // ObjectBox 底層
```

`Store` 在 `main.dart` 初始化，透過 `RepositoryProvider` 注入 BLoC。

---

## 資料流

### 初始化（`_init`）

1. `ChatRepository.loadMessages()` 從 ObjectBox 依 timestamp 降序讀出最多 100 筆
2. 轉換為 `List<String>`（還原前綴格式）賦給 `_chatList`
3. UI 無需改動

### 查詢（`_query`）

```
使用者送出
  → saveMessage(role: "prompt",   content: _stripBase64(userMessage))
stream 結束（Status.success）
  → saveMessage(role: "ai_reply", content: _stripInlineImage(aiReply))
catch
  → saveMessage(role: "error",    content: e.toString())
```

附件相關事件（`_pickFile`、`_pickImage`、`_removeFile`）**不觸碰 ObjectBox**。

---

## Base64 過濾規則

| 來源 | 替換規則 |
|------|---------|
| 使用者訊息中的圖片 | `![...](data:image/...;base64,...)` → `[附件: {mimeType}, 大小: {size} MB]`（size 從 base64 長度反推：`length × 3 / 4`） |
| AI 回覆中的 inline image | 同上模式 → `[圖片回覆]` |

---

## 上限策略

- 每次 `saveMessage` 後查詢總筆數
- 超過 100 筆：刪除 timestamp 最小（最舊）的 1 筆
- 每次只刪 1 筆，overhead 極小

---

## 不在此次範圍內（YAGNI）

- 多對話 session（新建 / 切換歷史）
- 附件 bytes 本地化儲存
- 對話搜尋 / 匯出
