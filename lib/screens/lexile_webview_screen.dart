import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

class LexileWebViewScreen extends StatefulWidget {
  final String searchQuery; // ISBN 優先，否則書名+作者

  const LexileWebViewScreen({super.key, required this.searchQuery});

  @override
  State<LexileWebViewScreen> createState() => _LexileWebViewScreenState();
}

class _LexileWebViewScreenState extends State<LexileWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() => _progress = progress);
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            final loc = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(loc.lexile_load_failed(error.description))),
            );
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://hub.lexile.com/find-a-book/').replace(
          queryParameters: {
            'searchText': widget.searchQuery,
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.lexile_title),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.clipboard_paste_tooltip,
            icon: const Icon(Icons.content_paste_go),
            onPressed: () async {
              final data = await Clipboard.getData('text/plain');
              final text = data?.text ?? '';
              final lexile = _parseLexile(text);
              if (lexile != null && context.mounted) {
                Navigator.of(context).pop(lexile);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            AppLocalizations.of(context)!.lexile_clipboard_none)),
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.refresh_tooltip,
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress > 0 && _progress < 100)
            LinearProgressIndicator(value: _progress / 100),
          Expanded(child: WebViewWidget(controller: _controller)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final controller = TextEditingController();
                    final result = await showDialog<int>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                            AppLocalizations.of(context)!.lexile_manual_title),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!
                                  .example_lexile_hint),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final v = int.tryParse(controller.text.trim());
                              Navigator.of(ctx).pop(v);
                            },
                            child:
                                Text(AppLocalizations.of(context)!.lexile_fill),
                          ),
                        ],
                      ),
                    );
                    if (result != null && context.mounted) {
                      Navigator.of(context).pop(result);
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label:
                      Text(AppLocalizations.of(context)!.lexile_manual_label),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int? _parseLexile(String text) {
    if (text.isEmpty) return null;
    final match = RegExp(r'lexile\s*:?\s*(\d+)\s*L', caseSensitive: false)
        .firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    // 後備：抓到第一個整數
    final m2 = RegExp(r'(\d{2,5})').firstMatch(text);
    if (m2 != null) return int.tryParse(m2.group(1)!);
    return null;
  }
}
