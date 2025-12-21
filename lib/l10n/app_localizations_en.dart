// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ISBN Book Manager';

  @override
  String get books => 'Books';

  @override
  String get statistics => 'Statistics';

  @override
  String get unsavedChangesTitle => 'Unsaved changes';

  @override
  String get unsavedChangesContent => 'You have unsaved changes. Save before leaving?';

  @override
  String get discard => 'Discard';

  @override
  String get saveAndLeave => 'Save and leave';

  @override
  String get cancel => 'Cancel';

  @override
  String get unfinishedSearchTitle => 'Unfinished search or changes';

  @override
  String get unfinishedSearchContent => 'You have an unfinished search or input. Perform search, discard changes, or continue editing?';

  @override
  String get performSearch => 'Search';

  @override
  String get pleaseFillRequiredFields => 'Please fill all required fields';
}
