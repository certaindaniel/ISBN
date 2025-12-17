import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/book.dart';
import '../models/api_source.dart';

class IsbnService {
  static const String openLibraryBaseUrl = 'https://openlibrary.org/api/books';
  static const Duration _timeout = Duration(seconds: 12);

  /// 多來源查詢，依序嘗試來源並在每次切換時呼叫 onSourceStart
  static Future<Book?> searchByIsbn(
    String rawIsbn, {
    List<ApiSource>? sources,
    ValueChanged<ApiSource>? onSourceStart,
  }) async {
    final isbn = normalizeIsbn(rawIsbn);

    if (!_isValidIsbn(isbn)) {
      throw Exception('無效的 ISBN 格式');
    }

    final activeSources = (sources == null || sources.isEmpty)
        ? ApiSourceRegistry.defaultEnabled()
        : sources;

    for (final source in activeSources) {
      onSourceStart?.call(source);
      Book? result;
      switch (source) {
        case ApiSource.googleBooks:
          result = await _searchGoogleBooks(isbn);
          break;
        case ApiSource.openLibrary:
          result = await _searchOpenLibrary(isbn);
          break;
        case ApiSource.wikipedia:
          result = await _searchWikipedia(isbn);
          break;
        case ApiSource.jikeFree:
          result = await _searchJikeFree(isbn);
          break;
      }
      if (result != null) return result;
    }

    return null;
  }

  static Future<Book?> _searchOpenLibrary(String isbn) async {
    try {
      final response = await http
          .get(
            Uri.parse('$openLibraryBaseUrl?bibkeys=ISBN:$isbn&format=json'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final key = 'ISBN:$isbn';

        if (data.containsKey(key)) {
          final bookData = data[key];
          return _parseOpenLibraryBook(bookData, isbn);
        }
      }
      return null;
    } catch (e) {
      print('Open Library 查詢錯誤: $e');
      return null;
    }
  }

  static Future<Book?> _searchGoogleBooks(String isbn) async {
    try {
      final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn',
      );
      final response = await http.get(url).timeout(_timeout);

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

        return Book(
          isbn: isbn,
          title: title,
          author: author,
          publisher: publisher,
          coverUrl: coverUrl,
          purchasePrice: 0.0,
          purchaseDate: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      print('Google Books 查詢錯誤: $e');
      return null;
    }
  }

  static Future<Book?> _searchJikeFree(String isbn) async {
    try {
      final response = await http
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

      return Book(
        isbn: isbn,
        title: title,
        author: author,
        publisher: publisher,
        coverUrl: coverUrl,
        purchasePrice: 0.0,
        purchaseDate: DateTime.now(),
      );
    } catch (e) {
      print('Jike 免費 API 查詢錯誤: $e');
      return null;
    }
  }

  static Future<Book?> _searchWikipedia(String isbn) async {
    try {
      // 使用 ISBN 和可能的書名搜尋
      final searchQuery = 'ISBN $isbn';
      final response = await http
          .get(
            Uri.parse(
              'https://en.wikipedia.org/w/api.php?'
              'action=query&list=search&srsearch=${Uri.encodeComponent(searchQuery)}&format=json&srprop=snippet',
            ),
          )
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
    } catch (e) {
      print('Wikipedia 查詢錯誤: $e');
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
    } catch (e) {
      print('Open Library 解析錯誤: $e');
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
}
