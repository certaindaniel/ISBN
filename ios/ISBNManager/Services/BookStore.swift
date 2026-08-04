import Foundation
import SwiftUI

/// 全域書籍狀態，對應 Flutter 的 BookProvider。
@MainActor
final class BookStore: ObservableObject {
    @Published var books: [Book] = []
    @Published var statistics = Database.Statistics()
    @Published var isLoading = false
    @Published var error: String?
    @Published var errorCode: String?
    @Published var errorArgs: [String: String]?

    private let db = Database.shared

    func loadBooks() async {
        isLoading = true
        error = nil; errorCode = nil; errorArgs = nil
        books = db.getAllBooks()
        isLoading = false
    }

    func loadStatistics() async {
        statistics = db.getStatistics()
    }

    func refresh() async {
        await loadBooks()
        await loadStatistics()
    }

    func clearError() {
        error = nil; errorCode = nil; errorArgs = nil
    }

    /// 依 ISBN 查詢書籍資訊，支援多來源與進度回報。
    func searchBookByIsbn(_ isbn: String, sources: [ApiSource],
                          onSourceStart: ((ApiSource) -> Void)? = nil) async -> Book? {
        isLoading = true
        error = nil; errorCode = nil; errorArgs = nil
        let normalized = ISBNService.normalizeIsbn(isbn)
        if let local = db.getBookByISBN(normalized) {
            error = "此 ISBN 已存在於資料庫"
            errorCode = "isbn_already_exists"
            isLoading = false
            return local
        }
        let active = sources.isEmpty ? ApiSource.defaultEnabled() : sources
        do {
            let book = try await ISBNService.searchByIsbn(normalized, sources: active, onSourceStart: onSourceStart)
            if book == nil {
                let isZh = LocaleManager.shared.effectiveLanguage != .english
                let fallbackURL = isZh ? "https://isbn.ncl.edu.tw/NEW_ISBNNet/main_DisplayResults.php?Pact=DisplayAll4Simple&isbn=\(normalized)" : "https://openlibrary.org/isbn/\(normalized)"
                error = "無法查詢到此 ISBN 的書籍資訊，可前往查詢：\(fallbackURL)"
                errorCode = "cannot_find_isbn_ncl"
                errorArgs = ["url": fallbackURL]
            }
            isLoading = false
            return book
        } catch let err as IsbnError {
            error = err.message
            errorCode = err.code
            isLoading = false
            return nil
        } catch let caught {
            error = "查詢失敗: \(caught)"
            errorCode = "query_failed_error"
            errorArgs = ["error": String(describing: caught)]
            isLoading = false
            return nil
        }
    }

    @discardableResult
    func addBook(_ book: Book) async -> Bool {
        isLoading = true
        error = nil; errorCode = nil; errorArgs = nil
        let normalized = ISBNService.normalizeIsbn(book.isbn)
        guard ISBNService.isValidIsbn(normalized) else {
            error = "無效的 ISBN 格式"
            errorCode = "isbn_error_invalid_format"
            isLoading = false
            return false
        }
        var toSave = book
        toSave.isbn = normalized
        if !PurchaseService.shared.isUnlocked && books.count >= PurchaseService.freeBookLimit {
            error = "已達免費版書籍上限"
            errorCode = "free_limit_reached"
            isLoading = false
            return false
        }
        if db.getBookByISBN(normalized) != nil {
            error = "ISBN 已存在於資料庫"
            errorCode = "isbn_already_exists"
            isLoading = false
            return false
        }
        db.insertBook(toSave)
        await refresh()
        Task { await ReviewService.recordSuccess() }
        isLoading = false
        return true
    }

    @discardableResult
    func updateBook(_ book: Book) async -> Bool {
        isLoading = true
        error = nil; errorCode = nil; errorArgs = nil
        let normalized = ISBNService.normalizeIsbn(book.isbn)
        guard ISBNService.isValidIsbn(normalized) else {
            error = "無效的 ISBN 格式"
            errorCode = "isbn_error_invalid_format"
            isLoading = false
            return false
        }
        var toSave = book
        toSave.isbn = normalized
        db.updateBook(toSave)
        if toSave.status == "read" {
            db.recordReading()
        }
        await refresh()
        isLoading = false
        return true
    }

    @discardableResult
    func deleteBook(id: Int) async -> Bool {
        isLoading = true
        error = nil; errorCode = nil; errorArgs = nil
        db.deleteBook(id: id)
        await refresh()
        isLoading = false
        return true
    }

    @discardableResult
    func markAsSold(_ book: Book, salePrice: Double) async -> Bool {
        var updated = book
        updated.salePrice = salePrice
        updated.saleDate = Date()
        updated.status = "read"
        return await updateBook(updated)
    }

    func localizedError(_ s: Strings) -> String {
        switch errorCode {
        case "scan_not_isbn_ean": return s.t("scan_not_isbn_ean")
        case "provider_book_record_sale_failed": return s.recordSaleFailed(errorArgs?["error"] ?? "")
        case "isbn_error_invalid_format": return s.t("isbn_error_invalid_format")
        case "isbn_already_exists": return s.t("isbn_already_exists")
        case "free_limit_reached": return s.freeLimitReached(PurchaseService.freeBookLimit)
        case "cannot_find_isbn_ncl": return s.cannotFindIsbn(errorArgs?["url"] ?? "")
        case "load_books_failed": return s.loadBooksFailed(errorArgs?["error"] ?? "")
        case "add_book_failed": return s.addBookFailed(errorArgs?["error"] ?? "")
        case "update_book_failed": return s.updateBookFailed(errorArgs?["error"] ?? "")
        case "delete_book_failed": return s.deleteBookFailed(errorArgs?["error"] ?? "")
        case "query_failed_error": return s.queryFailed(errorArgs?["error"] ?? "")
        default: return error ?? ""
        }
    }
}
