import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/book.dart';
import '../models/api_source.dart';

class IsbnService {
  static const String openLibraryBaseUrl = 'https://openlibrary.org/api/books';
  // 可選：外部 Lexile API 基底網址與金鑰，未設定時跳過呼叫
  static const String lexileApiBase = String.fromEnvironment('LEXILE_API_BASE');
  static const String lexileApiKey = String.fromEnvironment('LEXILE_API_KEY');
  static const Duration _timeout = Duration(seconds: 12);

  /// 多來源查詢，依序嘗試來源並在每次切換時呼叫 onSourceStart
  static Future<Book?> searchByIsbn(
    String rawIsbn, {
    List<ApiSource>? sources,
    ValueChanged<ApiSource>? onSourceStart,
    http.Client? client,
  }) async {
    final isbn = normalizeIsbn(rawIsbn);

    if (!_isValidIsbn(isbn)) {
      if (isEan13ButNotIsbn(isbn)) {
        throw Exception('請掃描 ISBN 條碼，這個是 EAN');
      }
      throw Exception('無效的 ISBN 格式');
    }

    final activeSources = (sources == null || sources.isEmpty)
      ? ApiSourceRegistry.defaultEnabled()
      : sources;

    // 使用可注入的 http client（若未提供則自行建立並在結束時關閉），以利測試時注入 MockClient
    final bool _shouldCloseClient = client == null;
    final http.Client _client = client ?? http.Client();

    try {
      for (final source in activeSources) {
        onSourceStart?.call(source);
        Book? result;
        switch (source) {
          case ApiSource.googleBooks:
            result = await _searchGoogleBooks(isbn, _client);
            break;
          case ApiSource.openLibrary:
            result = await _searchOpenLibrary(isbn, _client);
            break;
          case ApiSource.wikipedia:
            result = await _searchWikipedia(isbn, _client);
            break;
          case ApiSource.jikeFree:
            result = await _searchJikeFree(isbn, _client);
            break;
        }
        if (result != null) return result;
      }
      return null;
    } finally {
      if (_shouldCloseClient) {
        try {
          _client.close();
        } catch (_) {}
      }
    }
  }

  static Future<Book?> _searchOpenLibrary(String isbn, http.Client client) async {
    try {
      final response = await client
          .get(Uri.parse('$openLibraryBaseUrl?bibkeys=ISBN:$isbn&format=json'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final key = 'ISBN:$isbn';

        if (data.containsKey(key)) {
          final bookData = data[key];
          final book = _parseOpenLibraryBook(bookData, isbn);
          if (book != null) {
            // 檢測語言並獲取 Lexile 分數（如果是英文書）
            final language = _detectLanguage(book.title, book.author);
            int? lexileScore;
            if (language == 'en') {
              lexileScore = await _fetchLexileScore(isbn, book.title);
            }
            return book.copyWith(language: language, lexileScore: lexileScore);
          }
        }
      }
      return null;
    } catch (e, st) {
      AppLogger.warn('Open Library 查詢錯誤: $e', e, st);
      return null;
    }
  }

  static Future<Book?> _searchGoogleBooks(String isbn, http.Client client) async {
    try {
      final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn');
      final response = await client.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>?;
        if (items == null || items.isEmpty) return null;

        final volume = items.first['volumeInfo'];
        if (volume == null) return null;

        final title = volume['title'] ?? '未知標題';
        final authors = volume['authors'] as List<dynamic>?;
        final author = authors != null && authors.isNotEmpty
            ? authors.first.toString()
            : '未知作者';
        final publisher = volume['publisher'] ?? '未知出版社';
        final coverUrl = volume['imageLinks'] != null
            ? volume['imageLinks']['thumbnail'] ??
                volume['imageLinks']['smallThumbnail']
            : null;

        // 從 Google Books 數據中獲取語言和 Lexile 分數
        final language = volume['language'] ?? _detectLanguage(title, author);
        int? lexileScore;
        if (language == 'en') {
          lexileScore = await _fetchLexileScore(isbn, title);
        }

        return Book(
          isbn: isbn,
          title: title,
          author: author,
          publisher: publisher,
          coverUrl: coverUrl,
          purchasePrice: 0.0,
          purchaseDate: DateTime.now(),
          language: language,
          lexileScore: lexileScore,
        );
      }
      return null;
    } catch (e, st) {
      AppLogger.warn('Google Books 查詢錯誤: $e', e, st);
      return null;
    }
  }

