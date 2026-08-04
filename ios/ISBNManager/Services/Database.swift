import Foundation
import SQLite3

/// SQLite 的 SQLITE_TRANSIENT 哨兵值（Swift 未直接暴露）。
private let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

/// SQLite 資料庫存取，欄位與 Flutter 版一致。
final class Database {
    static let shared = Database()
    private let dbPath: String
    private var db: OpaquePointer?

    /// 建立資料庫實例。測試時可傳入自訂路徑；正式使用時使用預設的 Documents/isbn_books.db。
    init(dbPath: String? = nil) {
        if let dbPath {
            self.dbPath = dbPath
        } else {
            let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
            self.dbPath = (docs as NSString).appendingPathComponent("isbn_books.db")
        }
        open()
        migrate()
    }

    deinit {
        if let db { sqlite3_close(db) }
    }

    private func open() {
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            print("SQLite open failed: \(dbPath)")
            db = nil
            return
        }
    }

    /// 檢查指定欄位是否存在於 books 表格，讓遷移可重複執行（idempotent）。
    private func columnExists(_ column: String) -> Bool {
        guard let db else { return false }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "PRAGMA table_info(books)", -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let ptr = sqlite3_column_text(stmt, 1), String(cString: ptr) == column {
                return true
            }
        }
        return false
    }

    private func migrate() {
        guard let db else { return }
        // 讀取現有版本
        var userVersion: Int32 = 0
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "PRAGMA user_version", -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                userVersion = sqlite3_column_int(stmt, 0)
            }
            sqlite3_finalize(stmt)
        }

        if userVersion < 1 {
            let sql = """
            CREATE TABLE IF NOT EXISTS books(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              isbn TEXT UNIQUE NOT NULL,
              title TEXT NOT NULL,
              author TEXT NOT NULL,
              publisher TEXT NOT NULL,
              coverUrl TEXT,
              description TEXT,
              purchasePrice REAL NOT NULL,
              salePrice REAL,
              purchaseDate TEXT NOT NULL,
              saleDate TEXT,
              startDate TEXT,
              finishDate TEXT,
              progress REAL,
              quantity INTEGER DEFAULT 1,
              status TEXT DEFAULT 'unread',
              language TEXT,
              lexileScore INTEGER,
              tags TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
            """
            sqlite3_exec(db, sql, nil, nil, nil)
        }
        if userVersion < 2 {
            if !columnExists("language") {
                sqlite3_exec(db, "ALTER TABLE books ADD COLUMN language TEXT", nil, nil, nil)
            }
            if !columnExists("lexileScore") {
                sqlite3_exec(db, "ALTER TABLE books ADD COLUMN lexileScore INTEGER", nil, nil, nil)
            }
        }
        if userVersion < 3 {
            sqlite3_exec(db, "UPDATE books SET status='unread' WHERE status IS NULL OR status='' OR status='owned'", nil, nil, nil)
            sqlite3_exec(db, "UPDATE books SET status='read' WHERE status='sold'", nil, nil, nil)
        }
        if userVersion < 4 {
            if !columnExists("startDate") {
                sqlite3_exec(db, "ALTER TABLE books ADD COLUMN startDate TEXT", nil, nil, nil)
            }
            if !columnExists("finishDate") {
                sqlite3_exec(db, "ALTER TABLE books ADD COLUMN finishDate TEXT", nil, nil, nil)
            }
            if !columnExists("progress") {
                sqlite3_exec(db, "ALTER TABLE books ADD COLUMN progress REAL", nil, nil, nil)
            }
            if !columnExists("tags") {
                sqlite3_exec(db, "ALTER TABLE books ADD COLUMN tags TEXT", nil, nil, nil)
            }
        }
        sqlite3_exec(db, "PRAGMA user_version = 4", nil, nil, nil)
    }

    private func lastErrorMessage(_ db: OpaquePointer?) -> String {
        guard let db else { return "unknown" }
        return String(cString: sqlite3_errmsg(db))
    }

    // MARK: - 寫入/讀取

    @discardableResult
    func insertBook(_ book: Book) -> Int64? {
        guard let db else { return nil }
        let now = Date().iso8601
        var stmt: OpaquePointer?
        let sql = """
        INSERT INTO books(isbn, title, author, publisher, coverUrl, description,
                          purchasePrice, salePrice, purchaseDate, saleDate,
                          startDate, finishDate, progress, quantity, status,
                          language, lexileScore, tags, createdAt, updatedAt)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_text(stmt, 1, book.isbn, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, book.title, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, book.author, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 4, book.publisher, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 5, book.coverUrl, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 6, book.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 7, book.purchasePrice)
        sqlite3_bind_double(stmt, 8, book.salePrice ?? 0)
        sqlite3_bind_text(stmt, 9, book.purchaseDate.iso8601, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 10, book.saleDate?.iso8601, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 11, book.startDate?.iso8601, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 12, book.finishDate?.iso8601, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 13, book.progress ?? 0)
        sqlite3_bind_int(stmt, 14, Int32(book.quantity))
        sqlite3_bind_text(stmt, 15, book.status, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 16, book.language, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 17, Int32(book.lexileScore ?? 0))
        sqlite3_bind_text(stmt, 18, book.tags, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 19, now, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 20, now, -1, SQLITE_TRANSIENT)
        let rc = sqlite3_step(stmt)
        sqlite3_finalize(stmt)
        if rc == SQLITE_DONE {
            return sqlite3_last_insert_rowid(db)
        }
        return nil
    }

    func getAllBooks() -> [Book] {
        guard let db else { return [] }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT * FROM books ORDER BY createdAt DESC", -1, &stmt, nil) == SQLITE_OK else { return [] }
        var books: [Book] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let b = book(from: stmt) { books.append(b) }
        }
        sqlite3_finalize(stmt)
        return books
    }

    func getBookByISBN(_ isbn: String) -> Book? {
        guard let db else { return nil }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT * FROM books WHERE isbn = ? LIMIT 1", -1, &stmt, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_text(stmt, 1, isbn, -1, SQLITE_TRANSIENT)
        defer { sqlite3_finalize(stmt) }
        if sqlite3_step(stmt) == SQLITE_ROW { return book(from: stmt) }
        return nil
    }

    func updateBook(_ book: Book) -> Bool {
        guard let db, let id = book.id else { return false }
        var stmt: OpaquePointer?
        let sql = """
        UPDATE books SET isbn=?, title=?, author=?, publisher=?, coverUrl=?, description=?,
        purchasePrice=?, salePrice=?, purchaseDate=?, saleDate=?,
        startDate=?, finishDate=?, progress=?, quantity=?, status=?,
        language=?, lexileScore=?, tags=?, updatedAt=? WHERE id=?
        """
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        sqlite3_bind_text(stmt, 1, book.isbn, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, book.title, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, book.author, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 4, book.publisher, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 5, book.coverUrl, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 6, book.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 7, book.purchasePrice)
        sqlite3_bind_double(stmt, 8, book.salePrice ?? 0)
        sqlite3_bind_text(stmt, 9, book.purchaseDate.iso8601, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 10, book.saleDate?.iso8601, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 11, book.startDate?.iso8601, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 12, book.finishDate?.iso8601, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 13, book.progress ?? 0)
        sqlite3_bind_int(stmt, 14, Int32(book.quantity))
        sqlite3_bind_text(stmt, 15, book.status, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 16, book.language, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 17, Int32(book.lexileScore ?? 0))
        sqlite3_bind_text(stmt, 18, book.tags, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 19, Date().iso8601, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 20, Int32(id))
        let rc = sqlite3_step(stmt)
        sqlite3_finalize(stmt)
        return rc == SQLITE_DONE
    }

    func deleteBook(id: Int) -> Bool {
        guard let db else { return false }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "DELETE FROM books WHERE id = ?", -1, &stmt, nil) == SQLITE_OK else { return false }
        sqlite3_bind_int(stmt, 1, Int32(id))
        let rc = sqlite3_step(stmt)
        sqlite3_finalize(stmt)
        return rc == SQLITE_DONE
    }

    struct Statistics {
        var totalBooks = 0
        var readBooks = 0
        var readingBooks = 0
        var unreadBooks = 0
        var totalSpent = 0.0
        var totalEarned = 0.0
        var totalProfit: Double { totalEarned - totalSpent }
    }

    func getStatistics() -> Statistics {
        guard let db else { return Statistics() }
        var stats = Statistics()
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM books", -1, &stmt, nil) == SQLITE_OK,
           sqlite3_step(stmt) == SQLITE_ROW {
            stats.totalBooks = Int(sqlite3_column_int64(stmt, 0))
        }
        sqlite3_finalize(stmt)
        for (key, status) in [("read", "read"), ("reading", "reading"), ("unread", "unread")] {
            var s: OpaquePointer?
            guard sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM books WHERE status = ?", -1, &s, nil) == SQLITE_OK else { continue }
            sqlite3_bind_text(s, 1, status, -1, SQLITE_TRANSIENT)
            if sqlite3_step(s) == SQLITE_ROW {
                let v = Int(sqlite3_column_int64(s, 0))
                switch key {
                case "read": stats.readBooks = v
                case "reading": stats.readingBooks = v
                default: stats.unreadBooks = v
                }
            }
            sqlite3_finalize(s)
        }
        var s: OpaquePointer?
        if sqlite3_prepare_v2(db, "SELECT SUM(purchasePrice * quantity) FROM books", -1, &s, nil) == SQLITE_OK,
           sqlite3_step(s) == SQLITE_ROW {
            let v = sqlite3_column_double(s, 0)
            if v > 0 { stats.totalSpent = v }
        }
        sqlite3_finalize(s)
        if sqlite3_prepare_v2(db, "SELECT SUM(salePrice * quantity) FROM books WHERE salePrice IS NOT NULL", -1, &s, nil) == SQLITE_OK,
           sqlite3_step(s) == SQLITE_ROW {
            let v = sqlite3_column_double(s, 0)
            if v > 0 { stats.totalEarned = v }
        }
        sqlite3_finalize(s)
        return stats
    }

    // MARK: - Row 解析

    private func book(from stmt: OpaquePointer?) -> Book? {
        guard let stmt else { return nil }

        func idx(_ name: String) -> Int32? { columnIndex(name, in: stmt) }
        func text(_ name: String) -> String? {
            guard let i = idx(name) else { return nil }
            let ptr = sqlite3_column_text(stmt, i)
            return ptr != nil ? String(cString: ptr!) : nil
        }
        func intVal(_ name: String) -> Int? {
            guard let i = idx(name) else { return nil }
            return Int(sqlite3_column_int64(stmt, i))
        }
        func doubleVal(_ name: String) -> Double? {
            guard let i = idx(name) else { return nil }
            return sqlite3_column_double(stmt, i)
        }
        func optionalInt(_ name: String) -> Int? {
            guard let i = idx(name) else { return nil }
            return sqlite3_column_type(stmt, i) == SQLITE_NULL ? nil : Int(sqlite3_column_int64(stmt, i))
        }
        func optionalDouble(_ name: String) -> Double? {
            guard let i = idx(name) else { return nil }
            return sqlite3_column_type(stmt, i) == SQLITE_NULL ? nil : sqlite3_column_double(stmt, i)
        }

        guard let id = intVal("id"), let isbn = text("isbn") else { return nil }

        return Book(id: id, isbn: isbn,
                    title: text("title") ?? "",
                    author: text("author") ?? "",
                    publisher: text("publisher") ?? "",
                    coverUrl: text("coverUrl"), description: text("description"),
                    purchasePrice: doubleVal("purchasePrice") ?? 0,
                    salePrice: optionalDouble("salePrice"),
                    purchaseDate: Date(iso8601: text("purchaseDate") ?? ""),
                    saleDate: text("saleDate").map { Date(iso8601: $0) },
                    startDate: text("startDate").map { Date(iso8601: $0) },
                    finishDate: text("finishDate").map { Date(iso8601: $0) },
                    progress: optionalDouble("progress"),
                    quantity: intVal("quantity") ?? 1,
                    status: text("status") ?? "unread",
                    language: text("language"),
                    lexileScore: optionalInt("lexileScore"),
                    tags: text("tags"))
    }

    /// 依欄位名稱取得在 SELECT * 結果中的欄位索引，避免因遷移路徑不同造成的欄位順序差異。
    private func columnIndex(_ name: String, in stmt: OpaquePointer?) -> Int32? {
        guard let stmt else { return nil }
        let count = sqlite3_column_count(stmt)
        for i in 0..<count {
            guard let ptr = sqlite3_column_name(stmt, i) else { continue }
            if String(cString: ptr) == name { return i }
        }
        return nil
    }
}

extension Date {
    var iso8601: String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: self)
    }
    init(iso8601: String) {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        self = f.date(from: iso8601) ?? Date()
    }
}
