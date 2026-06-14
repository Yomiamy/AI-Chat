---
name: gen-commit
description: Analyze unstaged/staged git changes, group files by functional relevance, and create multiple semantic unit commits. Use when the user says "commit", "gen-commit", "依功能 commit", "幫我 commit", "進行功能單元 commit", or any variant requesting intelligent grouping and committing of current changes. Also use when the user wants to commit changed files with meaningful, well-structured messages organized by feature area.
---

# gen-commit

分析當前 git 變更，依功能相關性將檔案分組，並執行多個語意化 commit——每個邏輯單元一個。

## 工作流程

### 1. 檢視變更

```bash
git status
git diff --stat
```

涵蓋 staged 與 unstaged 變更。也檢查屬於本次工作的 untracked 檔案。

### 2. 依功能單元分組檔案

逐一檢視每個檔案的 `git diff` 內容以理解變動了什麼，再叢集成數組，使得**同一組內所有檔案服務於相同的邏輯目的**。

**分組啟發法：**

| 組別類型 | 典型檔案樣態 |
|---|---|
| `feat` | 新功能檔案 + 其直接測試 |
| `refactor` | 跨相關檔案的風格/常數/命名變更 |
| `test` | 僅測試檔（當與實作解耦時） |
| `fix` | bug 修復檔，通常範圍狹窄 |
| `chore` | 設定、工具、Makefile、CI、lock 檔 |
| `build` / `ci` | build 腳本、pubspec、package.json、pipeline |
| `docs` | 僅文件的變更 |

**關鍵規則：** 一個 commit = 一個變更理由。若兩個檔案能用同一句話解釋，它們就該放在一起。

### 3. 排序 commit

依依賴順序提交——基礎性變更優先（例如：設定先於產生檔，常數先於使用它的 UI）。

### 4. 執行 commit

對每一組，只 stage 那些檔案並提交：

```bash
git add <file1> <file2> ...
git commit -m "$(cat <<'EOF'
<type>(<optional scope>): <short imperative summary>

<optional body explaining why, not what>
EOF
)"
```

**訊息規則：**
- 類型：`feat` / `fix` / `refactor` / `test` / `chore` / `build` / `ci` / `docs`
- 主旨行 ≤ 72 字元，祈使語氣（"add"、"fix"、"remove"——而非 "added"、"fixes"）
- 內文：解釋*為何*或*變更了什麼*，而非逐行摘要
- 不要附加任何署名 trailer（不要 `Co-Authored-By`、不要 `Generated with ...`）

### 5. 確認

所有 commit 完成後，執行 `git log --oneline -N`（N = 本次提交數），並向使用者展示結果。

## 邊界情況

- **Untracked 檔案**：若明顯屬於某個邏輯單元則納入；除非它正是 commit 的重點，否則跳過產生檔或二進位檔。
- **單一邏輯變更**：一個 commit 才正確——不要刻意拆分。
- **產生檔**（例如 `*.gen.dart`、`pubspec.lock`）：與觸發其產生的設定/原始碼放同一組，不要單獨分組。
- **分組曖昧時**：寧可少而廣的 commit，也不要多個難以理解的微 commit。