  /// 以書名與（可選）作者查詢 Google Books
  /// - title: 書名（必要）
  /// - author: 作者（可選）
  /// - langRestrict: 語言限制（例如 'en'、'zh'），可選
  /// - maxResults: 回傳數量，預設 10
  /// 回傳符合條件且帶有 ISBN 的書籍清單
  static Future<List<Book>> searchByTitleAuthor(
    String title, {
    String? author,
    String? langRestrict,
    int maxResults = 10,
  }) async {
    try {
      final inputTitle = title.trim();
      final inputAuthor = author?.trim();
      // 若偵測到中文關鍵字且未指定 langRestrict，預設限制 zh
      final autoLangRestrict = langRestrict ??
          (RegExp(r'[\u4e00-\u9fa5]').hasMatch(inputTitle) ? 'zh' : null);

      // 先查 Google Books
      final googleResults = await _searchGoogleByTitleAuthor(
        inputTitle,
        author: inputAuthor,
        langRestrict: autoLangRestrict,
        maxResults: maxResults,
      );

      // 再查 Open Library（可補到更多 ISBN）
      final olResults = await _searchOpenLibraryByTitleAuthor(
        inputTitle,
        author: inputAuthor,
        maxResults: maxResults,
      );

      // 合併並依 ISBN 去重
      final byIsbn = <String, Book>{};
      for (final b in [...googleResults, ...olResults]) {
        final key = normalizeIsbn(b.isbn);
        if (key.isNotEmpty) {
          byIsbn[key] = b;
        }
      }
      return byIsbn.values.toList();
    } catch (e, st) {
      AppLogger.warn('書名查詢錯誤: $e', e, st);
      return <Book>[];
    }
  }

  static Future<List<Book>> _searchGoogleByTitleAuthor(
    String title, {
    String? author,
    String? langRestrict,
    int maxResults = 10,
  }) async {
    final String queryParts = [
      if (title.trim().isNotEmpty) 'intitle:${title.trim()}',
      if (author != null && author.trim().isNotEmpty)
        'inauthor:${author.trim()}',
    ].join('+');

    final params = <String, String>{
      'q': queryParts.isEmpty ? title : queryParts,
      'printType': 'books',
      // 使用 full 以確保拿到 industryIdentifiers（ISBN）
      'projection': 'full',
      'orderBy': 'relevance',
      'maxResults': maxResults.toString(),
    };
    if (langRestrict != null && langRestrict.isNotEmpty) {
      params['langRestrict'] = langRestrict;
    }

    Future<List<dynamic>> fetchItems(Map<String, String> p) async {
      final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', p);
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return const [];
      final data = jsonDecode(response.body);
      final items = data['items'] as List<dynamic>?;
      return items ?? const [];
    }

    // 第一次用 intitle/inauthor 查
    var items = await fetchItems(params);
    // 若無結果，改用原始關鍵字（不加 intitle）重試
    if (items.isEmpty) {
      final retryParams = Map<String, String>.from(params);
      retryParams['q'] = title.trim();
      items = await fetchItems(retryParams);
    }
    if (items.isEmpty) return <Book>[];

    final results = <Book>[];
    for (final item in items) {
      final volume = item['volumeInfo'];
      if (volume == null) continue;

      // 嘗試從識別碼中取得 ISBN（優先 13，其次 10）
      String? isbn;
      final ids = volume['industryIdentifiers'] as List<dynamic>?;
      if (ids != null) {
        for (final id in ids) {
          if (id is Map && id['type'] == 'ISBN_13') {
            isbn = (id['identifier'] as String?)?.replaceAll('-', '');
            break;
          }
        }
        if (isbn == null) {
          for (final id in ids) {
            if (id is Map && id['type'] == 'ISBN_10') {
              isbn = (id['identifier'] as String?)?.replaceAll('-', '');
              break;
            }
          }
        }
      }

      // 若無 ISBN，略過（本系統資料模型要求有 ISBN）
      if (isbn == null || isbn.isEmpty) continue;

      final bookTitle = volume['title'] ?? '未知標題';
      final authors = volume['authors'] as List<dynamic>?;
      final bookAuthor = (authors != null && authors.isNotEmpty)
          ? authors.first.toString()
          : '未知作者';
      final publisher = volume['publisher'] ?? '未知出版社';
      final coverUrl = volume['imageLinks'] != null
          ? volume['imageLinks']['thumbnail'] ??
              volume['imageLinks']['smallThumbnail']
          : null;
      final language =
          volume['language'] ?? _detectLanguage(bookTitle, bookAuthor);

      results.add(
        Book(
          isbn: isbn,
          title: bookTitle,
          author: bookAuthor,
          publisher: publisher,
          coverUrl: coverUrl,
          purchasePrice: 0.0,
          purchaseDate: DateTime.now(),
          language: language,
        ),
      );
    }
    return results;
  }

