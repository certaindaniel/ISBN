import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_logger.dart';
import '../models/api_source.dart';
import '../services/isbn_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final _testIsbn = '9789868914766';
  String _output = '';
  bool _isRunning = false;

  void _addLog(String message) {
    setState(() {
      _output += '$message\n';
    });
    AppLogger.debug(message);
  }

  Future<void> _runTests() async {
    setState(() {
      _output = '';
      _isRunning = true;
    });

    _addLog('\n╔══════════════════════════════════════════╗');
    _addLog('║   ISBN API 測試工作                      ║');
    _addLog('║   ISBN: $_testIsbn                   ║');
    _addLog('╚══════════════════════════════════════════╝\n');

    // 測試 1: Google Books
    _addLog('【測試 1】Google Books API');
    _addLog('─' * 50);
    try {
      List<ApiSource> sources = [ApiSource.googleBooks];
      final book = await IsbnService.searchByIsbn(
        _testIsbn,
        sources: sources,
        onSourceStart: (source) {
          _addLog('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
        },
      );

      if (book != null) {
        _addLog('✓ 成功\n');
        _addLog('  書名: ${book.title}');
        _addLog('  作者: ${book.author}');
        _addLog('  出版社: ${book.publisher}');
        _addLog('  ISBN: ${book.isbn}');
        _addLog('  封面: ${book.coverUrl != null ? "有" : "無"}\n');
      } else {
        _addLog('✗ 未返回結果\n');
      }
    } catch (e) {
      _addLog('✗ 錯誤: $e\n');
    }

    // 測試 2: Open Library
    _addLog('【測試 2】Open Library API');
    _addLog('─' * 50);
    try {
      List<ApiSource> sources = [ApiSource.openLibrary];
      final book = await IsbnService.searchByIsbn(
        _testIsbn,
        sources: sources,
        onSourceStart: (source) {
          _addLog('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
        },
      );

      if (book != null) {
        _addLog('✓ 成功\n');
        _addLog('  書名: ${book.title}');
        _addLog('  作者: ${book.author}');
        _addLog('  出版社: ${book.publisher}');
        _addLog('  ISBN: ${book.isbn}');
        _addLog('  封面: ${book.coverUrl != null ? "有" : "無"}\n');
      } else {
        _addLog('✗ 未返回結果\n');
      }
    } catch (e) {
      _addLog('✗ 錯誤: $e\n');
    }

    // 測試 3: Jike 免費 API
    _addLog('【測試 3】Jike 免費 API');
    _addLog('─' * 50);
    try {
      List<ApiSource> sources = [ApiSource.jikeFree];
      final book = await IsbnService.searchByIsbn(
        _testIsbn,
        sources: sources,
        onSourceStart: (source) {
          _addLog('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
        },
      );

      if (book != null) {
        _addLog('✓ 成功\n');
        _addLog('  書名: ${book.title}');
        _addLog('  作者: ${book.author}');
        _addLog('  出版社: ${book.publisher}');
        _addLog('  ISBN: ${book.isbn}');
        _addLog('  封面: ${book.coverUrl != null ? "有" : "無"}\n');
      } else {
        _addLog('⚠ 未返回結果（此來源不穩定）\n');
      }
    } catch (e) {
      _addLog('⚠ 錯誤（此來源不穩定，可忽略）: $e\n');
    }

    // 測試 4: 依序嘗試 Google + Open Library
    _addLog('【測試 4】多來源查詢 (Google → Open Library)');
    _addLog('─' * 50);
    try {
      List<ApiSource> sources = [
        ApiSource.googleBooks,
        ApiSource.openLibrary,
      ];
      List<ApiSource> attemptedSources = [];

      final book = await IsbnService.searchByIsbn(
        _testIsbn,
        sources: sources,
        onSourceStart: (source) {
          attemptedSources.add(source);
          _addLog('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
        },
      );

      if (book != null) {
        _addLog('✓ 成功\n');
        _addLog(
            '  嘗試順序: ${attemptedSources.map((s) => ApiSourceRegistry.info(s).displayName).join(" → ")}');
        _addLog('  使用第 ${attemptedSources.length} 個來源');
        _addLog('  書名: ${book.title}');
        _addLog('  作者: ${book.author}');
        _addLog('  出版社: ${book.publisher}\n');
      } else {
        _addLog('✗ 所有來源均失敗\n');
      }
    } catch (e) {
      _addLog('✗ 錯誤: $e\n');
    }

    // 測試 5: 所有預設來源
    _addLog('【測試 5】所有預設來源');
    _addLog('─' * 50);
    try {
      List<ApiSource> sources = ApiSourceRegistry.defaultEnabled();
      List<ApiSource> attemptedSources = [];

      _addLog(
          '啟用的來源: ${sources.map((s) => ApiSourceRegistry.info(s).displayName).join(", ")}\n');

      final book = await IsbnService.searchByIsbn(
        _testIsbn,
        sources: sources,
        onSourceStart: (source) {
          attemptedSources.add(source);
          _addLog('嘗試來源: ${ApiSourceRegistry.info(source).displayName}');
        },
      );

      if (book != null) {
        _addLog('✓ 成功\n');
        _addLog(
            '  最終使用: ${ApiSourceRegistry.info(attemptedSources.last).displayName}');
        _addLog('  嘗試次數: ${attemptedSources.length}');
        _addLog('  書籍資訊:');
        _addLog('    - 書名: ${book.title}');
        _addLog('    - 作者: ${book.author}');
        _addLog('    - 出版社: ${book.publisher}');
        _addLog('    - ISBN: ${book.isbn}');
        _addLog('    - 封面: ${book.coverUrl != null ? "有" : "無"}\n');
      } else {
        _addLog('✗ 所有來源均失敗\n');
      }
    } catch (e) {
      _addLog('✗ 錯誤: $e\n');
    }

    _addLog('╔══════════════════════════════════════════╗');
    _addLog('║         測試完成                        ║');
    _addLog('╚══════════════════════════════════════════╝\n');

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.api_test_title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _runTests,
              icon: _isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label:
                  Text(_isRunning ? loc.api_test_running : loc.api_test_start),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _output.isEmpty ? loc.api_test_output_placeholder : _output,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
