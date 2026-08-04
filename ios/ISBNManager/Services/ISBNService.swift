import Foundation

/// ISBN 查詢例外。
struct IsbnError: Error {
    let message: String
    let code: String
}

/// ISBN 驗證與書籍資訊查詢服務（多來源依序嘗試）。
struct ISBNService {
    static let openLibraryBaseURL = "https://openlibrary.org/api/books"
    static let timeout: TimeInterval = 12

    // MARK: - 驗證與格式化

    static func normalizeIsbn(_ raw: String) -> String {
        var cleaned = ""
        for c in raw.uppercased() {
            if c.isNumber || c == "X" { cleaned.append(c) }
        }
        return cleaned
    }

    static func isValidIsbn10(_ isbn: String) -> Bool {
        guard isbn.count == 10 else { return false }
        let chars = Array(isbn)
        for i in 0..<9 {
            guard chars[i].isNumber else { return false }
        }
        guard chars[9] == "X" || chars[9].isNumber else { return false }
        var sum = 0
        for i in 0..<9 {
            sum += (chars[i].wholeNumberValue ?? 0) * (10 - i)
        }
        let expected = (11 - (sum % 11)) % 11
        let expectedChar = expected == 10 ? "X" : String(expected)
        return expectedChar == String(chars[9])
    }

    static func isValidIsbn13(_ isbn: String) -> Bool {
        guard isbn.count == 13 else { return false }
        guard isbn.hasPrefix("978") || isbn.hasPrefix("979") else { return false }
        let chars = Array(isbn)
        var sum = 0
        for i in 0..<12 {
            guard chars[i].isNumber else { return false }
            let d = chars[i].wholeNumberValue ?? 0
            sum += i % 2 == 0 ? d : d * 3
        }
        guard let checkDigit = chars[12].wholeNumberValue else { return false }
        let expected = (10 - (sum % 10)) % 10
        return checkDigit == expected
    }

    static func isValidIsbn(_ isbn: String) -> Bool {
        let cleaned = normalizeIsbn(isbn)
        if cleaned.count == 10 { return isValidIsbn10(cleaned) }
        if cleaned.count == 13 { return isValidIsbn13(cleaned) }
        return false
    }

    /// 檢查是否為有效 EAN-13 條碼（但非書籍 ISBN）。
    static func isEan13ButNotIsbn(_ code: String) -> Bool {
        let cleaned = normalizeIsbn(code)
        if cleaned.count != 13 { return false }
        if cleaned.hasPrefix("978") || cleaned.hasPrefix("979") { return false }
        let chars = Array(cleaned)
        var sum = 0
        for i in 0..<12 {
            let d = chars[i].wholeNumberValue ?? 0
            sum += i % 2 == 0 ? d : d * 3
        }
        guard let checkDigit = chars[12].wholeNumberValue else { return false }
        let expected = (10 - (sum % 10)) % 10
        return checkDigit == expected
    }

    static func formatIsbn(_ isbn: String) -> String {
        let cleaned = normalizeIsbn(isbn)
        if cleaned.count == 13 {
            let c = Array(cleaned)
            return "\(c[0])\(c[1])\(c[2])-\(c[3])-\(String(c[4...8]))-\(String(c[9...11]))-\(c[12])"
        }
        return cleaned
    }

    /// 從文字中提取所有可能的 ISBN。
    static func extractIsbnFromText(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        for c in text.uppercased() {
            if c.isNumber || c == "X" {
                current.append(c)
                for start in 0..<current.count {
                    let tail = String(current.suffix(current.count - start))
                    if (tail.count == 10 || tail.count == 13) && isValidIsbn(tail) {
                        result.append(tail)
                        break
                    }
                }
                if current.count > 16 { current = "" }
            } else {
                current = ""
            }
        }
        var seen = Set<String>()
        return result.filter { seen.insert($0).inserted }
    }

    // MARK: - 語言偵測

    static func detectLanguage(title: String, author: String) -> String {
        let text = title + author
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x4E00...0x9FA5: return "zh"
            case 0x3040...0x30FF: return "ja"
            default: break
            }
        }
        return "en"
    }
}

extension ISBNService {
    // MARK: - 查詢

    /// 多來源依序查詢 ISBN。
    static func searchByIsbn(_ rawIsbn: String, sources: [ApiSource],
                             onSourceStart: ((ApiSource) -> Void)? = nil) async throws -> Book? {
        let isbn = normalizeIsbn(rawIsbn)
        if !isValidIsbn(isbn) {
            if isEan13ButNotIsbn(isbn) {
                throw IsbnError(message: "請掃描 ISBN 條碼，這個是 EAN", code: "scan_not_isbn_ean")
            }
            throw IsbnError(message: "無效的 ISBN 格式", code: "isbn_error_invalid_format")
        }
        let active = sources.isEmpty ? ApiSource.defaultEnabled() : sources
        for source in active {
            onSourceStart?(source)
            var result: Book?
            switch source {
            case .googleBooks: result = try? await searchGoogleBooks(isbn)
            case .openLibrary: result = try? await searchOpenLibrary(isbn)
            case .wikipedia: result = try? await searchWikipedia(isbn)
            case .jikeFree: result = try? await searchJikeFree(isbn)
            }
            if let result { return result }
        }
        return nil
    }

