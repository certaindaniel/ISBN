import XCTest
@testable import ISBNManager

final class ISBNServiceTests: XCTestCase {
    func testISBN10Validation() {
        XCTAssertTrue(ISBNService.isValidIsbn("013603599X"))
        XCTAssertTrue(ISBNService.isValidIsbn("9780136035992"))
        XCTAssertFalse(ISBNService.isValidIsbn("0136035991"))
    }

    func testISBN13Validation() {
        XCTAssertTrue(ISBNService.isValidIsbn("9780136035992"))
        XCTAssertFalse(ISBNService.isValidIsbn("9780136035993"))
    }

    func testNormalize() {
        XCTAssertEqual(ISBNService.normalizeIsbn("978-0-14032-872-1"), "9780140328721")
    }

    func testFormat() {
        XCTAssertEqual(ISBNService.formatIsbn("9780136035992"), "978-0-13603-599-2")
    }

    func testEan13NotIsbn() {
        XCTAssertTrue(ISBNService.isEan13ButNotIsbn("4006381333931"))
    }

    func testLanguageDetection() {
        XCTAssertEqual(ISBNService.detectLanguage(title: "哈利波特", author: "J.K. Rowling"), "zh")
        XCTAssertEqual(ISBNService.detectLanguage(title: "Harry Potter", author: "J.K. Rowling"), "en")
    }
}
