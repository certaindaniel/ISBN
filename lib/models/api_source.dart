import '../l10n/app_localizations.dart';

enum ApiSource {
  googleBooks,
  openLibrary,
  wikipedia,
  jikeFree,
}

class ApiSourceInfo {
  final ApiSource id;
  final String displayName;
  final String description;
  final bool enabledByDefault;
  final bool requiresKey;
  final String baseUrl;

  const ApiSourceInfo({
    required this.id,
    required this.displayName,
    required this.description,
    required this.enabledByDefault,
    required this.requiresKey,
    required this.baseUrl,
  });

  String localizedName(AppLocalizations loc) {
    switch (id) {
      case ApiSource.googleBooks:
        return loc.settings_google_title;
      case ApiSource.openLibrary:
        return loc.settings_openlibrary_title;
      case ApiSource.wikipedia:
        return loc.settings_wikipedia_title;
      case ApiSource.jikeFree:
        return loc.settings_jike_title;
    }
  }

  String localizedDescription(AppLocalizations loc) {
    switch (id) {
      case ApiSource.googleBooks:
        return loc.settings_google_subtitle;
      case ApiSource.openLibrary:
        return loc.settings_openlibrary_subtitle;
      case ApiSource.wikipedia:
        return loc.settings_wikipedia_subtitle;
      case ApiSource.jikeFree:
        return loc.settings_jike_subtitle;
    }
  }
}

class ApiSourceRegistry {
  static const List<ApiSourceInfo> all = [
    ApiSourceInfo(
      id: ApiSource.googleBooks,
      displayName: 'Google Books',
      description: '',
      enabledByDefault: true,
      requiresKey: false,
      baseUrl: 'https://www.googleapis.com/books/v1/volumes?q=isbn=',
    ),
    ApiSourceInfo(
      id: ApiSource.openLibrary,
      displayName: 'Open Library',
      description: '',
      enabledByDefault: true,
      requiresKey: false,
      baseUrl: 'https://openlibrary.org/api/books?bibkeys=ISBN:',
    ),
    ApiSourceInfo(
      id: ApiSource.wikipedia,
      displayName: 'Wikipedia',
      description: '',
      enabledByDefault: false,
      requiresKey: false,
      baseUrl:
          'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=',
    ),
    ApiSourceInfo(
      id: ApiSource.jikeFree,
      displayName: 'Jike Free',
      description: '',
      enabledByDefault: false,
      requiresKey: false,
      baseUrl: 'https://api.jike.xyz/situ/book/isbn/',
    )
  ];

  static ApiSourceInfo info(ApiSource source) {
    return all.firstWhere((item) => item.id == source);
  }

  static String localizedName(AppLocalizations loc, ApiSource source) {
    switch (source) {
      case ApiSource.googleBooks:
        return loc.settings_google_title;
      case ApiSource.openLibrary:
        return loc.settings_openlibrary_title;
      case ApiSource.wikipedia:
        return loc.settings_wikipedia_title;
      case ApiSource.jikeFree:
        return loc.settings_jike_title;
    }
  }

  static String localizedDescription(AppLocalizations loc, ApiSource source) {
    switch (source) {
      case ApiSource.googleBooks:
        return loc.settings_google_subtitle;
      case ApiSource.openLibrary:
        return loc.settings_openlibrary_subtitle;
      case ApiSource.wikipedia:
        return loc.settings_wikipedia_subtitle;
      case ApiSource.jikeFree:
        return loc.settings_jike_subtitle;
    }
  }

  static List<ApiSource> defaultEnabled() {
    return all
        .where((item) => item.enabledByDefault)
        .map((item) => item.id)
        .toList();
  }

  static ApiSource? fromId(String raw) {
    try {
      return ApiSource.values.firstWhere((s) => s.name == raw);
    } catch (_) {
      return null;
    }
  }

  static String toId(ApiSource source) => source.name;
}
