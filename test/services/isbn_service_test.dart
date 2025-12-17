import 'package:flutter_test/flutter_test.dart';
import 'package:isbn_book_manager/services/isbn_service.dart';
import 'package:isbn_book_manager/models/api_source.dart';

void main() {
  group('ISBN 格式驗證測試', () {
    test('ISBN-10 驗證', () {
      expect(IsbnService.isValidIsbn('0140328721'), true);
      expect(IsbnService.isValidIsbn('014032872X'), true);
      expect(IsbnService.isValidIsbn('0140328722'), false); // 無效
    });

    test('ISBN-13 驗證', () {
      expect(IsbnService.isValidIsbn('9780140328721'), true);
      expect(IsbnService.isValidIsbn('9780140328722'), false); // 無效
    });

    test('ISBN 格式化 (ISBN-13)', () {
      final formatted = IsbnService.formatIsbn('9780140328721');
      expect(formatted, '978-0-14032-872-1');
    });

    test('ISBN 移除連字號', () {
      expect(IsbnService.isValidIsbn('978-0-14032-872-1'), true);
    });

    test('ISBN 移除空格', () {
      expect(IsbnService.isValidIsbn('978 0 14032 872 1'), true);
    });

    test('無效 ISBN 長度', () {
      expect(IsbnService.isValidIsbn('123'), false);
      expect(IsbnService.isValidIsbn('12345678901234'), false);
    });

    test('無效 ISBN 包含非數字', () {
      expect(IsbnService.isValidIsbn('978014032872A'), false);
    });

    test('ISBN 正規化', () {
      const variants = [
        '9789868914766',
        '978-9868914766',
        '978 9868 9147 66',
      ];

      for (final variant in variants) {
        final normalized = IsbnService.normalizeIsbn(variant);
        expect(normalized, '9789868914766', reason: '應正規化為純數字');
      }
    });
  });

  group('ISBN API 查詢測試', () {
    const testIsbn = '9789868914766';

    test('Google Books 查詢 - $testIsbn', () async {
      print('\n=== 測試 Google Books API ===');
      print('ISBN: $testIsbn');

      List<ApiSource> sources = [ApiSource.googleBooks];
      ApiSource? usedSource;

      final book = await IsbnService.searchByIsbn(
        testIsbn,
        sources: sources,
        onSourceStart: (source) {
          print('→ 嘗試：${ApiSourceRegistry.info(source).displayName}');
          usedSource = source;
        },
      );

      if (book != null) {
        print('✓ 查詢成功！');
        print('  書名：${book.title}');
        print('  作者：${book.author}');
        print('  出版社：${book.publisher}');
        print('  封面：${book.coverUrl != null ? "有" : "無"}');
        expect(book.isbn, testIsbn);
        expect(book.title.isNotEmpty, true);
      } else {
        print('⚠ Google Books 未返回結果');
      }
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('Open Library 查詢 - $testIsbn', () async {
      print('\n=== 測試 Open Library API ===');
      print('ISBN: $testIsbn');

      List<ApiSource> sources = [ApiSource.openLibrary];
      ApiSource? usedSource;

      final book = await IsbnService.searchByIsbn(
        testIsbn,
        sources: sources,
        onSourceStart: (source) {
          print('→ 嘗試：${ApiSourceRegistry.info(source).displayName}');
          usedSource = source;
        },
      );

      if (book != null) {
        print('✓ 查詢成功！');
        print('  書名：${book.title}');
        print('  作者：${book.author}');
        print('  出版社：${book.publisher}');
        print('  封面：${book.coverUrl != null ? "有" : "無"}');
        expect(book.isbn, testIsbn);
      } else {
        print('⚠ Open Library 未返回結果');
      }
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('Jike 免費 API 查詢 - $testIsbn', () async {
      print('\n=== 測試 Jike 免費 API ===');
      print('ISBN: $testIsbn');

      List<ApiSource> sources = [ApiSource.jikeFree];
      ApiSource? usedSource;

      final book = await IsbnService.searchByIsbn(
        testIsbn,
        sources: sources,
        onSourceStart: (source) {
          print('→ 嘗試：${ApiSourceRegistry.info(source).displayName}');
          usedSource = source;
        },
      );

      if (book != null) {
        print('✓ 查詢成功！');
        print('  書名：${book.title}');
        print('  作者：${book.author}');
        print('  出版社：${book.publisher}');
        print('  封面：${book.coverUrl != null ? "有" : "無"}');
      } else {
        print('⚠ Jike 免費 API 未返回結果（不穩定來源，可正常）');
      }
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('Google + Open Library 依序嘗試', () async {
      print('\n=== 多來源查詢 (Google → Open Library) ===');
      print('ISBN: $testIsbn');

      List<ApiSource> sources = [
        ApiSource.googleBooks,
        ApiSource.openLibrary,
      ];
      List<ApiSource> attemptedSources = [];

      final book = await IsbnService.searchByIsbn(
        testIsbn,
        sources: sources,
        onSourceStart: (source) {
          attemptedSources.add(source);
          print('→ 嘗試：${ApiSourceRegistry.info(source).displayName}');
        },
      );

      expect(book, isNotNull);
      if (book != null) {
        print('✓ 成功查詢！');
        print(
            '  嘗試順序：${attemptedSources.map((s) => ApiSourceRegistry.info(s).displayName).join(" → ")}');
        print('  使用第 ${attemptedSources.length} 個來源');
        print('  書籍：${book.title}');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('所有預設來源', () async {
      print('\n=== 多來源查詢 (所有預設來源) ===');
      print('ISBN: $testIsbn');

      List<ApiSource> sources = ApiSourceRegistry.defaultEnabled();
      List<ApiSource> attemptedSources = [];

      print(
          '已啟用來源：${sources.map((s) => ApiSourceRegistry.info(s).displayName).join(", ")}');

      final book = await IsbnService.searchByIsbn(
        testIsbn,
        sources: sources,
        onSourceStart: (source) {
          attemptedSources.add(source);
          print('→ 嘗試：${ApiSourceRegistry.info(source).displayName}');
        },
      );

      expect(book, isNotNull);
      if (book != null) {
        print('✓ 成功查詢！');
        print(
            '  最終使用：${ApiSourceRegistry.info(attemptedSources.last).displayName}');
        print('  書籍資訊：');
        print('    - 書名：${book.title}');
        print('    - 作者：${book.author}');
        print('    - 出版社：${book.publisher}');
        print('    - ISBN：${book.isbn}');
      }
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}
