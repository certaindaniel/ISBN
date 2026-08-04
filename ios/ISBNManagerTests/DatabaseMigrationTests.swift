import XCTest
import SQLite3
@testable import ISBNManager

final class DatabaseMigrationTests: XCTestCase {
    private var dir: String!

    override func setUpWithError() throws {
        dir = NSTemporaryDirectory() + "dbmig_" + UUID().uuidString
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(atPath: dir)
    }

    private func file(_ name: String) -> String { dir + "/" + name }

    @discardableResult
    private func exec(_ path: String, _ sql: String) {
        var db: OpaquePointer?
        XCTAssertEqual(sqlite3_open(path, &db), SQLITE_OK)
        XCTAssertEqual(sqlite3_exec(db, sql, nil, nil, nil), SQLITE_OK)
        XCTAssertEqual(sqlite3_close(db), SQLITE_OK)
    }

    private func userVersion(_ path: String) -> Int32 {
        var db: OpaquePointer?
        guard sqlite3_open(path, &db) == SQLITE_OK else { return -1 }
        defer { sqlite3_close(db) }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "PRAGMA user_version", -1, &stmt, nil) == SQLITE_OK else { return -1 }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return -1 }
        return sqlite3_column_int(stmt, 0)
    }

    private func makeV1(_ path: String) {
        exec(path, """
        PRAGMA user_version = 1;
        CREATE TABLE books(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          isbn TEXT UNIQUE NOT NULL, title TEXT NOT NULL, author TEXT NOT NULL,
          publisher TEXT NOT NULL, coverUrl TEXT, description TEXT,
          purchasePrice REAL NOT NULL, salePrice REAL,
          purchaseDate TEXT NOT NULL, saleDate TEXT,
          quantity INTEGER DEFAULT 1, status TEXT DEFAULT 'owned',
          createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL
        );
        INSERT INTO books(isbn,title,author,publisher,purchasePrice,purchaseDate,status,createdAt,updatedAt)
        VALUES('0140328721','1984','Orwell','Penguin',10.5,'2020-01-01T00:00:00Z','owned','2020-01-01T00:00:00Z','2020-01-01T00:00:00Z');
        INSERT INTO books(isbn,title,author,publisher,purchasePrice,salePrice,purchaseDate,saleDate,status,createdAt,updatedAt)
        VALUES('9780140328721','1984 b','Orwell','Penguin',20.0,30.0,'2021-02-02T00:00:00Z','2021-03-03T00:00:00Z','sold','2021-02-02T00:00:00Z','2021-03-03T00:00:00Z');
        """)
    }

    private func makeV2(_ path: String) {
        exec(path, """
        PRAGMA user_version = 2;
        CREATE TABLE books(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          isbn TEXT UNIQUE NOT NULL, title TEXT NOT NULL, author TEXT NOT NULL,
          publisher TEXT NOT NULL, coverUrl TEXT, description TEXT,
          purchasePrice REAL NOT NULL, salePrice REAL,
          purchaseDate TEXT NOT NULL, saleDate TEXT,
          quantity INTEGER DEFAULT 1, status TEXT DEFAULT 'unread',
          language TEXT, lexileScore INTEGER,
          createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL
        );
        INSERT INTO books(isbn,title,author,publisher,purchasePrice,purchaseDate,status,language,lexileScore,createdAt,updatedAt)
        VALUES('0140328721','1984','Orwell','Penguin',10.5,'2020-01-01T00:00:00Z','owned','en',900,'2020-01-01T00:00:00Z','2020-01-01T00:00:00Z');
        INSERT INTO books(isbn,title,author,publisher,purchasePrice,salePrice,purchaseDate,saleDate,status,language,createdAt,updatedAt)
        VALUES('9780140328721','1984 b','Orwell','Penguin',20.0,30.0,'2021-02-02T00:00:00Z','2021-03-03T00:00:00Z','sold','zh','2021-02-02T00:00:00Z','2021-03-03T00:00:00Z');
        """)
    }

    private func makeV3(_ path: String) {
        exec(path, """
        PRAGMA user_version = 3;
        CREATE TABLE books(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          isbn TEXT UNIQUE NOT NULL, title TEXT NOT NULL, author TEXT NOT NULL,
          publisher TEXT NOT NULL, coverUrl TEXT, description TEXT,
          purchasePrice REAL NOT NULL, salePrice REAL,
          purchaseDate TEXT NOT NULL, saleDate TEXT,
          quantity INTEGER DEFAULT 1, status TEXT DEFAULT 'unread',
          language TEXT, lexileScore INTEGER,
          createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL
        );
        INSERT INTO books(isbn,title,author,publisher,purchasePrice,purchaseDate,status,language,lexileScore,createdAt,updatedAt)
        VALUES('0140328721','1984','Orwell','Penguin',10.5,'2020-01-01T00:00:00Z','read','en',900,'2020-01-01T00:00:00Z','2020-01-01T00:00:00Z');
        INSERT INTO books(isbn,title,author,publisher,purchasePrice,purchaseDate,status,language,createdAt,updatedAt)
        VALUES('9781491927281','Learn JS','x','y',5.0,'2022-04-04T00:00:00Z','unread','en','2022-04-04T00:00:00Z','2022-04-04T00:00:00Z');
        """)
    }

    /// v1 既有資料庫：無 language/lexileScore、舊狀態（owned/sold）。
    /// Swift 遷移會附加欄位並對齊狀態，資料須完整保留。
    func testMigrateFromV1PreservesData() {
        let p = file("v1.db")
        makeV1(p)
        let db = Database(dbPath: p)
        let books = db.getAllBooks()
        XCTAssertEqual(books.count, 2)

        let first = books.first { $0.isbn == "0140328721" }
        XCTAssertEqual(first?.status, "unread")   // owned -> unread
        XCTAssertEqual(first?.purchasePrice, 10.5)
        XCTAssertNil(first?.salePrice)
        XCTAssertNil(first?.language)
        XCTAssertNil(first?.lexileScore)

        let sold = books.first { $0.isbn == "9780140328721" }
        XCTAssertEqual(sold?.status, "read")      // sold -> read
        XCTAssertEqual(sold?.purchasePrice, 20.0)
        XCTAssertEqual(sold?.salePrice, 30.0)
        XCTAssertEqual(userVersion(p), 3)
    }

    /// v2 既有資料庫：已有 language/lexileScore、舊狀態（owned/sold）。
    func testMigrateFromV2NormalizesStatuses() {
        let p = file("v2.db")
        makeV2(p)
        _ = Database(dbPath: p)
        let db = Database(dbPath: p)
        let books = db.getAllBooks()
        XCTAssertEqual(books.count, 2)

        let first = books.first { $0.isbn == "0140328721" }
        XCTAssertEqual(first?.status, "unread")
        XCTAssertEqual(first?.language, "en")
        XCTAssertEqual(first?.lexileScore, 900)

        let sold = books.first { $0.isbn == "9780140328721" }
        XCTAssertEqual(sold?.status, "read")
        XCTAssertEqual(sold?.language, "zh")
        XCTAssertEqual(userVersion(p), 3)
    }

    /// v3 既有資料庫：完整 schema、狀態已對齊。遷移不應造成任何資料變動。
    func testMigrateFromV3NoDataLoss() {
        let p = file("v3.db")
        makeV3(p)
        _ = Database(dbPath: p)
        let db = Database(dbPath: p)
        let books = db.getAllBooks()
        XCTAssertEqual(books.count, 2)

        let first = books.first { $0.isbn == "0140328721" }
        XCTAssertEqual(first?.status, "read")
        XCTAssertEqual(first?.language, "en")
        XCTAssertEqual(first?.lexileScore, 900)
        XCTAssertEqual(first?.purchasePrice, 10.5)

        let second = books.first { $0.isbn == "9781491927281" }
        XCTAssertEqual(second?.status, "unread")
        XCTAssertEqual(second?.language, "en")
        XCTAssertEqual(userVersion(p), 3)
    }

    /// 模擬 sqflite 從 v1 升級到 v3 的真實路徑：language/lexileScore 被附加到表格尾端。
    /// 即使欄位順序與新建立資料庫不同，Swift 讀取器也必須依欄位名稱正確解析。
    func testUpgradedFromV1ReadsAppendedColumnsByName() {
        let p = file("upgraded.db")
        makeV1(p)
        exec(p, """
        ALTER TABLE books ADD COLUMN language TEXT;
        ALTER TABLE books ADD COLUMN lexileScore INTEGER;
        UPDATE books SET language='en', lexileScore=900 WHERE isbn='0140328721';
        UPDATE books SET language='zh' WHERE isbn='9780140328721';
        UPDATE books SET status='unread' WHERE status='owned';
        UPDATE books SET status='read' WHERE status='sold';
        PRAGMA user_version = 3;
        """)
        let db = Database(dbPath: p)
        let books = db.getAllBooks()
        XCTAssertEqual(books.count, 2)

        let first = books.first { $0.isbn == "0140328721" }
        XCTAssertEqual(first?.status, "unread")
        XCTAssertEqual(first?.language, "en")
        XCTAssertEqual(first?.lexileScore, 900)
        XCTAssertEqual(first?.salePrice, nil)

        let sold = books.first { $0.isbn == "9780140328721" }
        XCTAssertEqual(sold?.status, "read")
        XCTAssertEqual(sold?.language, "zh")
        XCTAssertEqual(sold?.salePrice, 30.0)
        XCTAssertEqual(userVersion(p), 3)
    }

    /// 遷移後重新寫入與更新書籍，確保 CRUD 在既有資料庫上仍正常。
    func testCRUDOnMigratedDatabase() {
        let p = file("crud.db")
        makeV3(p)
        let db = Database(dbPath: p)
        let created = db.insertBook(Book(isbn: "9781449355739", title: "Programming Rust",
                                         author: "Blandy", publisher: "Oreilly",
                                         purchasePrice: 12.0, purchaseDate: Date(),
                                         status: "unread", language: "en", lexileScore: 1000))
        XCTAssertNotNil(created)
        XCTAssertEqual(db.getAllBooks().count, 3)

        var fetched = db.getBookByISBN("9781449355739")
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.language, "en")
        XCTAssertEqual(fetched?.lexileScore, 1000)

        fetched?.status = "read"
        XCTAssertTrue(db.updateBook(fetched!))
        XCTAssertEqual(db.getBookByISBN("9781449355739")?.status, "read")

        XCTAssertTrue(db.deleteBook(id: Int(created!)))
        XCTAssertEqual(db.getAllBooks().count, 2)
    }
}