  static Future<List<Book>> _searchOpenLibraryByTitleAuthor(
    String title, {
    String? author,
    int maxResults = 10,
  }) async {
    try {
      final params = <String, String>{
        'title': title,
        if (author != null && author.isNotEmpty) 'author': author,
        'limit': maxResults.toString(),
      };
      final uri = Uri.https('openlibrary.org', '/search.json', params);
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return <Book>[];

      final data = jsonDecode(response.body);
      final docs = data['docs'] as List<dynamic>?;
      if (docs == null || docs.isEmpty) return <Book>[];

      final results = <Book>[];
      for (final doc in docs) {
        final isbns =
            (doc['isbn'] as List?)?.cast<String>() ?? const <String>[];
        // 優先找有效的 ISBN-13（978/979），其次 ISBN-10
        String? isbn;
        for (final id in isbns) {
          final cleaned = normalizeIsbn(id);
          if (cleaned.length == 13 && isValidIsbn13(cleaned)) {
            isbn = cleaned;
            break;
          }
        }
        if (isbn == null) {
          for (final id in isbns) {
            final cleaned = normalizeIsbn(id);
            if (cleaned.length == 10 && isValidIsbn10(cleaned)) {
              isbn = cleaned;
              break;
            }
          }
        }
        if (isbn == null) continue; // 沒有可用 ISBN 則略過

        final bookTitle = (doc['title'] as String?) ?? '未知標題';
        final authorNames = (doc['author_name'] as List?)?.cast<String>();
        final bookAuthor = (authorNames != null && authorNames.isNotEmpty)
            ? authorNames.first
            : '未知作者';
        final publishers = (doc['publisher'] as List?)?.cast<String>();
        final publisher = (publishers != null && publishers.isNotEmpty)
            ? publishers.first
            : '未知出版社';
        final coverUrl = 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg';
        final language = _detectLanguage(bookTitle, bookAuthor);

        results.add(
          Book(
            isbn: isbn,
            title: bookTitle,
            author: bookAuthor,
            publisher: publisher,
            coverUrl: coverUrl,
            purchasePrice: 0.0,
            purchaseDate: DateTime.now(),
            language: language,
          ),
        );
      }
      return results;
    } catch (e, st) {
      AppLogger.warn('Open Library 書名查詢錯誤: $e', e, st);
      return <Book>[];
    }
  }

  static Future<Book?> _searchJikeFree(String isbn, http.Client client) async {
    try {
      final response = await client
          .get(Uri.parse('https://api.jike.xyz/situ/book/isbn/$isbn'))
          .timeout(const Duration(seconds: 8)); // 縮短超時，此來源較不穩定

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final payload = data['data'] ?? data;
      if (payload == null) return null;

      final title = payload['title'] ?? '未知標題';
      final authorRaw = payload['author'] ?? payload['authors'];
      String author = '未知作者';
      if (authorRaw is List && authorRaw.isNotEmpty) {
        author = authorRaw.first.toString();
      } else if (authorRaw is String && authorRaw.isNotEmpty) {
        author = authorRaw;
      }
      final publisher = payload['publisher'] ?? '未知出版社';
      final coverUrl = payload['images']?['large'] ?? payload['image'];

      // Jike 通常提供中文書籍，所以假設語言為中文
      const language = 'zh';

      return Book(
        isbn: isbn,
        title: title,
        author: author,
        publisher: publisher,
        coverUrl: coverUrl,
        purchasePrice: 0.0,
        purchaseDate: DateTime.now(),
        language: language,
      );
    } catch (e, st) {
      AppLogger.warn('Jike 免費 API 查詢錯誤: $e', e, st);
      return null;
    }
  }

 

