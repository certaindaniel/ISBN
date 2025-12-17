import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_source.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _prefsKey = 'enabled_api_sources';
  Map<ApiSource, bool> _enabled = {
    for (final info in ApiSourceRegistry.all) info.id: info.enabledByDefault,
  };
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<ApiSource> get enabledSources {
    return ApiSourceRegistry.all
        .where((item) => _enabled[item.id] ?? item.enabledByDefault)
        .map((item) => item.id)
        .toList();
  }

  bool isSourceEnabled(ApiSource source) {
    return _enabled[source] ?? ApiSourceRegistry.info(source).enabledByDefault;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey);
    if (stored != null && stored.isNotEmpty) {
      final parsed = stored
          .map((raw) => ApiSourceRegistry.fromId(raw))
          .whereType<ApiSource>()
          .toList();
      _enabled = {
        for (final info in ApiSourceRegistry.all)
          info.id: parsed.contains(info.id),
      };
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleSource(ApiSource source, bool enabled) async {
    _enabled[source] = enabled;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final enabledIds = _enabled.entries
        .where((entry) => entry.value)
        .map((entry) => ApiSourceRegistry.toId(entry.key))
        .toList();
    await prefs.setStringList(_prefsKey, enabledIds);
  }
}
