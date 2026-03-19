# Code Review Style Guide

## Language / 語言

- All code review comments must be written in **Traditional Chinese (繁體中文)**.
- 所有 code review 說明、建議、問題描述一律使用**繁體中文**撰寫。

## Code Style / 程式碼風格

- Follow Flutter/Dart official style guide.
- Use `const` wherever possible to improve performance.
- Prefer `S.of(context)` over `S.current` for localization to ensure proper widget rebuilds on locale change.
- All user-facing strings must use i18n keys from `lib/generated/l10n.dart`, no hardcoded strings.

## Architecture / 架構

- Use BLoC pattern for state management.
- Keep business logic out of widgets.
- Widgets should only handle UI rendering.

## Pull Request Review Focus / PR Review 重點

請在 review 時特別注意以下項目：

1. **國際化 (i18n)**：是否有使用 `S.of(context)` 而非 `S.current`？是否有遺漏未翻譯的字串？
2. **Null Safety**：是否正確處理可能為 null 的值？
3. **Context 生命週期**：使用 `context` 前是否有檢查 `context.mounted`？
4. **資源釋放**：Controller、Stream 等是否在 `dispose()` 中正確釋放？
5. **Const 優化**：能加 `const` 的地方是否都加了？
