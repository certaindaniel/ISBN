// Minimal manual localization fallback to allow analysis/build before generated files exist.
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh', 'TW'),
    Locale('zh', 'CN'),
  ];

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get appTitle {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'CN') return 'ISBN 书籍管理';
        return 'ISBN 書籍管理';
      default:
        return 'ISBN Book Manager';
    }
  }

  String get books {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'CN') return '书籍';
        return '書籍';
      default:
        return 'Books';
    }
  }

  String get statistics {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'CN') return '统计';
        return '統計';
      default:
        return 'Statistics';
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
