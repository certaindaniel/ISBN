import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../models/api_source.dart';
import '../providers/settings_provider.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('錯誤: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      sourceNotifier.dispose();
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
