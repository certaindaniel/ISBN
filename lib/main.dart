import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/scanner_screen.dart' deferred as scanner_screen;
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

class _DeferredScannerLoader extends StatefulWidget {
  const _DeferredScannerLoader();

  @override
  State<_DeferredScannerLoader> createState() => _DeferredScannerLoaderState();
}

class _DeferredScannerLoaderState extends State<_DeferredScannerLoader> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await scanner_screen.loadLibrary();
      if (mounted) setState(() => _loaded = true);
    } catch (_) {
      if (mounted) setState(() => _loaded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return scanner_screen.ScannerScreen();
  }
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
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        routes: {
          '/scanner': (context) => const _DeferredScannerLoader(),
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books),
            label: AppLocalizations.of(context)?.books ?? '書籍',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: AppLocalizations.of(context)?.statistics ?? '統計',
          ),
        ],
      ),
    );
  }
}
