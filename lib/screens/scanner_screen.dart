import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../models/api_source.dart';
import '../providers/settings_provider.dart';
import '../services/isbn_service.dart';
import '../models/book.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late MobileScannerController controller;
  bool _isSearching = false;
  late TextEditingController _manualIsbnController;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    _manualIsbnController = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    _manualIsbnController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture barcodes) async {
    if (_isSearching) return;

    for (final barcode in barcodes.barcodes) {
      final isbn = barcode.rawValue ?? '';
      if (isbn.isNotEmpty) {
        _isSearching = true;
        await _searchBook(isbn);
        _isSearching = false;
        break;
      }
    }
  }

  Future<void> _searchBook(String isbn) async {
    final provider = context.read<BookProvider>();
    final settings = context.read<SettingsProvider>();
    final enabledSources = settings.enabledSources;

    if (enabledSources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('尚未啟用任何查詢來源，請到設定頁開啟來源'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final sourceNotifier = ValueNotifier<String>('準備查詢...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('查詢中...'),
        content: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: sourceNotifier,
                builder: (context, value, _) => Text('來源：$value'),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final book = await provider.searchBookByIsbn(
        isbn,
        sources: enabledSources,
        onSourceStart: (source) {
          final info = ApiSourceRegistry.info(source);
          sourceNotifier.value = info.displayName;
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // 關閉載入對話框

      if (book != null) {
        final result = await Navigator.of(context).pushNamed(
          '/book-edit',
          arguments: book,
        );
        if (!mounted) return;
        if (result == true) {
          // 將成功結果往回傳給書籍列表頁，便於自動刷新
          Navigator.of(context).pop(true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? '無法查詢到書籍資訊'),
            backgroundColor: Colors.red,
          ),
        );
        provider.clearError();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      final message = e.toString();
      if (message.contains('這個是 EAN')) {
        // 提示並提供以書名查詢的選項
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('請掃描 ISBN 條碼，這個是 EAN'),
            backgroundColor: Colors.orange,
          ),
        );
        await _startTitleSearchFlow();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('錯誤: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      sourceNotifier.dispose();
    }
  }

  Future<void> _startTitleSearchFlow() async {
    if (!mounted) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final titleController = TextEditingController();
        final authorController = TextEditingController();
        List<Book> results = const [];
        bool loading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> doSearch() async {
              final title = titleController.text.trim();
              final author = authorController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('請輸入書名'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              setState(() => loading = true);
              try {
                final list = await IsbnService.searchByTitleAuthor(
                  title,
                  author: author.isEmpty ? null : author,
                  // 可視需要加入語言限制，例如: langRestrict: 'en'
                );
                setState(() => results = list);
              } catch (err) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('查詢失敗: $err'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() => loading = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '以書名查詢（Google Books）',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '書名（必填）',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(
                      labelText: '作者（可選）',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => doSearch(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : doSearch,
                      icon: const Icon(Icons.search),
                      label: const Text('查詢'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (loading) const LinearProgressIndicator(),
                  if (!loading && results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          const Text(
                            '查無結果（或無可用 ISBN）',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('手動輸入 ISBN'),
                              onPressed: () async {
                                final isbnController = TextEditingController();
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('手動輸入 ISBN'),
                                    content: TextField(
                                      controller: isbnController,
                                      decoration: const InputDecoration(
                                        hintText: '請輸入 10 或 13 位 ISBN',
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('查詢'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  Navigator.of(context).pop();
                                  await _searchBook(isbnController.text.trim());
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!loading && results.isNotEmpty)
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final b = results[index];
                          return ListTile(
                            leading: const Icon(Icons.menu_book_outlined),
                            title: Text(b.title),
                            subtitle: Text('${b.author} • ISBN: ${b.isbn}'),
                            onTap: () async {
                              // 選定後開啟編輯頁
                              Navigator.of(context).pop();
                              final editResult =
                                  await Navigator.of(this.context).pushNamed(
                                '/book-edit',
                                arguments: b,
                              );
                              if (!mounted) return;
                              if (editResult == true) {
                                Navigator.of(this.context).pop(true);
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      // 已在內部處理返回刷新
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('掃描 ISBN'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.greenAccent,
                width: 3,
              ),
            ),
            margin: const EdgeInsets.all(40),
            child: const SizedBox(
              width: 300,
              height: 300,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await controller.toggleTorch();
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(Icons.flashlight_on, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '將書籍條碼放在掃描區域',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualIsbnController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: '手動輸入 ISBN',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (value) async {
                                final isbn = value.trim();
                                if (isbn.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('請輸入 ISBN'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                await _searchBook(isbn);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final isbn = _manualIsbnController.text.trim();
                              if (isbn.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('請輸入 ISBN'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              await _searchBook(isbn);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('查詢'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