  static Future<Book?> _searchWikipedia(String isbn, http.Client client) async {
    try {
      // 使用 ISBN 和可能的書名搜尋
      final searchQuery = 'ISBN $isbn';
      final response = await client
          .get(Uri.parse(
              'https://en.wikipedia.org/w/api.php?'
              'action=query&list=search&srsearch=${Uri.encodeComponent(searchQuery)}&format=json&srprop=snippet'))
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final search = data['query']?['search'];
      if (search == null || (search as List).isEmpty) return null;

      // 從搜尋結果中取得第一筆並嘗試提取資訊
      final firstResult = search.first;
      final snippet = firstResult['snippet'] as String? ?? '';

      // 這是從 Wikipedia 搜尋結果中提取基本資訊的簡單實現
      // 實際上 Wikipedia 通常包含書籍訊息在摘要中
      if (snippet.isNotEmpty) {
        return Book(
          isbn: isbn,
          title: firstResult['title'] ?? '未知標題',
          author: '未知作者',
          publisher: '未知出版社',
          coverUrl: null,
          purchasePrice: 0.0,
          purchaseDate: DateTime.now(),
        );
      }
      return null;
    } catch (e, st) {
      AppLogger.warn('Wikipedia 查詢錯誤: $e', e, st);
      return null;
    }
  }

  static Book? _parseOpenLibraryBook(dynamic data, String isbn) {
    try {
      final title = data['title'] ?? '未知標題';
      final author = (data['authors'] != null && data['authors'].isNotEmpty)
          ? data['authors'][0]['name']
          : '未知作者';
      final publisher =
          (data['publishers'] != null && data['publishers'].isNotEmpty)
              ? data['publishers'][0]['name']
              : '未知出版社';
      final coverUrl = data['cover'] != null ? data['cover']['large'] : null;

      return Book(
        isbn: isbn,
        title: title,
        author: author,
        publisher: publisher,
        coverUrl: coverUrl,
        purchasePrice: 0.0,
        purchaseDate: DateTime.now(),
      );
    } catch (e, st) {
      AppLogger.warn('Open Library 解析錯誤: $e', e, st);
      return null;
    }
  }

  static bool _isValidIsbn(String isbn) {
    final cleaned = normalizeIsbn(isbn);

    if (cleaned.length == 10) {
      return isValidIsbn10(cleaned);
    }

    if (cleaned.length == 13) {
      return isValidIsbn13(cleaned);
    }

    return false;
  }

