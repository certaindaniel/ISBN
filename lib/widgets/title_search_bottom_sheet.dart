import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/isbn_service.dart';
import '../l10n/app_localizations.dart';
import 'manual_isbn_dialog.dart';

class TitleSearchBottomSheet extends StatefulWidget {
  final Future<void> Function(String isbn)? onManualIsbn;

  const TitleSearchBottomSheet({super.key, this.onManualIsbn});

  @override
  State<TitleSearchBottomSheet> createState() => _TitleSearchBottomSheetState();
}

class _TitleSearchBottomSheetState extends State<TitleSearchBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  List<Book> _results = const [];
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final loc = AppLocalizations.of(context)!;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.please_enter_title),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final list = await IsbnService.searchByTitleAuthor(
        title,
        author: author.isEmpty ? null : author,
      );
      if (!mounted) return;
      setState(() => _results = list);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.query_failed_error(err)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _confirmClose() async {
    final loc = AppLocalizations.of(context)!;
    final hasChanges = _titleController.text.trim().isNotEmpty ||
        _authorController.text.trim().isNotEmpty ||
        _results.isNotEmpty ||
        _loading;
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
      await _doSearch();
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final shouldClose = await _confirmClose();
        if (shouldClose && mounted) {
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
                    final shouldClose = await _confirmClose();
                    if (shouldClose && mounted) {
                      Navigator.of(context).pop(false);
                    }
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: loc.label_title_required,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: loc.author_optional,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _doSearch(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _doSearch,
                icon: const Icon(Icons.search),
                label: Text(loc.search_button),
              ),
            ),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(),
            if (!_loading && _results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Text(
                      loc.no_results_text,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (widget.onManualIsbn != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: Text(loc.manual_isbn_label),
                          onPressed: () async {
                            final isbn = await showManualIsbnDialog(context);
                            if (isbn != null && isbn.isNotEmpty) {
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              await widget.onManualIsbn!(isbn);
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (!_loading && _results.isNotEmpty)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final b = _results[index];
                    return ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(b.title),
                      subtitle: Text('${b.author} • ISBN: ${b.isbn}'),
                      onTap: () {
                        Navigator.of(context).pop(b);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<Book?> showTitleSearchBottomSheet(BuildContext context,
    {Future<void> Function(String isbn)? onManualIsbn}) {
  return showModalBottomSheet<Book?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => TitleSearchBottomSheet(onManualIsbn: onManualIsbn),
  );
}
