import SwiftUI

/// 支援的應用語言。`system` 代表跟隨裝置設定，可在設定頁動態切換。
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case traditionalChinese = "zh-Hant"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    /// 設定頁顯示名稱（以該語言自身顯示）。
    var displayName: String {
        switch self {
        case .system: return "System (跟隨系統)"
        case .english: return "English"
        case .traditionalChinese: return "繁體中文"
        case .simplifiedChinese: return "简体中文"
        }
    }
}

/// 語言管理員：負責持久化使用者選擇，並解析「有效語言」。
final class LocaleManager: ObservableObject {
    static let shared = LocaleManager()
    @Published var language: AppLanguage = .system
    private let key = "app_language"

    private init() {
        let stored = UserDefaults.standard.string(forKey: key)
        language = AppLanguage(rawValue: stored ?? "") ?? .system
    }

    func set(_ lang: AppLanguage) {
        language = lang
        UserDefaults.standard.set(lang.rawValue, forKey: key)
    }

    /// 依使用者設定與裝置 locale 解析出實際使用語言。
    var effectiveLanguage: AppLanguage {
        if language != .system { return language }
        let code = Locale.current.languageCode ?? "en"
        if code.hasPrefix("zh") {
            let id = Locale.current.identifier.lowercased()
            if id.contains("hans") || id.contains("zh-cn") || id.contains("zh-sg") {
                return .simplifiedChinese
            }
            return .traditionalChinese
        }
        return .english
    }

    var strings: Strings { Strings(language: effectiveLanguage) }
}

/// 本地化字串庫。使用 `t(key)` 取得字串，`t(key, args)` 帶參數。
struct Strings {
    let language: AppLanguage

    private var table: [String: String] {
        switch language {
        case .english: return Strings.enTable
        case .traditionalChinese: return Strings.zhHantTable
        case .simplifiedChinese: return Strings.zhHansTable
        case .system: return Strings.enTable
        }
    }

    func t(_ key: String, _ args: [String: String] = [:]) -> String {
        let value = table[key] ?? key
        var result = value
        for (k, v) in args {
            result = result.replacingOccurrences(of: "{\(k)}", with: v)
        }
        return result
    }

    // MARK: - 帶參數的常用字串

    func lexileLabel(_ score: Int) -> String {
        t("lexile_label", ["score": String(score)])
    }
    func statsReadingLabel(_ count: Int) -> String {
        t("stats_reading_label", ["count": String(count)])
    }
    func statsUnreadLabel(_ count: Int) -> String {
        t("stats_unread_label", ["count": String(count)])
    }
    func settingsEnabledSources(_ enabled: Int, _ total: Int) -> String {
        t("settings_enabled_sources", ["enabled": String(enabled), "total": String(total)])
    }
    func freeLimitReached(_ limit: Int) -> String {
        t("free_limit_reached", ["limit": String(limit)])
    }
    func paywallSubtitle(_ limit: Int) -> String {
        t("paywall_subtitle", ["limit": String(limit)])
    }
    func paywallBuy(_ price: String) -> String {
        t("paywall_buy", ["price": price])
    }
    func settingsUnlockSubtitle(_ limit: Int) -> String {
        t("settings_unlock_subtitle", ["limit": String(limit)])
    }
    func sourceLabel(_ value: String) -> String {
        t("source_label", ["value": value])
    }
    func cannotFindIsbn(_ url: String) -> String {
        t("cannot_find_isbn_ncl", ["url": url])
    }
    func queryFailed(_ error: String) -> String {
        t("query_failed_error", ["error": error])
    }
    func errorPrefix(_ message: String) -> String {
        t("error_prefix", ["message": message])
    }
    func lexileRefilled(_ value: Int) -> String {
        t("lexile_refilled", ["value": String(value)])
    }
    func photoFailed(_ error: String) -> String {
        t("photo_failed", ["error": error])
    }
    func loadBooksFailed(_ error: String) -> String {
        t("load_books_failed", ["error": error])
    }
    func addBookFailed(_ error: String) -> String {
        t("add_book_failed", ["error": error])
    }
    func updateBookFailed(_ error: String) -> String {
        t("update_book_failed", ["error": error])
    }
    func deleteBookFailed(_ error: String) -> String {
        t("delete_book_failed", ["error": error])
    }
    func recordSaleFailed(_ error: String) -> String {
        t("provider_book_record_sale_failed", ["error": error])
    }
    func languageLabel(_ value: String) -> String {
        t("language_label", ["value": value])
    }
    func searchFailed(_ error: String) -> String {
        t("search_failed", ["error": error])
    }

    // MARK: - 動態多國語設定（新增）
    var settingsLanguageTitle: String { t("settings_language_title") }
    var languageSectionTitle: String { t("language_section_title") }
}
