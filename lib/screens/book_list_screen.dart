import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../models/book.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  String _filterStatus = 'all'; // all, owned, sold

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<BookProvider>().loadBooks();
    });
  }

  List<Book> _getFilteredBooks(List<Book> books) {
    switch (_filterStatus) {
      case 'owned':
        return books.where((b) => b.status == 'owned').toList();
      case 'sold':
        return books.where((b) => b.status == 'sold').toList();
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
                          '還沒有書籍',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '點擊 + 按鈕開始掃描新書籍',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // 篩選標籤
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
                        label: const Text('未售出'),
                        selected: _filterStatus == 'owned',
                        onSelected: (selected) {
                          setState(() => _filterStatus = 'owned');
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('已售出'),
                        selected: _filterStatus == 'sold',
                        onSelected: (selected) {
                          setState(() => _filterStatus = 'sold');
                        },
                      ),
                    ],
                  ),
                ),

                // 書籍列表
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return BookListItem(
                        book: book,
                        onEdit: () async {
                          final result = await Navigator.of(context).pushNamed(
                            '/book-edit',
                            arguments: book,
                          );
                          if (result == true && mounted) {
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
          final result = await Navigator.of(context).pushNamed('/scanner');
          if (result == true && mounted) {
            await context.read<BookProvider>().loadBooks();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已新增書籍')),
            );
          }
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: book.coverUrl != null
            ? Image.network(
                book.coverUrl!,
                width: 48,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 72,
                  color: Colors.grey[300],
                  child: const Icon(Icons.book),
                ),
              )
            : Container(
                width: 48,
                height: 72,
                color: Colors.grey[300],
                child: const Icon(Icons.book),
              ),
        title: Text(book.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: book.status == 'sold' ? Colors.orange : Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    book.status == 'sold' ? '已售出' : '持有中',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${book.purchasePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (book.salePrice != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '售: \$${book.salePrice!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
            if (book.profit != null) ...[
              const SizedBox(height: 4),
              Text(
                '利潤: \$${book.profit!.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: book.profit! > 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: onEdit,
              child: const Text('編輯'),
            ),
            PopupMenuItem(
              onTap: onDelete,
              child: const Text('刪除'),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
