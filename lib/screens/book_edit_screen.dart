import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// 使用內嵌 WebView 顯示 Lexile 查詢
import 'lexile_webview_screen.dart';
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
  late TextEditingController _lexileScoreController;

  late DateTime _purchaseDate;
  DateTime? _saleDate;
  String? _language;
  late String _readStatus; // 'unread' | 'reading' | 'read'

  File? _pickedImage;
  final ImagePicker _imagePicker = ImagePicker();

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
    _lexileScoreController = TextEditingController(
      text: book?.lexileScore?.toString() ?? '',
    );

    _purchaseDate = book?.purchaseDate ?? DateTime.now();
    _saleDate = book?.saleDate;
    _language = book?.language;
    _readStatus = book?.status ?? 'unread';
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
    _lexileScoreController.dispose();
    super.dispose();
  }

  bool _hasUnsavedChanges() {
    final book = widget.initialBook;
    if (book == null) {
      // 新增模式：若任一欄位非空或有選圖即視為已修改
      return _titleController.text.isNotEmpty ||
          _authorController.text.isNotEmpty ||
          _publisherController.text.isNotEmpty ||
          _descriptionController.text.isNotEmpty ||
          _isbnController.text.isNotEmpty ||
          _purchasePriceController.text.isNotEmpty ||
          _salePriceController.text.isNotEmpty ||
          _lexileScoreController.text.isNotEmpty ||
          _pickedImage != null;
    }

    // 編輯模式：比對與初始值是否不同
    if (_titleController.text.trim() != book.title) {
      return true;
    }
    if (_authorController.text.trim() != book.author) {
      return true;
    }
    if (_publisherController.text.trim() != book.publisher) {
      return true;
    }
    if (_descriptionController.text.trim() != (book.description ?? '')) {
      return true;
    }
    if (_isbnController.text.trim() != book.isbn) {
      return true;
    }
    if (_purchasePriceController.text.trim() != book.purchasePrice.toString()) {
      return true;
    }
    if (_salePriceController.text.trim() != (book.salePrice?.toString() ?? '')) {
      return true;
    }
    if (_lexileScoreController.text.trim() != (book.lexileScore?.toString() ?? '')) {
      return true;
    }
    if (_purchaseDate != book.purchaseDate) {
      return true;
    }
    // 比對售出日期（含 null 與不同值）
    if (_saleDate != book.saleDate) {
      return true;
    }
    if ((_pickedImage != null &&
        (book.coverUrl == null || _pickedImage!.path != book.coverUrl)))
      return true;
    if (_language != book.language) return true;
    if (_readStatus != (book.status ?? 'unread')) return true;

    return false;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges()) return true;

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('有未儲存的變更'),
        content: const Text('您有未儲存的變更，要儲存後離開嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: const Text('放棄變更'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('save'),
            child: const Text('儲存並離開'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _saveBook();
      // _saveBook 內在成功時會 pop，為避免雙重 pop，回傳 false
      return false;
    }

    if (result == 'discard') {
      return true;
    }

    // cancel 或 null
    return false;
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

  Future<void> _openLexileSearch() async {
    // 優先使用 ISBN，其次使用 書名+作者
    final isbn = _isbnController.text.trim();
    final fallback =
        '${_titleController.text} ${_authorController.text}'.trim();
    final query = isbn.isNotEmpty ? isbn : fallback;
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先填入書名與作者再查詢 Lexile')),
      );
      return;
    }

    if (!mounted) return;
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LexileWebViewScreen(searchQuery: query),
      ),
    );
    if (!mounted) return;
    if (result is int) {
      setState(() {
        _lexileScoreController.text = result.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已回填 Lexile：${result}L')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已拍攝書籍封面')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拍照失敗: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildCoverImage(String coverUrl) {
    // 判斷是本地檔案還是網路圖片
    if (coverUrl.startsWith('/') || coverUrl.startsWith('file://')) {
      final path = coverUrl.replaceFirst('file://', '');
      return Image.file(
        File(path),
        width: 120,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 120,
          height: 180,
          color: Colors.grey[300],
          child: const Icon(Icons.book),
        ),
      );
    } else {
      return Image.network(
        coverUrl,
        width: 120,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 120,
          height: 180,
          color: Colors.grey[300],
          child: const Icon(Icons.book),
        ),
      );
    }
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English (英文)';
      case 'zh':
        return 'Chinese (中文)';
      case 'ja':
        return 'Japanese (日文)';
      default:
        return languageCode;
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

    // 優先使用本地拍攝的圖片，否則使用原有的 coverUrl
    String? finalCoverUrl = widget.initialBook?.coverUrl;
    if (_pickedImage != null) {
      finalCoverUrl = _pickedImage!.path;
    }

    final book = Book(
      id: widget.initialBook?.id,
      isbn: _isbnController.text.trim(),
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      publisher: _publisherController.text.trim(),
      coverUrl: finalCoverUrl,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      purchasePrice: double.parse(_purchasePriceController.text),
      salePrice: _salePriceController.text.isNotEmpty
          ? double.parse(_salePriceController.text)
          : null,
      purchaseDate: _purchaseDate,
      saleDate: _saleDate,
      language: _language,
      lexileScore: _lexileScoreController.text.isNotEmpty
          ? int.tryParse(_lexileScoreController.text)
          : null,
      status: _readStatus,
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 顯示圖片
                    if (_pickedImage != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withAlpha((0.2 * 255).round()),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _pickedImage!,
                            width: 120,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else if (widget.initialBook?.coverUrl != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withAlpha((0.2 * 255).round()),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              _buildCoverImage(widget.initialBook!.coverUrl!),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha((0.1 * 255).round()),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '拍攝封面',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // 重拍按鈕（有圖時才顯示）
                    if (_pickedImage != null ||
                        widget.initialBook?.coverUrl != null)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: FloatingActionButton.small(
                          onPressed: _pickImage,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.camera_alt, size: 20),
                        ),
                      ),
                  ],
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

              // 書籍語言
              if (_language != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.language, size: 20),
                      const SizedBox(width: 12),
                      Text('語言: ${_getLanguageName(_language!)}'),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              if (_language != null) const SizedBox(height: 16),

              // 閱讀狀態切換（三段）
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _readStatus == 'read'
                              ? Icons.check_circle
                              : _readStatus == 'reading'
                                  ? Icons.menu_book
                                  : Icons.circle_outlined,
                          color: _readStatus == 'read'
                              ? Colors.green
                              : _readStatus == 'reading'
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _readStatus == 'read'
                              ? '已讀'
                              : _readStatus == 'reading'
                                  ? '閱讀中'
                                  : '未讀',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'unread', label: Text('未讀')),
                        ButtonSegment(value: 'reading', label: Text('閱讀中')),
                        ButtonSegment(value: 'read', label: Text('已讀')),
                      ],
                      selected: {_readStatus},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _readStatus = selection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 藍思值 (Lexile) - 英文書適用，可手動填寫
              TextField(
                controller: _lexileScoreController,
                decoration: InputDecoration(
                  labelText: '藍思值 (Lexile Measure)',
                  border: const OutlineInputBorder(),
                  hintText: '例: 850',
                  helperText:
                      _language == 'en' ? '英文書籍的閱讀難度指標' : '主要用於英文書籍，若非英文可留空',
                  prefixIcon: const Icon(Icons.auto_graph),
                  suffixIcon: IconButton(
                    tooltip: '到 Lexile 查詢',
                    onPressed: _openLexileSearch,
                    icon: const Icon(Icons.open_in_new),
                  ),
                ),
                keyboardType: TextInputType.number,
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
      ),
    );
  }
}
