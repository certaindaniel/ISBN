import 'package:flutter_test/flutter_test.dart';
import 'package:isbn_book_manager/models/book.dart';

void main() {
  group('Book 模型測試', () {
    test('書籍創建', () {
      final book = Book(
        isbn: '9780140328721',
        title: '1984',
        author: 'George Orwell',
        publisher: 'Penguin Books',
        purchasePrice: 100.0,
        purchaseDate: DateTime(2025, 1, 1),
      );

      expect(book.isbn, '9780140328721');
      expect(book.title, '1984');
      expect(book.author, 'George Orwell');
      expect(book.publisher, 'Penguin Books');
      expect(book.purchasePrice, 100.0);
      expect(book.status, 'owned');
    });

    test('計算利潤', () {
      final book = Book(
        isbn: '9780140328721',
        title: '1984',
        author: 'George Orwell',
        publisher: 'Penguin Books',
        purchasePrice: 100.0,
        purchaseDate: DateTime.now(),
        salePrice: 150.0,
      );

      expect(book.profit, 50.0);
    });

    test('無銷售價格時利潤為 null', () {
      final book = Book(
        isbn: '9780140328721',
        title: '1984',
        author: 'George Orwell',
        publisher: 'Penguin Books',
        purchasePrice: 100.0,
        purchaseDate: DateTime.now(),
      );

      expect(book.profit, null);
    });

    test('JSON 序列化和反序列化', () {
      final originalBook = Book(
        isbn: '9780140328721',
        title: '1984',
        author: 'George Orwell',
        publisher: 'Penguin Books',
        coverUrl: 'https://example.com/cover.jpg',
        description: '反烏托邦小說',
        purchasePrice: 100.0,
        purchaseDate: DateTime(2025, 1, 1),
        salePrice: 150.0,
        saleDate: DateTime(2025, 6, 1),
      );

      final json = originalBook.toJson();
      final deserializedBook = Book.fromJson(json);

      expect(deserializedBook.isbn, originalBook.isbn);
      expect(deserializedBook.title, originalBook.title);
      expect(deserializedBook.author, originalBook.author);
      expect(deserializedBook.purchasePrice, originalBook.purchasePrice);
    });

    test('copyWith 複製並修改', () {
      final book = Book(
        isbn: '9780140328721',
        title: '1984',
        author: 'George Orwell',
        publisher: 'Penguin Books',
        purchasePrice: 100.0,
        purchaseDate: DateTime.now(),
      );

      final updatedBook = book.copyWith(
        salePrice: 150.0,
        status: 'sold',
      );

      expect(updatedBook.isbn, book.isbn);
      expect(updatedBook.salePrice, 150.0);
      expect(updatedBook.status, 'sold');
      expect(updatedBook.profit, 50.0);
    });
  });
}
