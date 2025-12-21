import 'package:isbn_book_manager/services/isbn_service.dart';
import 'package:isbn_book_manager/models/api_source.dart';
import 'package:isbn_book_manager/utils/app_logger.dart';

Future<void> main() async {
  const testIsbn = '9789868914766';

  AppLogger.debug('\n╔══════════════════════════════════════════╗');
  AppLogger.debug('║   ISBN API 測試工作 - $testIsbn        ║');
  AppLogger.debug('╚══════════════════════════════════════════╝\n');

  // 測試 1: Google Books
  AppLogger.debug('【測試 1】Google Books API');
  AppLogger.debug('─' * 50);
  try {
    List<ApiSource> sources = [ApiSource.googleBooks];
    final book = await IsbnService.searchByIsbn(
      testIsbn,
      sources: sources,
      onSourceStart: (source) {
        AppLogger.debug('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
      },
    );

    if (book != null) {
      AppLogger.info('✓ 成功\n');
      AppLogger.info('  書名: ${book.title}');
      AppLogger.info('  作者: ${book.author}');
      AppLogger.info('  出版社: ${book.publisher}');
      AppLogger.info('  ISBN: ${book.isbn}');
      AppLogger.info('  封面: ${book.coverUrl != null ? "有" : "無"}\n');
    } else {
      AppLogger.warn('✗ 未返回結果\n');
    }
  } catch (e) {
    AppLogger.error('✗ 錯誤: $e\n', e);
  }

  // 測試 2: Open Library
  AppLogger.debug('【測試 2】Open Library API');
  AppLogger.debug('─' * 50);
  try {
    List<ApiSource> sources = [ApiSource.openLibrary];
    final book = await IsbnService.searchByIsbn(
      testIsbn,
      sources: sources,
      onSourceStart: (source) {
        AppLogger.debug('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
      },
    );

    if (book != null) {
      AppLogger.info('✓ 成功\n');
      AppLogger.info('  書名: ${book.title}');
      AppLogger.info('  作者: ${book.author}');
      AppLogger.info('  出版社: ${book.publisher}');
      AppLogger.info('  ISBN: ${book.isbn}');
      AppLogger.info('  封面: ${book.coverUrl != null ? "有" : "無"}\n');
    } else {
      AppLogger.warn('✗ 未返回結果\n');
    }
  } catch (e) {
    AppLogger.error('✗ 錯誤: $e\n', e);
  }

  // 測試 3: Jike 免費 API
  AppLogger.debug('【測試 3】Jike 免費 API');
  AppLogger.debug('─' * 50);
  try {
    List<ApiSource> sources = [ApiSource.jikeFree];
    final book = await IsbnService.searchByIsbn(
      testIsbn,
      sources: sources,
      onSourceStart: (source) {
        AppLogger.debug('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
      },
    );

    if (book != null) {
      AppLogger.info('✓ 成功\n');
      AppLogger.info('  書名: ${book.title}');
      AppLogger.info('  作者: ${book.author}');
      AppLogger.info('  出版社: ${book.publisher}');
      AppLogger.info('  ISBN: ${book.isbn}');
      AppLogger.info('  封面: ${book.coverUrl != null ? "有" : "無"}\n');
    } else {
      AppLogger.warn('⚠ 未返回結果（此來源不穩定）\n');
    }
  } catch (e) {
    AppLogger.warn('⚠ 錯誤（此來源不穩定，可忽略）: $e\n', e);
  }

  // 測試 4: 依序嘗試 Google + Open Library
  AppLogger.debug('【測試 4】多來源查詢 (Google → Open Library)');
  AppLogger.debug('─' * 50);
  try {
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
        AppLogger.debug('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
      },
    );

    if (book != null) {
      AppLogger.info('✓ 成功\n');
      AppLogger.info(
          '  嘗試順序: ${attemptedSources.map((s) => ApiSourceRegistry.info(s).displayName).join(" → ")}');
      AppLogger.info('  使用第 ${attemptedSources.length} 個來源');
      AppLogger.info('  書名: ${book.title}');
      AppLogger.info('  作者: ${book.author}');
      AppLogger.info('  出版社: ${book.publisher}\n');
    } else {
      AppLogger.warn('✗ 所有來源均失敗\n');
    }
  } catch (e) {
    AppLogger.error('✗ 錯誤: $e\n', e);
  }

  // 測試 5: 所有預設來源
  AppLogger.debug('【測試 5】所有預設來源');
  AppLogger.debug('─' * 50);
  try {
    List<ApiSource> sources = ApiSourceRegistry.defaultEnabled();
    List<ApiSource> attemptedSources = [];

    AppLogger.debug(
        '啟用的來源: ${sources.map((s) => ApiSourceRegistry.info(s).displayName).join(", ")}\n');

    final book = await IsbnService.searchByIsbn(
      testIsbn,
      sources: sources,
      onSourceStart: (source) {
        attemptedSources.add(source);
        AppLogger.debug('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
      },
    );

    if (book != null) {
      AppLogger.info('✓ 成功\n');
      AppLogger.info(
          '  最終使用: ${ApiSourceRegistry.info(attemptedSources.last).displayName}');
      AppLogger.info('  嘗試次數: ${attemptedSources.length}');
      AppLogger.info('  書籍資訊:');
      AppLogger.info('    - 書名: ${book.title}');
      AppLogger.info('    - 作者: ${book.author}');
      AppLogger.info('    - 出版社: ${book.publisher}');
      AppLogger.info('    - ISBN: ${book.isbn}');
      AppLogger.info('    - 封面: ${book.coverUrl != null ? "有" : "無"}\n');
    } else {
      AppLogger.warn('✗ 所有來源均失敗\n');
    }
  } catch (e) {
    AppLogger.error('✗ 錯誤: $e\n', e);
  }

  AppLogger.debug('╔══════════════════════════════════════════╗');
  AppLogger.debug('║         測試完成                        ║');
  AppLogger.debug('╚══════════════════════════════════════════╝\n');
}
