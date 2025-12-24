// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'test_helper.dart';

import 'package:isbn_book_manager/main.dart';
import 'package:isbn_book_manager/l10n/app_localizations.dart';
import 'package:isbn_book_manager/providers/book_provider.dart';
import 'package:isbn_book_manager/providers/settings_provider.dart';

void main() {
  setUpAll(() {
    initTestDatabase();
  });

  testWidgets('HomeScreen shows main navigation label',
      (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider()),
        ChangeNotifierProvider<BookProvider>(create: (_) => BookProvider()),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(),
      ),
    ));

    await tester.pump();

    final bar =
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(bar.items[0].label, '書籍');
  });
}
