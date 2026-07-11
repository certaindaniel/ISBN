import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:isbn_book_manager/models/book.dart';
import 'package:isbn_book_manager/providers/book_provider.dart';
import 'package:isbn_book_manager/services/purchase_service.dart';

/// 產生合法且互不重複的 ISBN-13（978 前綴 + 流水號 + 校驗碼）
String _isbn13(int i) {
  final base = '978${i.toString().padLeft(9, '0')}';
  var sum = 0;
  for (var j = 0; j < 12; j++) {
    sum += int.parse(base[j]) * (j.isEven ? 1 : 3);
  }
  return '$base${(10 - sum % 10) % 10}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // review_prompted=true 讓 ReviewService 提早 return，避免測試環境呼叫平台 channel
  SharedPreferences.setMockInitialValues({'review_prompted': true});

  test('未解鎖時第 ${PurchaseService.freeBookLimit + 1} 本書被擋下', () async {
    final provider = BookProvider();
    await provider.loadBooks();
    for (final book in List.of(provider.books)) {
      await provider.deleteBook(book.id!);
    }

    for (var i = 0; i < PurchaseService.freeBookLimit; i++) {
      final ok = await provider.addBook(Book(
        isbn: _isbn13(i),
        title: 'Book $i',
        author: 'Tester',
        publisher: 'Test Press',
        purchasePrice: 100,
        purchaseDate: DateTime.now(),
      ));
      expect(ok, isTrue, reason: '第 ${i + 1} 本應可新增');
    }

    final blocked = await provider.addBook(Book(
      isbn: _isbn13(PurchaseService.freeBookLimit),
      title: 'Over limit',
      author: 'Tester',
      publisher: 'Test Press',
      purchasePrice: 100,
      purchaseDate: DateTime.now(),
    ));
    expect(blocked, isFalse);
    expect(provider.errorCode, 'free_limit_reached');

    for (final book in List.of(provider.books)) {
      await provider.deleteBook(book.id!);
    }
  });
}
