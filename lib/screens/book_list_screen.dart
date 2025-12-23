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

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  String _filterStatus = 'all'; // all, unread, reading, read

  Future<void> _startTitleSearchFlow() async {
    if (!mounted) return;
    final parentContext = context;
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
            final loc = AppLocalizations.of(context)!;

            Future<void> doSearch() async {
              final title = titleController.text.trim();
              final author = authorController.text.trim();
              if (title.isEmpty) {
                if (!mounted) return;
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
                );
                setState(() => results = list);
              } catch (err) {
                if (!context.mounted) return;
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
              final hasChanges = titleController.text.trim().isNotEmpty ||
                  authorController.text.trim().isNotEmpty ||
                  results.isNotEmpty ||
                  loading;
              if (!hasChanges) return true;

              final choice = await showDialog<String?>(
                context: context,
                builder: (ctx) {
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
              return false;
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
                        Expanded(
                          child: Text(
                            loc.search_by_title_title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: loc.cancel,
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
                      decoration: InputDecoration(
                        labelText: loc.label_title_required,
                        border: const OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: authorController,
                      decoration: InputDecoration(
                        labelText: loc.author_optional,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => doSearch(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : doSearch,
                        icon: const Icon(Icons.search),
                        label: Text(loc.search_button),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (loading) const LinearProgressIndicator(),
                    if (!loading && results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: [
                            Text(
                              loc.no_results_text,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit),
                                label: Text(loc.manual_isbn_label),
                                onPressed: () async {
                                  final isbn =
                                      await showManualIsbnDialog(context);
                                  if (isbn != null && isbn.isNotEmpty) {
                                    if (!parentContext.mounted) return;
                                    Navigator.of(context).pop();

                                    final provider =
                                        parentContext.read<BookProvider>();
                                    final settings =
                                        parentContext.read<SettingsProvider>();
                                    final enabledSources =
                                        settings.enabledSources;
                                    final locParent =
                                        AppLocalizations.of(parentContext)!;

                                    if (enabledSources.isEmpty) {
                                      ScaffoldMessenger.of(parentContext)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              locParent.no_enabled_sources),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    final sourceNotifier =
                                        ValueNotifier<String>(
                                            locParent.searching_title);

                                    showDialog(
                                      context: parentContext,
                                      barrierDismissible: false,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(locParent.searching_title),
                                        content: SizedBox(
                                          height: 80,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const CircularProgressIndicator(),
                                              const SizedBox(height: 12),
                                              ValueListenableBuilder<String>(
                                                valueListenable: sourceNotifier,
                                                builder: (c, value, _) => Text(
                                                    locParent
                                                        .source_label(value)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );

                                    try {
                                      final book =
                                          await provider.searchBookByIsbn(
                                        isbn,
                                        sources: enabledSources,
                                        onSourceStart: (source) {
                                          final info =
                                              ApiSourceRegistry.info(source);
                                          sourceNotifier.value =
                                              info.displayName;
                                        },
                                      );

                                      if (!parentContext.mounted) return;
                                      Navigator.of(parentContext)
                                          .pop(); // close loading dialog

                                      if (book != null) {
                                        final nav = Navigator.of(parentContext);
                                        final editResult = await nav.pushNamed(
                                          '/book-edit',
                                          arguments: book,
                                        );
                                        if (!parentContext.mounted) return;
                                        if (editResult == true) {
                                          await parentContext
                                              .read<BookProvider>()
                                              .loadBooks();
                                          ScaffoldMessenger.of(parentContext)
                                              .showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text(locParent.book_added),
                                            ),
                                          );
                                        }
                                      } else {
                                        if (!parentContext.mounted) return;
                                        ScaffoldMessenger.of(parentContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(provider.error ??
                                                locParent.book_not_found),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        provider.clearError();
                                      }
                                    } catch (e) {
                                      if (!parentContext.mounted) return;
                                      Navigator.of(parentContext).pop();
                                      final message = e.toString();
                                      ScaffoldMessenger.of(parentContext)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              locParent.error_prefix(message)),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } finally {
                                      sourceNotifier.dispose();
                                    }
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
                                Navigator.of(context).pop();
                                if (!context.mounted) return;
                                final nav = Navigator.of(context);
                                final editResult = await nav.pushNamed(
                                  '/book-edit',
                                  arguments: b,
                                );
                                if (!context.mounted) return;
                                if (editResult == true) {
                                  await context
                                      .read<BookProvider>()
                                      .loadBooks();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            AppLocalizations.of(context)!
                                                .book_added)),
                                  );
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
      // 已於內部處理刷新
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
                            provider.error!,
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
