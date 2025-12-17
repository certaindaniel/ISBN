# AI 全域偏好與執行規範

本文件用於指引所有代理（AI/助理）在本專案的既定偏好與規範，請在開始任何工作前先閱讀並遵循。

## 語言與內容產出
- 預設語言：繁體中文（台灣用語）。
- 文件（README、CLAUDE.md、commit message 等）預設使用繁體中文。
- 程式碼本體保留原始語言；註解、說明與 docstring 一律使用繁體中文。
- 若使用英文回覆，請先以「請用英文」明確標示需求。
- 依政策不可公開代理的內部「思考過程」（chain-of-thought）。若需要說明，請提供可檢驗的結論、理由與步驟，而非內在思維內容。

## Python 開發環境
- 若需使用 Python：
  - 一律使用 `uv` 與專案私有虛擬環境 `.venv`。
  - 禁止使用系統 base 環境與裸 `pip` 操作，避免汙染環境。
  - 提供可複製的指令與最小化依賴安裝步驟（如 `uv venv`, `uv pip install -r requirements.txt`）。

## Git 與 Commit
- 自動產生的 Git commit messages / comments 一律使用繁體中文台灣用語。
- 提交前確保程式可成功 build，測試（若有）須通過再宣告完成。

## 文件與計劃
- 代理產生的永久或固定的 `implementation_plan.md*`、`task.md*`、`walkthrough.md*` 檔案，一律使用繁體中文台灣用語。
- 變更需最小且聚焦，避免不必要的重構與風格調整。

## 本地化（Localization）
- Swift Package 與 Xcode 皆須以 `L("key")` 進行多國語字串擷取（詳見 `QDir/QDir/Utilities/LocalizationHelper.swift`）。
- 翻譯檔案需置於：
  - `QDir/QDir/en.lproj/Localizable.strings`
  - `QDir/QDir/zh-Hant.lproj/Localizable.strings`
  - `QDir/QDir/zh-Hans.lproj/Localizable.strings`
- 命令列測試可透過 `LANG=zh_TW.UTF-8 swift run` / `LANG=zh_CN.UTF-8 swift run` 切換語言。

## 執行準則
- 先以最小可行步驟驗證，逐步擴充；提供必要的指令與後續建議。
- 回應保持精練、可操作、避免過度冗長；必要時提供簡短進度更新。

—
本文件存在於版本控制中，供所有代理與貢獻者查閱與遵循。