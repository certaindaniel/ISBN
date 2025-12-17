import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/scanner_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/book_edit_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/api_test_screen.dart';
import 'providers/book_provider.dart';
import 'providers/settings_provider.dart';
import 'models/book.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IsbnBookManagerApp());
}

class IsbnBookManagerApp extends StatelessWidget {
  const IsbnBookManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => BookProvider()..initialize()),
      ],
      child: MaterialApp(
        title: 'ISBN 書籍管理',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        routes: {
          '/scanner': (context) => const ScannerScreen(),
          '/book-edit': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            return BookEditScreen(
              initialBook: args is Book ? args : null,
            );
          },
          '/book-list': (context) => const BookListScreen(),
          '/statistics': (context) => const StatisticsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/api-test': (context) => const ApiTestScreen(),
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        const BookListScreen(),
        const StatisticsScreen(),
      ][_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: '書籍',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '統計',
          ),
        ],
      ),
    );
  }
}
