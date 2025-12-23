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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.manual_isbn_title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: loc.manual_isbn_hint,
        ),
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
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
    );
  }
}

Future<String?> showManualIsbnDialog(BuildContext context) {
  return showDialog<String?>(
    context: context,
    builder: (ctx) => const ManualIsbnDialog(),
  );
}
