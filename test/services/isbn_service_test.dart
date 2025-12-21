import 'package:flutter_test/flutter_test.dart';
import '../test_helper.dart';
import 'package:isbn_book_manager/services/isbn_service.dart';
import 'package:isbn_book_manager/models/api_source.dart';
import 'package:isbn_book_manager/utils/app_logger.dart';

void main() {
  setUpAll(() {
    initTestDatabase();
  });
  group('ISBN 格式驗證測試', () {
    test('ISBN-10 驗證', () {
      AppLogger.debug(
          'normalize(013603599X) -> ${IsbnService.normalizeIsbn('013603599X')}');
      AppLogger.debug(
          'isValidIsbn10 -> ${IsbnService.isValidIsbn10('013603599X')}');
      AppLogger.debug(
          'isValidIsbn -> ${IsbnService.isValidIsbn('013603599X')}');
      expect(IsbnService.isValidIsbn('013603599X'), true);
      expect(IsbnService.isValidIsbn('9780136035992'), true);
      expect(IsbnService.isValidIsbn('0136035991'), false); // 無效
    });

    test('ISBN-13 驗證', () {
      expect(IsbnService.isValidIsbn('9780136035992'), true);
      expect(IsbnService.isValidIsbn('9780136035993'), false); // 無效
    });

    test('ISBN 格式化 (ISBN-13)', () {
      final formatted = IsbnService.formatIsbn('9780136035992');
      expect(formatted, '978-0-13603-599-2');
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
      AppLogger.debug('\n=== 測試 Google Books API ===');
      AppLogger.debug('ISBN: $testIsbn');

      List<ApiSource> sources = [ApiSource.googleBooks];

      final book = await IsbnService.searchByIsbn(
        testIsbn,
        sources: sources,
        onSourceStart: (source) {
          AppLogger.debug('→ 嘗試：${ApiSourceRegistry.info(source).displayName}');
        },
      );

      if (book != null) {
        AppLogger.info('✓ 查詢成功！');
        AppLogger.info('  書名：${book.title}');
        AppLogger.info('  作者：${book.author}');
        AppLogger.info('  出版社：${book.publisher}');
        AppLogger.info('  封面：${book.coverUrl != null ? "有" : "無"}');
        expect(book.isbn, testIsbn);
        expect(book.title.isNotEmpty, true);
      } else {
        AppLogger.warn('⚠ Google Books 未返回結果');
      }
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('Open Library 查詢 - $testIsbn', () async {
      AppLogger.debug('\n=== 測試 Open Library API ===');
      AppLogger.debug('ISBN: $testIsbn');

      List<ApiSource> sources = [ApiSource.openLibrary];

      final book = await IsbnService.searchByIsbn(
        testIsbn,
        sources: sources,
        onSourceStart: (source) {
          AppLogger.debug('→ 嘗試：${ApiSourceRegistry.info(source).displayName}');
        },
      );

      if (book != null) {
        AppLogger.info('✓ 查詢成功！');
        AppLogger.info('  書名：${book.title}');
        AppLogger.info('  作者：${book.author}');
        AppLogger.info('  出版社：${book.publisher}');
        AppLogger.info('  封面：${book.coverUrl != null ? "有" : "無"}');
        expect(book.isbn, testIsbn);
      } else {
        AppLogger.warn('⚠ Open Library 未返回結果');
      }
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('Jike 免費 API 查詢 - $testIsbn', () async {
      AppLogger.debug('\n=== 測試 Jike 免費 API ===');
      AppLogger.debug('ISBN: $testIsbn');

      List<ApiSource> sources = [ApiSource.jikeFree];

      final book = await IsbnService.searchByIsbn(
        testIsbn,
        sources: sources,
        onSourceStart: (source) {
          AppLogger.debug('→ 嘗試：${ApiSourceRegistry.info(source).displayName}');
        },
      );

      if (book != null) {
        AppLogger.info('✓ 查詢成功！');
        AppLogger.info('  書名：${book.title}');
        AppLogger.info('  作者：${book.author}');
        AppLogger.info('  出版社：${book.publisher}');
        AppLogger.info('  封面：${book.coverUrl != null ? "有" : "無"}');
      } else {
        AppLogger.warn('⚠ Jike 免費 API 未返回結果（不穩定來源，可正常）');
      }
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('Google + Open Library 依序嘗試', () async {
      AppLogger.debug('\n=== 多來源查詢 (Google → Open Library) ===');
      AppLogger.debug('ISBN: $testIsbn');

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
          AppLogger.debug('→ 嘗試：${ApiSourceRegistry.info(source).displayName}');
        },
      );

      expect(book, isNotNull);
      if (book != null) {
        AppLogger.info('✓ 成功查詢！');
        AppLogger.info(
            '  嘗試順序：${attemptedSources.map((s) => ApiSourceRegistry.info(s).displayName).join(" → ")}');
        AppLogger.info('  使用第 ${attemptedSources.length} 個來源');
        AppLogger.info('  書籍：${book.title}');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('所有預設來源', () async {
      AppLogger.debug('\n=== 多來源查詢 (所有預設來源) ===');
      AppLogger.debug('ISBN: $testIsbn');

      List<ApiSource> sources = ApiSourceRegistry.defaultEnabled();
      List<ApiSource> attemptedSources = [];

      AppLogger.debug(
          '已啟用來源：${sources.map((s) => ApiSourceRegistry.info(s).displayName).join(", ")}');

      final book = await IsbnService.searchByIsbn(
        testIsbn,
        sources: sources,
        onSourceStart: (source) {
          attemptedSources.add(source);
          AppLogger.debug('→ 嘗試：${ApiSourceRegistry.info(source).displayName}');
        },
      );

      expect(book, isNotNull);
      if (book != null) {
        AppLogger.info('✓ 成功查詢！');
        AppLogger.info(
            '  最終使用：${ApiSourceRegistry.info(attemptedSources.last).displayName}');
        AppLogger.info('  書籍資訊：');
        AppLogger.info('    - 書名：${book.title}');
        AppLogger.info('    - 作者：${book.author}');
        AppLogger.info('    - 出版社：${book.publisher}');
        AppLogger.info('    - ISBN：${book.isbn}');
      }
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}
