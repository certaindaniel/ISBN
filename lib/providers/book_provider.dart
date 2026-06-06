import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/api_source.dart';
import '../services/database_helper.dart';
import '../services/isbn_service.dart';
import '../utils/app_logger.dart';
import '../l10n/app_localizations.dart';

class BookProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Book> _books = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  String? _error;
  String? _errorCode;
  Map<String, dynamic>? _errorArgs;

  List<Book> get books => _books;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorCode => _errorCode;
  Map<String, dynamic>? get errorArgs => _errorArgs;

  // 初始化
  Future<void> initialize() async {
    await loadBooks();
    await loadStatistics();
  }

  // 載入所有書籍
  Future<void> loadBooks() async {
    try {
      _isLoading = true;
      _error = null;
      _errorCode = null;
      _errorArgs = null;
      _books = await _dbHelper.getAllBooks();
      notifyListeners();
    } catch (e) {
      _error = '載入書籍失敗: $e';
      _errorCode = 'load_books_failed';
      _errorArgs = {'error': e.toString()};
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 載入統計資訊
  Future<void> loadStatistics() async {
    try {
      _statistics = await _dbHelper.getStatistics();
      notifyListeners();
    } catch (e, st) {
      AppLogger.warn('載入統計失敗: $e', e, st);
    }
  }

  // 依 ISBN 查詢書籍資訊，支援多來源與進度回報
  Future<Book?> searchBookByIsbn(
    String isbn, {
    List<ApiSource>? sources,
    ValueChanged<ApiSource>? onSourceStart,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      _errorCode = null;
      _errorArgs = null;
      notifyListeners();

      final normalizedIsbn = IsbnService.normalizeIsbn(isbn);
      AppLogger.debug(
          'searchBookByIsbn called: raw="$isbn" normalized="$normalizedIsbn"');

      // 先檢查本地資料庫
      final localBook = await _dbHelper.getBookByISBN(normalizedIsbn);
      if (localBook != null) {
        _error = '此 ISBN 已存在於資料庫';
        _errorCode = 'isbn_already_exists';
        _errorArgs = null;
        notifyListeners();
        return localBook;
      }

      // 從 API 查詢
      final activeSources = (sources == null || sources.isEmpty)
          ? ApiSourceRegistry.defaultEnabled()
          : sources;
      AppLogger.debug(
          'activeSources order: ${activeSources.map((s) => ApiSourceRegistry.info(s).displayName).join(', ')}');

      final book = await IsbnService.searchByIsbn(
        normalizedIsbn,
        sources: activeSources,
        onSourceStart: (src) {
          AppLogger.debug(
              'starting source: ${ApiSourceRegistry.info(src).displayName}');
          if (onSourceStart != null) onSourceStart(src);
        },
      );

      if (book == null) {
        final nclUrl =
            'https://isbn.ncl.edu.tw/NEW_ISBNNet/main_DisplayResults.php?Pact=DisplayAll4Simple&isbn=$normalizedIsbn';
        _error = '無法查詢到此 ISBN 的書籍資訊，可前往 NCL 查詢：$nclUrl';
        _errorCode = 'cannot_find_isbn_ncl';
        _errorArgs = {'url': nclUrl};
      }

      notifyListeners();
      return book;
    } on IsbnException catch (e) {
      _error = e.message;
      _errorCode = e.code;
      _errorArgs = null;
      notifyListeners();
      return null;
    } catch (e) {
      _error = '查詢失敗: $e';
      _errorCode = 'query_failed_error';
      _errorArgs = {'error': e.toString()};
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 新增書籍
  Future<bool> addBook(Book book) async {
    try {
      _isLoading = true;
      _error = null;
      _errorCode = null;
      _errorArgs = null;
      notifyListeners();

      final normalizedIsbn = IsbnService.normalizeIsbn(book.isbn);
      if (!IsbnService.isValidIsbn(normalizedIsbn)) {
        _error = '無效的 ISBN 格式';
        _errorCode = 'isbn_error_invalid_format';
        _errorArgs = null;
        notifyListeners();
        return false;
      }
      final bookToSave = book.copyWith(isbn: normalizedIsbn);

      // 檢查 ISBN 是否已存在
      final existing = await _dbHelper.getBookByISBN(normalizedIsbn);
      if (existing != null) {
        _error = 'ISBN 已存在於資料庫';
        _errorCode = 'isbn_already_exists';
        _errorArgs = null;
        notifyListeners();
        return false;
      }

      await _dbHelper.insertBook(bookToSave);
      await loadBooks();
      await loadStatistics();
      return true;
    } catch (e) {
      _error = '新增書籍失敗: $e';
      _errorCode = 'add_book_failed';
      _errorArgs = {'error': e.toString()};
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 更新書籍
  Future<bool> updateBook(Book book) async {
    try {
      _isLoading = true;
      _error = null;
      _errorCode = null;
      _errorArgs = null;
      notifyListeners();

      final normalizedIsbn = IsbnService.normalizeIsbn(book.isbn);
      if (!IsbnService.isValidIsbn(normalizedIsbn)) {
        _error = '無效的 ISBN 格式';
        _errorCode = 'isbn_error_invalid_format';
        _errorArgs = null;
        notifyListeners();
        return false;
      }
      final bookToSave = book.copyWith(isbn: normalizedIsbn);

      await _dbHelper.updateBook(bookToSave);
      await loadBooks();
      await loadStatistics();
      return true;
    } catch (e) {
      _error = '更新書籍失敗: $e';
      _errorCode = 'update_book_failed';
      _errorArgs = {'error': e.toString()};
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 刪除書籍
  Future<bool> deleteBook(int id) async {
    try {
      _isLoading = true;
      _error = null;
      _errorCode = null;
      _errorArgs = null;
      notifyListeners();

      await _dbHelper.deleteBook(id);
      await loadBooks();
      await loadStatistics();
      return true;
    } catch (e) {
      _error = '刪除書籍失敗: $e';
      _errorCode = 'delete_book_failed';
      _errorArgs = {'error': e.toString()};
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 記錄售出資訊
  Future<bool> markAsSold(Book book, double salePrice) async {
    try {
      final updatedBook = book.copyWith(
        salePrice: salePrice,
        saleDate: DateTime.now(),
        status: 'read',
      );

      return await updateBook(updatedBook);
    } catch (e) {
      _error = '記錄售出失敗: $e';
      _errorCode = 'provider_book_record_sale_failed';
      _errorArgs = {'error': e.toString()};
      notifyListeners();
      return false;
    }
  }

  // 清除錯誤訊息
  void clearError() {
    _error = null;
    _errorCode = null;
    _errorArgs = null;
    notifyListeners();
  }

  /// Helper: return localized error message when UI has a BuildContext.
  String localizedError(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (_errorCode) {
      case 'scan_not_isbn_ean':
        return loc.scan_not_isbn_ean;
      case 'provider_book_record_sale_failed':
        return loc.provider_book_record_sale_failed(_errorArgs?['error'] ?? '');
      case 'isbn_error_invalid_format':
        return loc.isbn_error_invalid_format;
      case 'isbn_already_exists':
        return loc.isbn_already_exists;
      case 'cannot_find_isbn_ncl':
        return loc.cannot_find_isbn_ncl(_errorArgs?['url'] ?? '');
      case 'load_books_failed':
        return loc.load_books_failed(_errorArgs?['error'] ?? '');
      case 'add_book_failed':
        return loc.add_book_failed(_errorArgs?['error'] ?? '');
      case 'update_book_failed':
        return loc.update_book_failed(_errorArgs?['error'] ?? '');
      case 'delete_book_failed':
        return loc.delete_book_failed(_errorArgs?['error'] ?? '');
      case 'query_failed_error':
        return loc.query_failed_error(_errorArgs?['error'] ?? '');
      default:
        return _error ?? '';
    }
  }
}
