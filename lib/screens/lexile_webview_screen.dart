import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('載入失敗: ${error.description}')),
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
        title: const Text('Lexile 查詢'),
        actions: [
          IconButton(
            tooltip: '貼上回填',
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
                    const SnackBar(content: Text('剪貼簿未偵測到 Lexile 值')),
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: '重新整理',
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
                        title: const Text('手動輸入 Lexile 值'),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '例如：850'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final v = int.tryParse(controller.text.trim());
                              Navigator.of(ctx).pop(v);
                            },
                            child: const Text('回填'),
                          ),
                        ],
                      ),
                    );
                    if (result != null && context.mounted) {
                      Navigator.of(context).pop(result);
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('手動輸入'),
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
