import Foundation

/// 書籍資料模型，與 Flutter 版欄位一致。
struct Book: Identifiable, Codable {
    var id: Int?
    var isbn: String
    var title: String
    var author: String
    var publisher: String
    var coverUrl: String?
    var description: String?
    var purchasePrice: Double
    var salePrice: Double?
    var purchaseDate: Date
    var saleDate: Date?
    var quantity: Int
    var status: String  // 'unread' | 'reading' | 'read'
    var language: String?
    var lexileScore: Int?

    init(id: Int? = nil, isbn: String, title: String, author: String, publisher: String,
         coverUrl: String? = nil, description: String? = nil, purchasePrice: Double,
         salePrice: Double? = nil, purchaseDate: Date, saleDate: Date? = nil,
         quantity: Int = 1, status: String = "unread", language: String? = nil,
         lexileScore: Int? = nil) {
        self.id = id
        self.isbn = isbn
        self.title = title
        self.author = author
        self.publisher = publisher
        self.coverUrl = coverUrl
        self.description = description
        self.purchasePrice = purchasePrice
        self.salePrice = salePrice
        self.purchaseDate = purchaseDate
        self.saleDate = saleDate
        self.quantity = quantity
        self.status = status
        self.language = language
        self.lexileScore = lexileScore
    }

    var profit: Double? {
        guard let sale = salePrice else { return nil }
        return sale - purchasePrice
    }
}
