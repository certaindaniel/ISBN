import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';

class BookEditScreen extends StatefulWidget {
  final Book? initialBook;

  const BookEditScreen({super.key, this.initialBook});

  @override
  State<BookEditScreen> createState() => _BookEditScreenState();
}

class _BookEditScreenState extends State<BookEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _publisherController;
  late TextEditingController _descriptionController;
  late TextEditingController _isbnController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;

  late DateTime _purchaseDate;
  DateTime? _saleDate;

  @override
  void initState() {
    super.initState();
    final book = widget.initialBook;

    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _publisherController = TextEditingController(text: book?.publisher ?? '');
    _descriptionController =
        TextEditingController(text: book?.description ?? '');
    _isbnController = TextEditingController(text: book?.isbn ?? '');
    _purchasePriceController = TextEditingController(
      text: book?.purchasePrice.toString() ?? '',
    );
    _salePriceController = TextEditingController(
      text: book?.salePrice?.toString() ?? '',
    );

    _purchaseDate = book?.purchaseDate ?? DateTime.now();
    _saleDate = book?.saleDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _descriptionController.dispose();
    _isbnController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isPurchaseDate) async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          isPurchaseDate ? _purchaseDate : (_saleDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = selected;
        } else {
          _saleDate = selected;
        }
      });
    }
  }

  Future<void> _saveBook() async {
    if (_titleController.text.isEmpty ||
        _authorController.text.isEmpty ||
        _publisherController.text.isEmpty ||
        _isbnController.text.isEmpty ||
        _purchasePriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填入所有必填欄位')),
      );
      return;
    }

    final book = Book(
      id: widget.initialBook?.id,
      isbn: _isbnController.text.trim(),
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      publisher: _publisherController.text.trim(),
      coverUrl: widget.initialBook?.coverUrl,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      purchasePrice: double.parse(_purchasePriceController.text),
      salePrice: _salePriceController.text.isNotEmpty
          ? double.parse(_salePriceController.text)
          : null,
      purchaseDate: _purchaseDate,
      saleDate: _saleDate,
    );

    final provider = context.read<BookProvider>();
    bool success;

    // 若是掃描新增帶入的書（沒有資料庫 id），視為新增；否則為更新
    if ((widget.initialBook?.id) == null) {
      success = await provider.addBook(book);
    } else {
      success = await provider.updateBook(book);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('書籍已儲存')),
      );
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? '儲存失敗'),
          backgroundColor: Colors.red,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialBook == null ? '新增書籍' : '編輯書籍'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 書籍封面
            if (widget.initialBook?.coverUrl != null)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.initialBook!.coverUrl!,
                      width: 120,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 120,
                        height: 180,
                        color: Colors.grey[300],
                        child: const Icon(Icons.book),
                      ),
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Container(
                  width: 120,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.book, size: 64),
                ),
              ),
            const SizedBox(height: 24),

            // ISBN
            TextField(
              controller: _isbnController,
              decoration: const InputDecoration(
                labelText: 'ISBN *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.barcode_reader),
              ),
              readOnly: widget.initialBook != null,
            ),
            const SizedBox(height: 16),

            // 書名
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '書名 *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 作者
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: '作者 *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 出版社
            TextField(
              controller: _publisherController,
              decoration: const InputDecoration(
                labelText: '出版社 *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 描述
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // 購買價格
            TextField(
              controller: _purchasePriceController,
              decoration: const InputDecoration(
                labelText: '購買價格 (元) *',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 購買日期
            ListTile(
              title: const Text('購買日期'),
              subtitle: Text(
                  '${_purchaseDate.year}-${_purchaseDate.month.toString().padLeft(2, '0')}-${_purchaseDate.day.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(true),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            // 售出價格
            TextField(
              controller: _salePriceController,
              decoration: const InputDecoration(
                labelText: '售出價格 (元)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 售出日期
            if (_saleDate != null) ...[
              ListTile(
                title: const Text('售出日期'),
                subtitle: Text(
                    '${_saleDate!.year}-${_saleDate!.month.toString().padLeft(2, '0')}-${_saleDate!.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _selectDate(false),
                icon: const Icon(Icons.add),
                label: const Text('設定售出日期'),
              ),
            ],
            const SizedBox(height: 32),

            // 利潤顯示
            if (_purchasePriceController.text.isNotEmpty &&
                _salePriceController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '利潤計算',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('購買價格:'),
                        Text('\$${_purchasePriceController.text}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('售出價格:'),
                        Text('\$${_salePriceController.text}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '利潤:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${((double.tryParse(_salePriceController.text) ?? 0.0) - (double.tryParse(_purchasePriceController.text) ?? 0.0)).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (double.tryParse(
                                            _salePriceController.text) ??
                                        0.0) >
                                    (double.tryParse(
                                            _purchasePriceController.text) ??
                                        0.0)
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // 保存按鈕
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveBook,
                child: const Text('保存書籍'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
