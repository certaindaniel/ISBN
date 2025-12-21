import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/api_source.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings_title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: AppLocalizations.of(context)!.api_test_title,
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
                title: Text(loc.settings_enabled_sources(enabledCount, ApiSourceRegistry.all.length)),
                subtitle: Text(loc.settings_sources_subtitle),
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  loc.settings_sources_explain,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const Divider(height: 32, thickness: 8),
              ListTile(
                title: Text(
                  loc.settings_common_websites_title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(loc.settings_manual_query_subtitle),
              ),
              ListTile(
                leading: const Icon(Icons.public, color: Colors.blue),
                title: Text(loc.settings_tnla_title),
                subtitle: Text(loc.settings_tnla_subtitle),
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
                title: Text(loc.settings_bok_title),
                subtitle: Text(loc.settings_bok_subtitle),
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
                title: Text(loc.settings_eslite_title),
                subtitle: Text(loc.settings_eslite_subtitle),
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
                title: Text(loc.settings_google_title),
                subtitle: Text(loc.settings_google_subtitle),
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
