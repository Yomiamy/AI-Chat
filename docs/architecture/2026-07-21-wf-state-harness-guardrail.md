# wf-state.sh: Execution Harness 與 Guardrail 機制解析

> **核心信條**：把 LLM 當成一台不受控、隨時可能暴衝的引擎。單靠 Markdown 提示詞去約束 LLM 就像用「道德勸說」在管教程式碼；我們必須在底層實作「硬體級別的防呆機制」。

在 AI-Chat 專案的 `gen-dev-workflow` 開發流程中，`wf-state.sh` 擔任了專屬狀態機 (State Machine) 的守門員，並且是狀態檔 (State JSON) 的**唯一存取入口**。

---

## 1. Harness 機制（基礎執行設施）

Harness 的目標是**抹平底層系統複雜度**，讓 LLM 不需要親自處理檔案競爭、型別轉換或 JSON 序列化，只要呼叫標準 API 即可。

* **單一掛載點**：隱藏繁瑣的 Shell 指令，提供 `init`, `promote`, `get`, `set`, `advance` 介面，讓自動化有穩定的軌道。
* **原子寫入 (Atomic Write)**：資料強制寫入暫存檔，確認解析成功且內容合法後才用 `mv` 覆蓋原檔。如果系統中途當機，磁碟絕不會留下寫壞的 JSON。
* **型別安全轉換**：處理 Bash 傳遞至 JSON 時的布林值與字串型別問題，避免格式損毀。

---

## 2. Guardrail 機制（邊界防護與斷路器）

Guardrail 是防範 LLM 越權的最強防護欄。一旦發現不對勁，立刻 `exit 1` 讓流程當機，**絕對拒絕靜默失敗 (Silent Failure)**。

### 2.1 強制暫停棘輪 (Pause Point Ratchet)
在完成 `stage-done` 或 `task-done` 後，狀態檔會自動鎖定為 `awaiting_confirmation=true`。如果 LLM 試圖在未經使用者同意下推進流程 (`advance`)，且未帶上 `--confirmed` 旗標，腳本將無情報錯。這強迫 LLM 必須停下來等待人類指令。

### 2.2 寫死狀態機轉移表
對於 `sequence` 模式，合法路徑已寫死（`0a→0b→1→2→3→4→done`）。任何試圖跳關的行為都會被視為非法轉移並遭到攔截。

### 2.3 寫入白名單
腳本明確限制了 `set` 指令可以修改的欄位（如 `spec`, `plan`, `branch`, `total_tasks`）。不允許透過 `set` 竄改階段（stage）或確認鎖，只能循正規管道 `advance` 推進。

### 2.4 Schema 與完整性驗證
每次讀寫強制透過 `jq -e` 檢查 Schema 與型別，並且在進入下一階段前，嚴格核對 `completed_tasks` 與 `total_tasks` 是否吻合。

---

## 總結

* **Harness** 提供了一套標準方向盤，讓 LLM 得以平穩驅動專案開發。
* **Guardrail** 是一套無法被繞過的斷路器系統，將規範寫入底層腳本並以 `exit 1` 來保證系統的正確性與邊界安全。
