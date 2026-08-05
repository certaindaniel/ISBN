import XCTest
@testable import ISBNManager

/// 驗證「掃描器解出的 ISBN 是否能查到對應書籍」。
/// - 結構驗證為純單元測試（離線、確定性）。
/// - 來源查詢為整合測試（依賴外部 API，網路不穩時可能失敗）。
final class ISBNLookupTests: XCTestCase {
    /// 掃描器從截圖解出的條碼值：9789812408198。
    /// 必須是結構上有效的 ISBN-13（978 開頭、檢查碼正確）。
    func testDecodedIsbnIsStructurallyValid() {
        XCTAssertTrue(ISBNService.isValidIsbn("9789812408198"))
        XCTAssertEqual(ISBNService.normalizeIsbn("9789812408198"), "9789812408198")
        XCTAssertEqual(ISBNService.isEanButNotIsbn("9789812408198"), false)
    }

    /// 實測（2026-08）：Google Books / Open Library / Wikidata / Library of Congress
    /// 四個預設來源對 9789812408198 皆查無對應書籍。
    func testLookupDecodedIsbnAcrossSources() async throws {
        let isbn = "9789812408198"
        let sources = ApiSource.defaultEnabled()
        let book = try await ISBNService.searchByIsbn(isbn, sources: sources)
        XCTAssertNil(book, "9789812408198 在預設來源皆查無對應書籍（實測為空）")
    }
}