    static func searchOpenLibrary(_ isbn: String) async throws -> Book? {
        guard let url = URL(string: "\(openLibraryBaseURL)?bibkeys=ISBN:\(isbn)&format=json") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: timeout)
        req.httpMethod = "GET"
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let bookData = obj["ISBN:\(isbn)"] as? [String: Any] else { return nil }
        let title = bookData["title"] as? String ?? ""
        let authors = bookData["authors"] as? [Any]
        let author = (authors?.first as? [String: Any])?["name"] as? String ?? ""
        let publishers = bookData["publishers"] as? [Any]
        let publisher = (publishers?.first as? [String: Any])?["name"] as? String ?? ""
        let cover = (bookData["cover"] as? [String: Any])?["large"] as? String
        var book = Book(isbn: isbn, title: title, author: author, publisher: publisher,
                        coverUrl: cover, purchasePrice: 0, purchaseDate: Date())
        let language = detectLanguage(title: title, author: author)
        if language == "en" {
            book.lexileScore = await fetchLexileScore(isbn: isbn, title: title)
        }
        book.language = language
        return book
    }

    static func searchGoogleBooks(_ isbn: String) async throws -> Book? {
        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: timeout)
        req.httpMethod = "GET"
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = obj["items"] as? [Any], !items.isEmpty,
              let volume = (items.first as? [String: Any])?["volumeInfo"] as? [String: Any] else { return nil }
        let title = volume["title"] as? String ?? ""
        let authors = volume["authors"] as? [Any]
        let author = authors?.first as? String ?? ""
        let publisher = volume["publisher"] as? String ?? ""
        let imageLinks = volume["imageLinks"] as? [String: Any]
        let coverUrl = imageLinks?["thumbnail"] as? String ?? imageLinks?["smallThumbnail"] as? String
        let language = volume["language"] as? String ?? detectLanguage(title: title, author: author)
        var book = Book(isbn: isbn, title: title, author: author, publisher: publisher,
                        coverUrl: coverUrl, purchasePrice: 0, purchaseDate: Date())
        if language == "en" {
            book.lexileScore = await fetchLexileScore(isbn: isbn, title: title)
        }
        book.language = language
        return book
    }

    static func searchWikipedia(_ isbn: String) async throws -> Book? {
        let enc = "ISBN \(isbn)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=\(enc)&format=json&srprop=snippet") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: timeout)
        req.httpMethod = "GET"
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let search = (obj["query"] as? [String: Any])?["search"] as? [Any],
              !search.isEmpty,
              let first = search.first as? [String: Any] else { return nil }
        let snippet = first["snippet"] as? String ?? ""
        guard !snippet.isEmpty else { return nil }
        return Book(isbn: isbn, title: first["title"] as? String ?? "", author: "",
                    publisher: "", purchasePrice: 0, purchaseDate: Date())
    }

    static func searchJikeFree(_ isbn: String) async throws -> Book? {
        guard let url = URL(string: "https://api.jike.xyz/situ/book/isbn/\(isbn)") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.httpMethod = "GET"
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let payload = (obj["data"] as? [String: Any]) ?? obj
        let title = payload["title"] as? String ?? ""
        let authorRaw = payload["author"] ?? payload["authors"]
        var author = ""
        if let list = authorRaw as? [Any], let first = list.first as? String { author = first }
        else if let s = authorRaw as? String { author = s }
        let publisher = payload["publisher"] as? String ?? ""
        let images = payload["images"] as? [String: Any]
        let coverUrl = images?["large"] as? String ?? payload["image"] as? String
        return Book(isbn: isbn, title: title, author: author, publisher: publisher,
                    coverUrl: coverUrl, purchasePrice: 0, purchaseDate: Date(), language: "zh")
    }

    // MARK: - Lexile

    static func fetchLexileScore(isbn: String, title: String) async -> Int? {
        guard let url = URL(string: "\(openLibraryBaseURL)?bibkeys=ISBN:\(isbn)&format=json") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.httpMethod = "GET"
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let bookData = obj["ISBN:\(isbn)"] as? [String: Any],
                  let classifications = bookData["classifications"] as? [String: Any],
                  let lexileData = classifications["lexile"] as? String else { return nil }
            return extractInt(lexileData)
        } catch {
            return nil
        }
    }

    static func extractInt(_ text: String) -> Int? {
        var best: Int?
        var current = ""
        for c in text {
            if c.isNumber { current.append(c) }
            else {
                if let v = Int(current), current.count >= 2 { best = v }
                current = ""
            }
        }
        if let v = Int(current), current.count >= 2 { best = v }
        return best
    }

    // MARK: - 書名查詢（Google Books + Open Library）

    static func searchByTitleAuthor(_ title: String, author: String? = nil, maxResults: Int = 10) async -> [Book] {
        var byIsbn: [String: Book] = [:]
        let google = await searchGoogleByTitle(title, author: author, maxResults: maxResults)
        let ol = await searchOpenLibraryByTitle(title, author: author, maxResults: maxResults)
        for b in google + ol {
            let key = normalizeIsbn(b.isbn)
            if !key.isEmpty { byIsbn[key] = b }
        }
        return Array(byIsbn.values)
    }

    static func searchGoogleByTitle(_ title: String, author: String?, maxResults: Int) async -> [Book] {
        var parts: [String] = []
        if !title.trimmingCharacters(in: .whitespaces).isEmpty {
            parts.append("intitle:" + title.trimmingCharacters(in: .whitespaces))
        }
        if let a = author, !a.trimmingCharacters(in: .whitespaces).isEmpty {
            parts.append("inauthor:" + a.trimmingCharacters(in: .whitespaces))
        }
        var query = parts.isEmpty ? title : parts.joined(separator: "+")
        var params = ["q": query, "printType": "books", "projection": "full",
                      "orderBy": "relevance", "maxResults": String(maxResults)]
        var items = await googleFetchItems(params)
        if items.isEmpty {
            params["q"] = title
            items = await googleFetchItems(params)
        }
        guard !items.isEmpty else { return [] }
        var results: [Book] = []
        for item in items {
            guard let volume = (item as? [String: Any])?["volumeInfo"] as? [String: Any] else { continue }
            var isbn: String?
            if let ids = volume["industryIdentifiers"] as? [Any] {
                for id in ids {
                    if let m = id as? [String: Any], m["type"] as? String == "ISBN_13",
                       let ident = m["identifier"] as? String {
                        isbn = ident.replacingOccurrences(of: "-", with: "")
                        break
                    }
                }
                if isbn == nil {
                    for id in ids {
                        if let m = id as? [String: Any], m["type"] as? String == "ISBN_10",
                           let ident = m["identifier"] as? String {
                            isbn = ident.replacingOccurrences(of: "-", with: "")
                            break
                        }
                    }
                }
            }
            guard let isbn, !isbn.isEmpty else { continue }
            let bTitle = volume["title"] as? String ?? ""
            let authors = volume["authors"] as? [Any]
            let bAuthor = authors?.first as? String ?? ""
            let publisher = volume["publisher"] as? String ?? ""
            let imageLinks = volume["imageLinks"] as? [String: Any]
            let cover = imageLinks?["thumbnail"] as? String ?? imageLinks?["smallThumbnail"] as? String
            let lang = volume["language"] as? String ?? detectLanguage(title: bTitle, author: bAuthor)
            results.append(Book(isbn: isbn, title: bTitle, author: bAuthor, publisher: publisher,
                                coverUrl: cover, purchasePrice: 0, purchaseDate: Date(), language: lang))
        }
        return results
    }

    static func googleFetchItems(_ params: [String: String]) async -> [Any] {
        var comps = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        comps?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = comps?.url else { return [] }
        var req = URLRequest(url: url, timeoutInterval: timeout)
        req.httpMethod = "GET"
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }
            return (obj["items"] as? [Any]) ?? []
        } catch {
            return []
        }
    }

    static func searchOpenLibraryByTitle(_ title: String, author: String?, maxResults: Int) async -> [Book] {
        var comps = URLComponents(string: "https://openlibrary.org/search.json")
        var qs: [URLQueryItem] = [URLQueryItem(name: "title", value: title)]
        if let a = author, !a.isEmpty { qs.append(URLQueryItem(name: "author", value: a)) }
        qs.append(URLQueryItem(name: "limit", value: String(maxResults)))
        comps?.queryItems = qs
        guard let url = comps?.url else { return [] }
        var req = URLRequest(url: url, timeoutInterval: timeout)
        req.httpMethod = "GET"
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let docs = obj["docs"] as? [Any] else { return [] }
            var results: [Book] = []
            for doc in docs {
                guard let d = doc as? [String: Any] else { continue }
                let isbns = d["isbn"] as? [String] ?? []
                var isbn: String?
                for id in isbns {
                    let cleaned = normalizeIsbn(id)
                    if cleaned.count == 13 && isValidIsbn13(cleaned) { isbn = cleaned; break }
                }
                if isbn == nil {
                    for id in isbns {
                        let cleaned = normalizeIsbn(id)
                        if cleaned.count == 10 && isValidIsbn10(cleaned) { isbn = cleaned; break }
                    }
                }
                guard let isbn else { continue }
                let bTitle = d["title"] as? String ?? ""
                let names = d["author_name"] as? [String]
                let bAuthor = names?.first ?? ""
                let pubs = d["publisher"] as? [String]
                let publisher = pubs?.first ?? ""
                let cover = "https://covers.openlibrary.org/b/isbn/\(isbn)-M.jpg"
                let lang = detectLanguage(title: bTitle, author: bAuthor)
                results.append(Book(isbn: isbn, title: bTitle, author: bAuthor, publisher: publisher,
                                    coverUrl: cover, purchasePrice: 0, purchaseDate: Date(), language: lang))
            }
            return results
        } catch {
            return []
        }
    }
}
