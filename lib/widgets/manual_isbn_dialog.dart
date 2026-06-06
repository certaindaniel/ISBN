import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ManualIsbnDialog extends StatefulWidget {
  const ManualIsbnDialog({super.key});

  @override
  State<ManualIsbnDialog> createState() => _ManualIsbnDialogState();
}

class _ManualIsbnDialogState extends State<ManualIsbnDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final isbn = _controller.text.trim();
    if (isbn.isEmpty) return true;

    final loc = AppLocalizations.of(context)!;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      ),
    );

    if (choice == 'discard') return true;
    if (choice == 'search') {
      Navigator.of(context).pop(isbn);
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
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(null);
        }
      },
      child: AlertDialog(
        title: Text(loc.manual_isbn_title),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: loc.manual_isbn_hint,
          ),
          keyboardType: TextInputType.number,
          onSubmitted: (value) {
            final isbn = value.trim();
            if (isbn.isNotEmpty) {
              Navigator.of(context).pop(isbn);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop(null);
              }
            },
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              final isbn = _controller.text.trim();
              Navigator.of(context).pop(isbn);
            },
            child: Text(loc.search_button),
          ),
        ],
      ),
    );
  }
}

Future<String?> showManualIsbnDialog(BuildContext context) {
  return showDialog<String?>(
    context: context,
    builder: (ctx) => const ManualIsbnDialog(),
  );
}
