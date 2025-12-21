import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helper.dart';
import 'package:isbn_book_manager/models/book.dart';
import 'package:isbn_book_manager/screens/book_edit_screen.dart';
import 'package:isbn_book_manager/l10n/app_localizations.dart';

void main() {
  setUpAll(() {
    initTestDatabase();
  });

  testWidgets('沒有封面時顯示拍攝提示', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BookEditScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('拍攝封面'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });

  testWidgets('有封面時顯示重拍按鈕', (WidgetTester tester) async {
    final book = Book(
      id: 1,
      isbn: '9781234567897',
      title: '測試書',
      author: '作者',
      publisher: '出版社',
      coverUrl: 'file:///tmp/dummy.jpg',
      description: null,
      purchasePrice: 10.0,
      salePrice: null,
      purchaseDate: DateTime.now(),
      saleDate: null,
      language: 'zh',
      lexileScore: null,
      status: 'unread',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BookEditScreen(initialBook: book),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 找到帶有相機 icon 的 FloatingActionButton（重拍）
    expect(find.widgetWithIcon(FloatingActionButton, Icons.camera_alt),
        findsOneWidget);
  });
}
