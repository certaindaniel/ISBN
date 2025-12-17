import 'package:isbn_book_manager/services/isbn_service.dart';
import 'package:isbn_book_manager/models/api_source.dart';

Future<void> main() async {
  const testIsbn = '9789868914766';

  print('\n╔══════════════════════════════════════════╗');
  print('║   ISBN API 測試工作 - $testIsbn        ║');
  print('╚══════════════════════════════════════════╝\n');

  // 測試 1: Google Books
  print('【測試 1】Google Books API');
  print('─' * 50);
  try {
    List<ApiSource> sources = [ApiSource.googleBooks];
    final book = await IsbnService.searchByIsbn(
      testIsbn,
      sources: sources,
      onSourceStart: (source) {
        print('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
      },
    );

    if (book != null) {
      print('✓ 成功\n');
      print('  書名: ${book.title}');
      print('  作者: ${book.author}');
      print('  出版社: ${book.publisher}');
      print('  ISBN: ${book.isbn}');
      print('  封面: ${book.coverUrl != null ? "有" : "無"}\n');
    } else {
      print('✗ 未返回結果\n');
    }
  } catch (e) {
    print('✗ 錯誤: $e\n');
  }

  // 測試 2: Open Library
  print('【測試 2】Open Library API');
  print('─' * 50);
  try {
    List<ApiSource> sources = [ApiSource.openLibrary];
    final book = await IsbnService.searchByIsbn(
      testIsbn,
      sources: sources,
      onSourceStart: (source) {
        print('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
      },
    );

    if (book != null) {
      print('✓ 成功\n');
      print('  書名: ${book.title}');
      print('  作者: ${book.author}');
      print('  出版社: ${book.publisher}');
      print('  ISBN: ${book.isbn}');
      print('  封面: ${book.coverUrl != null ? "有" : "無"}\n');
    } else {
      print('✗ 未返回結果\n');
    }
  } catch (e) {
    print('✗ 錯誤: $e\n');
  }

  // 測試 3: Jike 免費 API
  print('【測試 3】Jike 免費 API');
  print('─' * 50);
  try {
    List<ApiSource> sources = [ApiSource.jikeFree];
    final book = await IsbnService.searchByIsbn(
      testIsbn,
      sources: sources,
      onSourceStart: (source) {
        print('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
      },
    );

    if (book != null) {
      print('✓ 成功\n');
      print('  書名: ${book.title}');
      print('  作者: ${book.author}');
      print('  出版社: ${book.publisher}');
      print('  ISBN: ${book.isbn}');
      print('  封面: ${book.coverUrl != null ? "有" : "無"}\n');
    } else {
      print('⚠ 未返回結果（此來源不穩定）\n');
    }
  } catch (e) {
    print('⚠ 錯誤（此來源不穩定，可忽略）: $e\n');
  }

  // 測試 4: 依序嘗試 Google + Open Library
  print('【測試 4】多來源查詢 (Google → Open Library)');
  print('─' * 50);
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
        print('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
      },
    );

    if (book != null) {
      print('✓ 成功\n');
      print(
          '  嘗試順序: ${attemptedSources.map((s) => ApiSourceRegistry.info(s).displayName).join(" → ")}');
      print('  使用第 ${attemptedSources.length} 個來源');
      print('  書名: ${book.title}');
      print('  作者: ${book.author}');
      print('  出版社: ${book.publisher}\n');
    } else {
      print('✗ 所有來源均失敗\n');
    }
  } catch (e) {
    print('✗ 錯誤: $e\n');
  }

  // 測試 5: 所有預設來源
  print('【測試 5】所有預設來源');
  print('─' * 50);
  try {
    List<ApiSource> sources = ApiSourceRegistry.defaultEnabled();
    List<ApiSource> attemptedSources = [];

    print(
        '啟用的來源: ${sources.map((s) => ApiSourceRegistry.info(s).displayName).join(", ")}\n');

    final book = await IsbnService.searchByIsbn(
      testIsbn,
      sources: sources,
      onSourceStart: (source) {
        attemptedSources.add(source);
        print('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
      },
    );

    if (book != null) {
      print('✓ 成功\n');
      print(
          '  最終使用: ${ApiSourceRegistry.info(attemptedSources.last).displayName}');
      print('  嘗試次數: ${attemptedSources.length}');
      print('  書籍資訊:');
      print('    - 書名: ${book.title}');
      print('    - 作者: ${book.author}');
      print('    - 出版社: ${book.publisher}');
      print('    - ISBN: ${book.isbn}');
      print('    - 封面: ${book.coverUrl != null ? "有" : "無"}\n');
    } else {
      print('✗ 所有來源均失敗\n');
    }
  } catch (e) {
    print('✗ 錯誤: $e\n');
  }

  print('╔══════════════════════════════════════════╗');
  print('║         測試完成                        ║');
  print('╚══════════════════════════════════════════╝\n');
}
