# Service/Provider Strings: Localization TODO

掃描範圍：`lib/services`、`lib/providers`。此清單列出發現的疑似使用者可見訊息（中文或需本地化的英文），並建議 ARB key 與處理建議。

---

1) File: `lib/services/isbn_service.dart`
- Line: ~26
- Source: `throw Exception('請掃描 ISBN 條碼，這個是 EAN');`
- Suggested ARB key: `isbn.error.ean`
- Suggested value (en/zh_TW/zh_CN):
  - en: "Please scan an ISBN barcode — this looks like an EAN"
  - zh_TW: "請掃描 ISBN 條碼，這個是 EAN"
  - zh_CN: "请扫描 ISBN 条码，这是 EAN"
- Notes: This is thrown from a low-level service. Options:
  - a) Throw a typed exception (e.g., `IsbnException.code('ean')`) and map to localized message in UI layer.
  - b) Keep throwing with message but ensure callers (UI) present localized text (not ideal).

2) File: `lib/services/isbn_service.dart`
- Line: ~28
- Source: `throw Exception('無效的 ISBN 格式');`
- Suggested ARB key: `isbn.error.invalid_format`
- Suggested value:
  - en: "Invalid ISBN format"
  - zh_TW: "無效的 ISBN 格式"
  - zh_CN: "无效的 ISBN 格式"
- Notes: Same handling options as above. Prefer throwing a code and localizing in UI.

3) File: `lib/providers/book_provider.dart`
- Line: ~203
- Source: `_error = '記錄售出失敗: $e';`
- Suggested ARB key: `provider.book.record_sale_failed`
- Suggested value (with placeholder):
  - en: "Failed to record sale: {error}"
  - zh_TW: "記錄售出失敗：{error}"
  - zh_CN: "记录售出失败：{error}"
- Notes: Provider holds `_error` likely shown in UI. Replace assignment with a localized message at the UI or have provider expose an `Error` object with code and message args.

---

Other findings (comments / SQL):
- `lib/services/database_helper.dart`: SQL update strings (not for localization).
- Inline comments in `isbn_service.dart` contain examples with double quotes — comments not for localization.

---

Recommended next steps:
1. Decide on exception strategy for services:
   - Prefer: services throw typed exceptions or return error codes; UI maps to localized strings.
2. Add ARB keys for the three items above and update UI/provider to use `AppLocalizations` or mapping.
3. Create a short PR that:
   - Adds ARB keys and translations
   - Replaces provider `_error` assignment with localized message (or structured error)
   - Adds unit tests for error mapping

如果你同意，我可以：
- 幫你新增以上 ARB key（en/zh/zh_TW）與範例翻譯，並示範如何在 provider 或 UI 層取得本地化訊息；或
- 我先將服務層改為回傳錯誤代碼/typed exception，再著手在 UI 層做本地化映射。

請告訴我你偏好的處理策略。