import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/book_provider.dart';
import '../models/book.dart';
import '../models/api_source.dart';
import '../services/isbn_service.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/manual_isbn_dialog.dart';

import '../widgets/title_search_bottom_sheet.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  String _filterStatus = 'all'; // all, unread, reading, read

  Future<void> _startTitleSearchFlow() async {
    final parentContext = context;
    final book = await showTitleSearchBottomSheet(
      context,
      onManualIsbn: (isbn) async {
        final provider = parentContext.read<BookProvider>();
        final settings = parentContext.read<SettingsProvider>();
        final enabledSources = settings.enabledSources;
        final locParent = AppLocalizations.of(parentContext)!;

        if (enabledSources.isEmpty) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text(locParent.no_enabled_sources),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final sourceNotifier =
            ValueNotifier<String>(locParent.searching_title);

        showDialog(
          context: parentContext,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(locParent.searching_title),
            content: SizedBox(
              height: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<String>(
                    valueListenable: sourceNotifier,
                    builder: (c, value, _) =>
                        Text(locParent.source_label(value)),
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

          if (!parentContext.mounted) return;
          Navigator.of(parentContext).pop(); // close loading dialog

          if (book != null) {
            final nav = Navigator.of(parentContext);
            final editResult = await nav.pushNamed(
              '/book-edit',
              arguments: book,
            );
            if (!parentContext.mounted) return;
            if (editResult == true) {
              await parentContext.read<BookProvider>().loadBooks();
              if (!parentContext.mounted) return;
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(
                  content: Text(locParent.book_added),
                ),
              );
            }
          } else {
            if (!parentContext.mounted) return;
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text(provider.errorCode != null
                    ? provider.localizedError(parentContext)
                    : (provider.error ?? locParent.book_not_found)),
                backgroundColor: Colors.red,
              ),
            );
            provider.clearError();
          }
        } catch (e) {
          if (!parentContext.mounted) return;
          Navigator.of(parentContext).pop();
          final provider = parentContext.read<BookProvider>();
          if (provider.errorCode != null) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text(provider.localizedError(parentContext)),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            final message = e.toString();
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text(locParent.error_prefix(message)),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          sourceNotifier.dispose();
        }
      },
    );

    if (book != null && mounted) {
      final nav = Navigator.of(context);
      final editResult = await nav.pushNamed(
        '/book-edit',
        arguments: book,
      );
      if (editResult == true && mounted) {
        await context.read<BookProvider>().loadBooks();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.book_added)),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BookProvider>().loadBooks();
    });
  }

  List<Book> _getFilteredBooks(List<Book> books) {
    switch (_filterStatus) {
      case 'unread':
        return books.where((b) => b.status == 'unread').toList();
      case 'reading':
        return books.where((b) => b.status == 'reading').toList();
      case 'read':
        return books.where((b) => b.status == 'read').toList();
      default:
        return books;
    }
  }

  void _deleteBook(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete_confirm_title),
        content: Text(AppLocalizations.of(context)!.delete_confirm_content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<BookProvider>().deleteBook(id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)!.book_deleted)),
              );
            },
            child: Text(AppLocalizations.of(context)!.delete_action,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.my_books_title),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.search_by_title_title,
            icon: const Icon(Icons.search),
            onPressed: _startTitleSearchFlow,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: Consumer<BookProvider>(
        builder: (context, provider, child) {
          final filteredBooks = _getFilteredBooks(provider.books);

          return Column(
            children: [
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.errorCode != null
                                ? provider.localizedError(context)
                                : provider.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () =>
                              context.read<BookProvider>().clearError(),
                          tooltip: AppLocalizations.of(context)!.cancel,
                        ),
                      ],
                    ),
                  ),
                ),
              // 篩選標籤（無論有無結果都顯示）
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(AppLocalizations.of(context)!.filter_all),
                      selected: _filterStatus == 'all',
                      onSelected: (selected) {
                        setState(() => _filterStatus = 'all');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(AppLocalizations.of(context)!.filter_unread),
                      selected: _filterStatus == 'unread',
                      onSelected: (selected) {
                        setState(() => _filterStatus = 'unread');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(AppLocalizations.of(context)!.filter_reading),
                      selected: _filterStatus == 'reading',
                      onSelected: (selected) {
                        setState(() => _filterStatus = 'reading');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(AppLocalizations.of(context)!.filter_read),
                      selected: _filterStatus == 'read',
                      onSelected: (selected) {
                        setState(() => _filterStatus = 'read');
                      },
                    ),
                  ],
                ),
              ),

              if (provider.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredBooks.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_books_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.filter_no_books,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.empty_hint),
                      ],
                    ),
                  ),
                )
              else ...[
                // 書籍列表
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return BookListItem(
                        book: book,
                        onEdit: () async {
                          if (!context.mounted) return;
                          final nav = Navigator.of(context);
                          final result = await nav.pushNamed(
                            '/book-edit',
                            arguments: book,
                          );
                          if (result == true && context.mounted) {
                            await provider.loadBooks();
                          }
                        },
                        onDelete: () => _deleteBook(context, book.id!),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet<void>(
            context: context,
            useSafeArea: true,
            builder: (sheetContext) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.search),
                      title: Text(AppLocalizations.of(sheetContext)!
                          .search_by_title_title),
                      subtitle: Text(AppLocalizations.of(sheetContext)!
                          .search_by_title_subtitle),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _startTitleSearchFlow();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.qr_code_scanner),
                      title:
                          Text(AppLocalizations.of(sheetContext)!.scan_title),
                      subtitle: Text(
                          AppLocalizations.of(sheetContext)!.scan_subtitle),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        if (!sheetContext.mounted) return;
                        final nav = Navigator.of(sheetContext);
                        final result = await nav.pushNamed('/scanner');
                        if (result == true && sheetContext.mounted) {
                          await sheetContext.read<BookProvider>().loadBooks();
                          if (!sheetContext.mounted) return;
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(
                                content: Text(AppLocalizations.of(sheetContext)!
                                    .book_added)),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class BookListItem extends StatelessWidget {
  final Book book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BookListItem({
    super.key,
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  // Lexile 查詢入口已從列表頁移除，僅保留顯示數值

  Widget _buildCoverImage() {
    if (book.coverUrl == null) {
      return Container(
        width: 48,
        height: 72,
        color: Colors.grey[300],
        child: const Icon(Icons.book),
      );
    }

    final coverUrl = book.coverUrl!;
    // 判斷是本地檔案還是網路圖片
    if (coverUrl.startsWith('/') || coverUrl.startsWith('file://')) {
      final path = coverUrl.replaceFirst('file://', '');
      return Image.file(
        File(path),
        width: 48,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 48,
          height: 72,
          color: Colors.grey[300],
          child: const Icon(Icons.book),
        ),
      );
    } else {
      return Image.network(
        coverUrl,
        width: 48,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 48,
          height: 72,
          color: Colors.grey[300],
          child: const Icon(Icons.book),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildCoverImage(),
        title: Text(book.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: book.status == 'read'
                        ? Colors.green
                        : book.status == 'reading'
                            ? Colors.orange
                            : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    book.status == 'read'
                        ? AppLocalizations.of(context)!.filter_read
                        : book.status == 'reading'
                            ? AppLocalizations.of(context)!.filter_reading
                            : AppLocalizations.of(context)!.filter_unread,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (book.lexileScore != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.auto_graph,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Builder(builder: (ctx) {
                        final score = book.lexileScore!;
                        return Text(
                            AppLocalizations.of(ctx)!.lexile_label(score));
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: const Icon(Icons.edit),
                    title: Text(AppLocalizations.of(context)!.edit),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: Text(AppLocalizations.of(context)!.delete),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
