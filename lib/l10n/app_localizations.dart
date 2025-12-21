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

  // Dialogs & prompts
  String get unsavedChangesTitle {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'CN') return '有未保存的更改';
        return '有未儲存的變更';
      default:
        return 'Unsaved changes';
    }
  }

  String get unsavedChangesContent {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'CN') return '您有未保存的更改，要保存后离开吗？';
        return '您有未儲存的變更，要儲存後離開嗎？';
      default:
        return 'You have unsaved changes. Save before leaving?';
    }
  }

  String get discard {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'CN') return '放棄變更';
        return '放棄變更';
      default:
        return 'Discard';
    }
  }

  String get saveAndLeave {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'CN') return '保存並離開';
        return '儲存並離開';
      default:
        return 'Save and leave';
    }
  }

  String get cancel {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'CN') return '取消';
        return '取消';
      default:
        return 'Cancel';
    }
  }

  String get unfinishedSearchTitle {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'CN') return '有未完成的查詢或變更';
        return '有未完成的查詢或變更';
      default:
        return 'Unfinished search or changes';
    }
  }

  String get unfinishedSearchContent {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'CN') return '您有尚未完成的查詢或輸入，要執行查詢、放棄變更還是繼續編輯？';
        return '您有尚未完成的查詢或輸入，要執行查詢、放棄變更還是繼續編輯？';
      default:
        return 'You have an unfinished search or input. Perform search, discard changes, or continue editing?';
    }
  }

  String get performSearch {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'CN') return '執行查詢';
        return '執行查詢';
      default:
        return 'Search';
    }
  }

  String get pleaseFillRequiredFields {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'CN') return '請填入所有必填欄位';
        return '請填入所有必填欄位';
      default:
        return 'Please fill all required fields';
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
