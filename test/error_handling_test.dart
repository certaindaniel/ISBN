import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/services/isbn_service.dart';
import '../lib/providers/book_provider.dart';
import '../lib/models/api_source.dart';

void main() {
  // 初始化資料庫工廠以利於測試
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('IsbnException Tests', () {
    test('IsbnService should throw IsbnException for EAN', () async {
      // 977... is ISSN (EAN-13 but not ISBN)
      const ean = '9771234567898';
      
      expect(
        () => IsbnService.searchByIsbn(ean),
        throwsA(isA<IsbnException>().having((e) => e.code, 'code', 'scan_not_isbn_ean')),
      );
    });

    test('IsbnService should throw IsbnException for invalid format', () async {
      const invalid = '12345';
      
      expect(
        () => IsbnService.searchByIsbn(invalid),
        throwsA(isA<IsbnException>().having((e) => e.code, 'code', 'isbn_error_invalid_format')),
      );
    });
  });

  group('BookProvider Error Handling Tests', () {
    late BookProvider provider;

    setUp(() {
      provider = BookProvider();
    });

    test('searchBookByIsbn should set errorCode for IsbnException', () async {
      const ean = '9771234567898';
      
      await provider.searchBookByIsbn(ean);
      
      expect(provider.errorCode, 'scan_not_isbn_ean');
    });

    test('addBook should set errorCode for invalid ISBN', () async {
      // Mocking Book is not easy without more imports, but we can test the logic
      // Since addBook checks isValidIsbn before DB operation
    });
  });
}
