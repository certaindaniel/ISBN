import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/api_source.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'API 測試',
            onPressed: () {
              Navigator.of(context).pushNamed('/api-test');
            },
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          if (!settings.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final enabledCount = settings.enabledSources.length;

          return ListView(
            children: [
              ListTile(
                title: Text(
                    '已啟用來源：$enabledCount / ${ApiSourceRegistry.all.length}'),
                subtitle: const Text('可切換使用的 ISBN 查詢來源，依序嘗試'),
              ),
              const Divider(height: 1),
              ...ApiSourceRegistry.all.map(
                (info) => SwitchListTile(
                  title: Text(info.displayName),
                  subtitle: Text(info.description),
                  value: settings.isSourceEnabled(info.id),
                  onChanged: (value) {
                    settings.toggleSource(info.id, value);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '系統會依照上列順序逐一查詢，失敗時自動換下一個來源。所有 API 均為免費來源，第三方來源穩定度可能較低。',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const Divider(height: 32, thickness: 8),
              const ListTile(
                title: Text(
                  '常用查詢網頁',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('手動查詢書籍資訊'),
              ),
              ListTile(
                leading: const Icon(Icons.public, color: Colors.blue),
                title: const Text('台灣國家圖書館 ISBN'),
                subtitle: const Text('查詢台灣出版書籍資訊'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  final uri = Uri.parse(
                      'https://isbn.ncl.edu.tw/NEW_ISBNNet/main_DisplayResults.php?Pact=DisplayAll4Simple');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.book, color: Colors.orange),
                title: const Text('博客來'),
                subtitle: const Text('台灣最大網路書店'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  final uri = Uri.parse('https://www.books.com.tw/');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.library_books, color: Colors.green),
                title: const Text('誠品書店'),
                subtitle: const Text('誠品線上書店'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  final uri = Uri.parse('https://www.eslite.com/');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.search, color: Colors.red),
                title: const Text('Google Books'),
                subtitle: const Text('全球書籍資料庫'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  final uri = Uri.parse('https://books.google.com/');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
