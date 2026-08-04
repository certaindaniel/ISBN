import Foundation
import CloudKit

/// CloudKit 同步服務：把書籍資料同步到使用者私人 iCloud 資料庫。
/// 以 ISBN 作為 CloudKit record 名稱（跨裝置穩定）。推本機、拉遠端並合併。
@MainActor
final class SyncService {
    static let shared = SyncService()
    private let container = CKContainer(identifier: "iCloud.com.daniel.isbn")
    private var database: CKDatabase { container.privateCloudDatabase }

    private let recordType = "Book"

    /// 推本機所有書籍到 iCloud；拉遠端並合併缺失的書。回傳錯誤訊息（nil = 成功）。
    func sync() async -> String? {
        // 先確認 iCloud 帳號可用與 container 可存取
        do {
            let status = try await container.accountStatus()
            if status != .available {
                return "account_status_\(status.rawValue)"
            }
        } catch {
            return "account_status_check_failed: \(cloudKitErrorDetail(error))"
        }

        let localBooks = Database.shared.getAllBooks()
        var records: [CKRecord] = []
        for book in localBooks {
            records.append(record(from: book))
        }
        if !records.isEmpty {
            do {
                try await saveRecords(records)
            } catch {
                return "icloud_push_failed: \(cloudKitErrorDetail(error))"
            }
        }

        do {
            let remote = try await fetchRecords()
            for record in remote {
                if let book = book(from: record),
                   Database.shared.getBookByISBN(book.isbn) == nil {
                    Database.shared.insertBook(book)
                }
            }
        } catch {
            return "icloud_pull_failed: \(cloudKitErrorDetail(error))"
        }
        return nil
    }

    private func cloudKitErrorDetail(_ error: Error) -> String {
        if let ck = error as? CKError {
            return "CKError \(ck.code.rawValue): \(ck.localizedDescription)"
        }
        return error.localizedDescription
    }

    private func saveRecords(_ records: [CKRecord]) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            op.savePolicy = .allKeys
            op.modifyRecordsCompletionBlock = { (_ saved: [CKRecord]?, _ deleted: [CKRecord.ID]?, _ error: Error?) in
                if let error { cont.resume(throwing: error) } else { cont.resume(returning: ()) }
            }
            database.add(op)
        }
    }

    private func fetchRecords() async throws -> [CKRecord] {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[CKRecord], Error>) in
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            let op = CKQueryOperation(query: query)
            op.resultsLimit = CKQueryOperation.maximumResults
            var records: [CKRecord] = []
            op.recordMatchedBlock = { (_ recordID: CKRecord.ID, _ result: Result<CKRecord, Error>) in
                if case .success(let record) = result { records.append(record) }
            }
            op.queryCompletionBlock = { (_ cursor: CKQueryOperation.Cursor?, _ error: Error?) in
                if let error { cont.resume(throwing: error) } else { cont.resume(returning: records) }
            }
            database.add(op)
        }
    }

    private func record(from book: Book) -> CKRecord {
        let record = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: "book-\(book.isbn)"))
        record["isbn"] = book.isbn as CKRecordValue
        record["title"] = book.title as CKRecordValue
        record["author"] = book.author as CKRecordValue
        record["publisher"] = book.publisher as CKRecordValue
        if let coverUrl = book.coverUrl { record["coverUrl"] = coverUrl as CKRecordValue }
        if let description = book.description { record["description"] = description as CKRecordValue }
        record["purchasePrice"] = book.purchasePrice as CKRecordValue
        if let salePrice = book.salePrice { record["salePrice"] = salePrice as CKRecordValue }
        record["purchaseDate"] = book.purchaseDate as CKRecordValue
        if let saleDate = book.saleDate { record["saleDate"] = saleDate as CKRecordValue }
        if let startDate = book.startDate { record["startDate"] = startDate as CKRecordValue }
        if let finishDate = book.finishDate { record["finishDate"] = finishDate as CKRecordValue }
        if let progress = book.progress { record["progress"] = progress as CKRecordValue }
        record["quantity"] = book.quantity as CKRecordValue
        record["status"] = book.status as CKRecordValue
        if let language = book.language { record["language"] = language as CKRecordValue }
        if let lexileScore = book.lexileScore { record["lexileScore"] = lexileScore as CKRecordValue }
        if let tags = book.tags { record["tags"] = tags as CKRecordValue }
        return record
    }

    private func book(from record: CKRecord) -> Book? {
        guard let isbn = record["isbn"] as? String, !isbn.isEmpty else { return nil }
        let title = record["title"] as? String ?? ""
        let author = record["author"] as? String ?? ""
        let publisher = record["publisher"] as? String ?? ""
        return Book(id: nil, isbn: isbn, title: title, author: author, publisher: publisher,
                    coverUrl: record["coverUrl"] as? String,
                    description: record["description"] as? String,
                    purchasePrice: record["purchasePrice"] as? Double ?? 0,
                    salePrice: record["salePrice"] as? Double,
                    purchaseDate: record["purchaseDate"] as? Date ?? Date(),
                    saleDate: record["saleDate"] as? Date,
                    startDate: record["startDate"] as? Date,
                    finishDate: record["finishDate"] as? Date,
                    progress: record["progress"] as? Double,
                    quantity: record["quantity"] as? Int ?? 1,
                    status: record["status"] as? String ?? "unread",
                    language: record["language"] as? String,
                    lexileScore: record["lexileScore"] as? Int,
                    tags: record["tags"] as? String)
    }
}
