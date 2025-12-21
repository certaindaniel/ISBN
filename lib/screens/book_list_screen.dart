// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/book_provider.dart';
import '../models/book.dart';
import '../services/isbn_service.dart';
import '../providers/settings_provider.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  String _filterStatus = 'all'; // all, unread, reading, read

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
                );
                setState(() => results = list);
              } catch (err) {
                if (!context.mounted) return;
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
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  final provider = context.read<BookProvider>();
                                  final settings =
                                      context.read<SettingsProvider>();
                                  final book = await provider.searchBookByIsbn(
                                    isbnController.text.trim(),
                                    sources: settings.enabledSources,
                                  );
                                  if (book != null) {
                                    if (!context.mounted) return;
                                    final nav = Navigator.of(context);
                                    final editResult = await nav.pushNamed(
                                      '/book-edit',
                                      arguments: book,
                                    );
                                    if (editResult == true && context.mounted) {
                                      await context
                                          .read<BookProvider>()
                                          .loadBooks();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(content: Text('已新增書籍')),
                                      );
                                    }
                                  } else {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text(provider.error ?? '查無書籍資訊')),
                                    );
                                    provider.clearError();
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
                                await context.read<BookProvider>().loadBooks();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已新增書籍')),
                                );
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
        title: const Text('刪除確認'),
        content: const Text('確定要刪除此書籍嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<BookProvider>().deleteBook(id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('書籍已刪除')),
              );
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的書籍'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '以書名查詢',
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
                          tooltip: '關閉',
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
                      label: const Text('全部'),
                      selected: _filterStatus == 'all',
                      onSelected: (selected) {
                        setState(() => _filterStatus = 'all');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('未讀'),
                      selected: _filterStatus == 'unread',
                      onSelected: (selected) {
                        setState(() => _filterStatus = 'unread');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('閱讀中'),
                      selected: _filterStatus == 'reading',
                      onSelected: (selected) {
                        setState(() => _filterStatus = 'reading');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('已讀'),
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
                          '這個篩選沒有書籍',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text('換個篩選或新增一本試試看'),
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
                      title: const Text('以書名查詢'),
                      subtitle: const Text('輸入書名/作者，用 Google Books 搜尋'),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _startTitleSearchFlow();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.qr_code_scanner),
                      title: const Text('掃描 ISBN'),
                      subtitle: const Text('使用相機掃描條碼（支援 978/979）'),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        if (!sheetContext.mounted) return;
                        final nav = Navigator.of(sheetContext);
                        final result = await nav.pushNamed('/scanner');
                        if (result == true && sheetContext.mounted) {
                          await sheetContext.read<BookProvider>().loadBooks();
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text('已新增書籍')),
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
                        ? '已讀'
                        : book.status == 'reading'
                            ? '閱讀中'
                            : '未讀',
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
                      Text('Lexile: ${book.lexileScore}L'),
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
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('編輯'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('刪除'),
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
