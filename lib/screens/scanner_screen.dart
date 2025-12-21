// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../models/api_source.dart';
import '../providers/settings_provider.dart';
import '../services/isbn_service.dart';
import '../models/book.dart';
import '../l10n/app_localizations.dart';
// 使用 framework PopScope 以支援系統預測返回手勢

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
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.no_enabled_sources),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final loc = AppLocalizations.of(context)!;
    final sourceNotifier = ValueNotifier<String>(loc.searching_title);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(loc.searching_title),
        content: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: sourceNotifier,
                builder: (context, value, _) => Text(loc.source_label(value)),
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? loc.cannot_find_book),
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
          SnackBar(
            content: Text(loc.scan_not_isbn_ean),
            backgroundColor: Colors.orange,
          ),
        );
        await _startTitleSearchFlow();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.error_prefix(message)),
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
      isDismissible: false,
      enableDrag: false,
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
                if (!mounted) return;
                final loc = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.please_enter_title),
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
                if (!context.mounted) return;
                final loc = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.query_failed_error(err)),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() => loading = false);
              }
            }

            Future<bool> confirmClose() async {
              // 若有未輸入內容或有查詢結果，提示使用者
              final hasChanges = titleController.text.trim().isNotEmpty ||
                  authorController.text.trim().isNotEmpty ||
                  results.isNotEmpty ||
                  loading;
              if (!hasChanges) return true;

              final choice = await showDialog<String?>(
                context: context,
                builder: (ctx) {
                  final loc = AppLocalizations.of(ctx)!;
                  return AlertDialog(
                    title: Text(loc.unfinishedSearchTitle),
                    content: Text(loc.unfinishedSearchContent),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop('cancel'),
                        child: Text(loc.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop('discard'),
                        child: Text(loc.discard),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop('search'),
                        child: Text(loc.performSearch),
                      ),
                    ],
                  );
                },
              );

              if (choice == 'discard') return true;
              if (choice == 'search') {
                await doSearch();
                return false;
              }
              return false; // cancel or null
            }

            return PopScope<Object?>(
              canPop: false,
              onPopInvokedWithResult: (bool didPop, Object? result) async {
                if (didPop) return;
                final shouldClose = await confirmClose();
                if (shouldClose && context.mounted) {
                  Navigator.of(context).pop(false);
                }
              },
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '以書名查詢（Google Books）',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: '關閉',
                          onPressed: () async {
                            final shouldClose = await confirmClose();
                            if (shouldClose && context.mounted) {
                              Navigator.of(context).pop(false);
                            }
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
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
                                  final isbnController =
                                      TextEditingController();
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
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop();
                                    await _searchBook(
                                        isbnController.text.trim());
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
                                if (!mounted) return;
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
          // 掃描方框居中
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              width: 280,
              height: 280,
            ),
          ),
          // 底部控制區
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha((0.7 * 255).round()),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 提示文字
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.5 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha((0.5 * 255).round()),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '將書籍條碼放在掃描區域',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 手動輸入區
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.5 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha((0.3 * 255).round()),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualIsbnController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '手動輸入 ISBN',
                              hintStyle: TextStyle(
                                color:
                                    Colors.white.withAlpha((0.6 * 255).round()),
                              ),
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
                        FilledButton(
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
                          child: const Text('查詢'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 手電筒按鈕
                  FilledButton.tonal(
                    onPressed: () async {
                      await controller.toggleTorch();
                      setState(() {});
                    },
                    child: const Icon(Icons.flashlight_on),
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
