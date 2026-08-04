import Foundation

/// ISBN 查詢來源。
enum ApiSource: String, CaseIterable, Identifiable {
    case googleBooks = "googleBooks"
    case openLibrary = "openLibrary"
    case wikipedia = "wikipedia"
    case jikeFree = "jikeFree"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .googleBooks: return "Google Books"
        case .openLibrary: return "Open Library"
        case .wikipedia: return "Wikipedia"
        case .jikeFree: return "Jike Free"
        }
    }

    var enabledByDefault: Bool {
        switch self {
        case .googleBooks, .openLibrary: return true
        case .wikipedia, .jikeFree: return false
        }
    }

    var requiresKey: Bool {
        switch self {
        case .googleBooks, .jikeFree: return true
        case .openLibrary, .wikipedia: return false
        }
    }

    /// 使用者填入 API key 的儲存鍵（若需要 key）。nil 表示不需 key。
    var keyStorageKey: String? {
        switch self {
        case .googleBooks: return "google_books_api_key"
        case .jikeFree: return "jike_api_key"
        default: return nil
        }
    }

    var baseUrl: String {
        switch self {
        case .googleBooks: return "https://www.googleapis.com/books/v1/volumes?q=isbn="
        case .openLibrary: return "https://openlibrary.org/api/books?bibkeys=ISBN:"
        case .wikipedia: return "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch="
        case .jikeFree: return "https://api.jike.xyz/situ/book/isbn/"
        }
    }

    /// 本地化名稱。
    func localizedName(_ s: Strings) -> String {
        switch self {
        case .googleBooks: return s.t("settings_google_title")
        case .openLibrary: return s.t("settings_openlibrary_title")
        case .wikipedia: return s.t("settings_wikipedia_title")
        case .jikeFree: return s.t("settings_jike_title")
        }
    }

    /// 本地化描述。
    func localizedDescription(_ s: Strings) -> String {
        switch self {
        case .googleBooks: return s.t("settings_google_subtitle")
        case .openLibrary: return s.t("settings_openlibrary_subtitle")
        case .wikipedia: return s.t("settings_wikipedia_subtitle")
        case .jikeFree: return s.t("settings_jike_subtitle")
        }
    }

    static var all: [ApiSource] { ApiSource.allCases }
    static func defaultEnabled() -> [ApiSource] { allCases.filter { $0.enabledByDefault } }
    static func fromId(_ raw: String) -> ApiSource? {
        ApiSource(rawValue: raw)
    }
}