  /// 檢查是否為有效的 EAN-13 條碼（但非書籍 ISBN）
  static bool isEan13ButNotIsbn(String code) {
    final cleaned = normalizeIsbn(code);
    if (cleaned.length != 13) return false;
    if (cleaned.startsWith('978') || cleaned.startsWith('979')) return false;

    // 驗證 EAN-13 校驗碼
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(cleaned[i]);
      sum += i % 2 == 0 ? digit : digit * 3;
    }
    final checkDigit = int.parse(cleaned[12]);
    final expected = (10 - (sum % 10)) % 10;
    return checkDigit == expected;
  }

  /// 嚴格的 ISBN-10 檢查碼驗證（參考 isbnlib 做法）
  static bool isValidIsbn10(String isbn) {
    if (!RegExp(r'^[0-9]{9}[0-9X]$').hasMatch(isbn)) return false;

    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(isbn[i]) * (10 - i);
    }

    final checkDigit = isbn[9];
    final expected = (11 - (sum % 11)) % 11;
    final expectedChar = expected == 10 ? 'X' : expected.toString();

    return checkDigit == expectedChar;
  }

  /// 嚴格的 ISBN-13 檢查碼驗證（參考 isbnlib 做法）
  static bool isValidIsbn13(String isbn) {
    if (!RegExp(r'^[0-9]{13}$').hasMatch(isbn)) return false;

    // ISBN-13 必須以 978 或 979 開頭（書籍標準）
    if (!isbn.startsWith('978') && !isbn.startsWith('979')) {
      return false;
    }

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(isbn[i]);
      sum += i % 2 == 0 ? digit : digit * 3;
    }

    final checkDigit = int.parse(isbn[12]);
    final expected = (10 - (sum % 10)) % 10;

    return checkDigit == expected;
  }

  static String normalizeIsbn(String isbn) {
    return isbn.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
  }

  static String formatIsbn(String isbn) {
    final cleaned = normalizeIsbn(isbn);
    if (cleaned.length == 13) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 4)}-${cleaned.substring(4, 9)}-${cleaned.substring(9, 12)}-${cleaned.substring(12)}';
    }
    return cleaned;
  }

  /// 從文字中提取所有可能的 ISBN（參考 isbnlib 的 get_isbnlike 做法）
  /// 例如輸入 "ISBN 978-0-446-31078-9 by Author" 會提取 "9780446310789"
  static List<String> extractIsbnFromText(String text) {
    final isbnPattern = RegExp(
        r'\b(?:ISBN)?[\s-]?(?=[-0-9X]{10}(?:[-0-9X]{3})?(?:\D|$))(?:97[89][-\s]?)?[0-9]{1,5}[-\s]?(?:[0-9]+[-\s]?){2}[0-9X]');
    final matches = isbnPattern.allMatches(text);

    final extracted = <String>[];
    for (final match in matches) {
      final cleaned = normalizeIsbn(match.group(0) ?? '');
      if (cleaned.isNotEmpty && _isValidIsbn(cleaned)) {
        extracted.add(cleaned);
      }
    }

    return extracted;
  }

  /// 對外公開的 ISBN 驗證入口（沿用既有呼叫點）
  static bool isValidIsbn(String isbn) {
    return _isValidIsbn(isbn);
  }

  /// 檢測書籍語言（簡單啟發式方法）
  /// 返回語言代碼：'en' for English, 'zh' for Chinese, 'other' for others
  static String _detectLanguage(String title, String author) {
    // 檢查是否包含中文字符
    final chinesePattern = RegExp(r'[\u4e00-\u9fa5]');
    if (chinesePattern.hasMatch(title) || chinesePattern.hasMatch(author)) {
      return 'zh';
    }

    // 檢查是否包含日文字符
    final japanesePattern = RegExp(r'[\u3040-\u309f\u30a0-\u30ff]');
    if (japanesePattern.hasMatch(title) || japanesePattern.hasMatch(author)) {
      return 'ja';
    }

    // 默認假設為英文（基於 ISBN 數據庫主要是英文和中文）
    return 'en';
  }

  /// 從 Lexile API 獲取英文書籍的藍思值
  /// Lexile 數據庫：https://www.lexile.com/
  /// 使用 ISBN 查詢（需要遵守使用條款）
  static Future<int?> _fetchLexileScore(String isbn, String title) async {
    try {
      // 嘗試從 Lexile API 獲取數據
      // 注意：Lexile 沒有公開的免費 API，所以使用替代方法
      // 1) 優先嘗試外部可配置的 Lexile 來源（若已設定）
      final external = await _fetchLexileFromExternal(isbn, title);
      if (external != null) return external;

      // 2) 回退到 Open Library 中可能包含的 Lexile 分類
      return await _fetchLexileFromOpenLibrary(isbn);
    } catch (e, st) {
      AppLogger.warn('Lexile 查詢錯誤: $e', e, st);
      return null;
    }
  }

  /// 從外部可配置 API 獲取 Lexile 分數，成功則回傳分數，未配置或失敗回傳 null
    static Future<int?> _fetchLexileFromExternal(
      String isbn, String title) async {
    if (lexileApiBase.isEmpty) return null;

    try {
      final uri = Uri.parse(lexileApiBase).replace(
        queryParameters: {
          'isbn': isbn,
          'title': title,
        },
      );

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (lexileApiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer $lexileApiKey';
      }

      final response = await http.get(uri, headers: headers).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      // 支援多種鍵名：lexile、lexileScore、lexile_score
      final dynamic raw =
          data['lexile'] ?? data['lexileScore'] ?? data['lexile_score'];
      if (raw == null) return null;

      if (raw is int) return raw;
      if (raw is String) {
        final match = RegExp(r'(\d+)').firstMatch(raw);
        if (match != null) return int.tryParse(match.group(1) ?? '');
      }
      return null;
    } catch (e, st) {
      AppLogger.warn('外部 Lexile API 查詢錯誤: $e', e, st);
      return null;
    }
  }

  /// 從 Open Library 獲取 Lexile 分數（如果可用）
  static Future<int?> _fetchLexileFromOpenLibrary(String isbn) async {
    try {
      final response = await http
          .get(Uri.parse('$openLibraryBaseUrl?bibkeys=ISBN:$isbn&format=json'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final key = 'ISBN:$isbn';

        if (data.containsKey(key)) {
          final bookData = data[key];
          final classifications = bookData['classifications'] as Map?;

          if (classifications != null) {
            // 檢查是否有 Lexile 分類
            final lexileData = classifications['lexile'];
            if (lexileData is String && lexileData.isNotEmpty) {
              // Lexile 通常是格式 "LEXILE: 850L" 或 "850"
              final lexileMatch = RegExp(r'(\d+)').firstMatch(lexileData);
              if (lexileMatch != null) {
                return int.tryParse(lexileMatch.group(1) ?? '');
              }
            }
          }
        }
      }
      return null;
    } catch (e, st) {
      AppLogger.warn('Open Library Lexile 查詢錯誤: $e', e, st);
      return null;
    }
  }
}
