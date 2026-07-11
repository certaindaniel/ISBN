import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ISBN Book Manager'**
  String get appTitle;

  /// No description provided for @books.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get books;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesContent.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Save before leaving?'**
  String get unsavedChangesContent;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @saveAndLeave.
  ///
  /// In en, this message translates to:
  /// **'Save and leave'**
  String get saveAndLeave;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @unfinishedSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfinished search or changes'**
  String get unfinishedSearchTitle;

  /// No description provided for @unfinishedSearchContent.
  ///
  /// In en, this message translates to:
  /// **'You have an unfinished search or input. Perform search, discard changes, or continue editing?'**
  String get unfinishedSearchContent;

  /// No description provided for @performSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get performSearch;

  /// No description provided for @pleaseFillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillRequiredFields;

  /// No description provided for @bookList_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Please enter title'**
  String get bookList_search_hint;

  /// No description provided for @search_failed.
  ///
  /// In en, this message translates to:
  /// **'Search failed: {error}'**
  String search_failed(Object error);

  /// No description provided for @search_button.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search_button;

  /// No description provided for @manual_isbn_label.
  ///
  /// In en, this message translates to:
  /// **'Manual ISBN'**
  String get manual_isbn_label;

  /// No description provided for @manual_isbn_title.
  ///
  /// In en, this message translates to:
  /// **'Manual ISBN'**
  String get manual_isbn_title;

  /// No description provided for @book_added.
  ///
  /// In en, this message translates to:
  /// **'Book added'**
  String get book_added;

  /// No description provided for @book_deleted.
  ///
  /// In en, this message translates to:
  /// **'Book deleted'**
  String get book_deleted;

  /// No description provided for @delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete confirmation'**
  String get delete_confirm_title;

  /// No description provided for @delete_confirm_content.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this book?'**
  String get delete_confirm_content;

  /// No description provided for @delete_action.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete_action;

  /// No description provided for @my_books_title.
  ///
  /// In en, this message translates to:
  /// **'My books'**
  String get my_books_title;

  /// No description provided for @filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filter_all;

  /// No description provided for @filter_unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filter_unread;

  /// No description provided for @filter_reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get filter_reading;

  /// No description provided for @filter_read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get filter_read;

  /// No description provided for @empty_hint.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or add a book'**
  String get empty_hint;

  /// No description provided for @search_by_title_title.
  ///
  /// In en, this message translates to:
  /// **'Search by title'**
  String get search_by_title_title;

  /// No description provided for @search_by_title_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter title/author, search Google Books'**
  String get search_by_title_subtitle;

  /// No description provided for @scan_title.
  ///
  /// In en, this message translates to:
  /// **'Scan ISBN'**
  String get scan_title;

  /// No description provided for @scan_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Use camera to scan (supports 978/979)'**
  String get scan_subtitle;

  /// No description provided for @lexile_label.
  ///
  /// In en, this message translates to:
  /// **'Lexile: {score}L'**
  String lexile_label(Object score);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @lexile_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String lexile_load_failed(Object error);

  /// No description provided for @lexile_clipboard_none.
  ///
  /// In en, this message translates to:
  /// **'No Lexile value detected in clipboard'**
  String get lexile_clipboard_none;

  /// No description provided for @lexile_manual_title.
  ///
  /// In en, this message translates to:
  /// **'Manual Lexile input'**
  String get lexile_manual_title;

  /// No description provided for @lexile_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get lexile_cancel;

  /// No description provided for @lexile_fill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get lexile_fill;

  /// No description provided for @lexile_manual_label.
  ///
  /// In en, this message translates to:
  /// **'Manual input'**
  String get lexile_manual_label;

  /// No description provided for @statistics_title.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics_title;

  /// No description provided for @stats_reading_label.
  ///
  /// In en, this message translates to:
  /// **'Reading: {count} books'**
  String stats_reading_label(Object count);

  /// No description provided for @stats_unread_label.
  ///
  /// In en, this message translates to:
  /// **'Unread: {count} books'**
  String stats_unread_label(Object count);

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_sources_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Toggle ISBN sources to try in order'**
  String get settings_sources_subtitle;

  /// No description provided for @settings_manual_query_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manual book lookup'**
  String get settings_manual_query_subtitle;

  /// No description provided for @settings_tnla_title.
  ///
  /// In en, this message translates to:
  /// **'Taiwan National Library ISBN'**
  String get settings_tnla_title;

  /// No description provided for @settings_tnla_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Lookup Taiwan-published books'**
  String get settings_tnla_subtitle;

  /// No description provided for @settings_bok_title.
  ///
  /// In en, this message translates to:
  /// **'Books.com.tw'**
  String get settings_bok_title;

  /// No description provided for @settings_bok_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Taiwan\'s largest online bookstore'**
  String get settings_bok_subtitle;

  /// No description provided for @settings_openlibrary_title.
  ///
  /// In en, this message translates to:
  /// **'Open Library'**
  String get settings_openlibrary_title;

  /// No description provided for @settings_openlibrary_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Free open bibliographic data'**
  String get settings_openlibrary_subtitle;

  /// No description provided for @settings_eslite_title.
  ///
  /// In en, this message translates to:
  /// **'Eslite'**
  String get settings_eslite_title;

  /// No description provided for @settings_eslite_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Eslite online bookstore'**
  String get settings_eslite_subtitle;

  /// No description provided for @settings_google_title.
  ///
  /// In en, this message translates to:
  /// **'Google Books'**
  String get settings_google_title;

  /// No description provided for @settings_google_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Global books database'**
  String get settings_google_subtitle;

  /// No description provided for @settings_wikipedia_title.
  ///
  /// In en, this message translates to:
  /// **'Wikipedia'**
  String get settings_wikipedia_title;

  /// No description provided for @settings_wikipedia_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Supplementary bibliographic data from Wikipedia'**
  String get settings_wikipedia_subtitle;

  /// No description provided for @settings_jike_title.
  ///
  /// In en, this message translates to:
  /// **'Community Chinese API'**
  String get settings_jike_title;

  /// No description provided for @settings_jike_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Community-maintained Chinese book info (unstable)'**
  String get settings_jike_subtitle;

  /// No description provided for @lexile_title.
  ///
  /// In en, this message translates to:
  /// **'Lexile Lookup'**
  String get lexile_title;

  /// No description provided for @no_results_text.
  ///
  /// In en, this message translates to:
  /// **'No results (or no usable ISBN)'**
  String get no_results_text;

  /// No description provided for @manual_isbn_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter 10 or 13 digit ISBN'**
  String get manual_isbn_hint;

  /// No description provided for @please_enter_isbn.
  ///
  /// In en, this message translates to:
  /// **'Please enter ISBN'**
  String get please_enter_isbn;

  /// No description provided for @scan_area_hint.
  ///
  /// In en, this message translates to:
  /// **'Place the book barcode in the scan area'**
  String get scan_area_hint;

  /// No description provided for @book_not_found.
  ///
  /// In en, this message translates to:
  /// **'No book information found'**
  String get book_not_found;

  /// No description provided for @filter_no_books.
  ///
  /// In en, this message translates to:
  /// **'No books for this filter'**
  String get filter_no_books;

  /// No description provided for @refresh_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh_tooltip;

  /// No description provided for @example_lexile_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g.: 850'**
  String get example_lexile_hint;

  /// No description provided for @clipboard_paste_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get clipboard_paste_tooltip;

  /// No description provided for @author_optional.
  ///
  /// In en, this message translates to:
  /// **'Author (optional)'**
  String get author_optional;

  /// No description provided for @new_book.
  ///
  /// In en, this message translates to:
  /// **'New Book'**
  String get new_book;

  /// No description provided for @edit_book.
  ///
  /// In en, this message translates to:
  /// **'Edit Book'**
  String get edit_book;

  /// No description provided for @lexile_need_title_author.
  ///
  /// In en, this message translates to:
  /// **'Please enter title and author before searching Lexile'**
  String get lexile_need_title_author;

  /// No description provided for @lexile_refilled.
  ///
  /// In en, this message translates to:
  /// **'Lexile filled: {value}L'**
  String lexile_refilled(Object value);

  /// No description provided for @photo_taken.
  ///
  /// In en, this message translates to:
  /// **'Photo captured'**
  String get photo_taken;

  /// No description provided for @photo_failed.
  ///
  /// In en, this message translates to:
  /// **'Photo failed: {error}'**
  String photo_failed(Object error);

  /// No description provided for @book_saved.
  ///
  /// In en, this message translates to:
  /// **'Book saved'**
  String get book_saved;

  /// No description provided for @save_failed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get save_failed;

  /// No description provided for @save_book_button.
  ///
  /// In en, this message translates to:
  /// **'Save Book'**
  String get save_book_button;

  /// No description provided for @label_title_required.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get label_title_required;

  /// No description provided for @label_author_required.
  ///
  /// In en, this message translates to:
  /// **'Author *'**
  String get label_author_required;

  /// No description provided for @label_publisher_required.
  ///
  /// In en, this message translates to:
  /// **'Publisher *'**
  String get label_publisher_required;

  /// No description provided for @label_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get label_description;

  /// No description provided for @label_purchase_price_required.
  ///
  /// In en, this message translates to:
  /// **'Purchase price (NT\$) *'**
  String get label_purchase_price_required;

  /// No description provided for @label_sale_price.
  ///
  /// In en, this message translates to:
  /// **'Sale price (NT\$)'**
  String get label_sale_price;

  /// No description provided for @purchase_date_title.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get purchase_date_title;

  /// No description provided for @sale_date_title.
  ///
  /// In en, this message translates to:
  /// **'Sale Date'**
  String get sale_date_title;

  /// No description provided for @set_sale_date_label.
  ///
  /// In en, this message translates to:
  /// **'Set sale date'**
  String get set_sale_date_label;

  /// No description provided for @profit_label.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit_label;

  /// No description provided for @settings_enabled_sources.
  ///
  /// In en, this message translates to:
  /// **'Enabled sources: {enabled} / {total}'**
  String settings_enabled_sources(Object enabled, Object total);

  /// No description provided for @settings_sources_explain.
  ///
  /// In en, this message translates to:
  /// **'The system will try enabled sources in order and fall back to the next if a source fails. All APIs are free third-party services and may vary in reliability.'**
  String get settings_sources_explain;

  /// No description provided for @statistics_tab_reading.
  ///
  /// In en, this message translates to:
  /// **'Reading Stats'**
  String get statistics_tab_reading;

  /// No description provided for @statistics_tab_finance.
  ///
  /// In en, this message translates to:
  /// **'Finance Stats'**
  String get statistics_tab_finance;

  /// No description provided for @stat_overview_title.
  ///
  /// In en, this message translates to:
  /// **'Reading Overview'**
  String get stat_overview_title;

  /// No description provided for @stat_total_books.
  ///
  /// In en, this message translates to:
  /// **'Total books'**
  String get stat_total_books;

  /// No description provided for @stat_read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get stat_read;

  /// No description provided for @stat_reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get stat_reading;

  /// No description provided for @stat_unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get stat_unread;

  /// No description provided for @stat_completion_title.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get stat_completion_title;

  /// No description provided for @finance_title.
  ///
  /// In en, this message translates to:
  /// **'Finance Overview'**
  String get finance_title;

  /// No description provided for @finance_total_spent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get finance_total_spent;

  /// No description provided for @finance_total_earned.
  ///
  /// In en, this message translates to:
  /// **'Total earned'**
  String get finance_total_earned;

  /// No description provided for @finance_total_profit.
  ///
  /// In en, this message translates to:
  /// **'Total profit'**
  String get finance_total_profit;

  /// No description provided for @settings_common_websites_title.
  ///
  /// In en, this message translates to:
  /// **'Common lookup websites'**
  String get settings_common_websites_title;

  /// No description provided for @take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get take_photo;

  /// No description provided for @language_label.
  ///
  /// In en, this message translates to:
  /// **'Language: {value}'**
  String language_label(Object value);

  /// No description provided for @label_lexile.
  ///
  /// In en, this message translates to:
  /// **'Lexile (Measure)'**
  String get label_lexile;

  /// No description provided for @profit_calculation.
  ///
  /// In en, this message translates to:
  /// **'Profit calculation'**
  String get profit_calculation;

  /// No description provided for @no_enabled_sources.
  ///
  /// In en, this message translates to:
  /// **'No ISBN sources enabled, please enable sources in Settings'**
  String get no_enabled_sources;

  /// No description provided for @searching_title.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching_title;

  /// No description provided for @source_label.
  ///
  /// In en, this message translates to:
  /// **'Source: {value}'**
  String source_label(Object value);

  /// No description provided for @cannot_find_book.
  ///
  /// In en, this message translates to:
  /// **'Unable to find book information'**
  String get cannot_find_book;

  /// No description provided for @api_test_title.
  ///
  /// In en, this message translates to:
  /// **'ISBN API Test'**
  String get api_test_title;

  /// No description provided for @api_test_start.
  ///
  /// In en, this message translates to:
  /// **'Start tests'**
  String get api_test_start;

  /// No description provided for @api_test_running.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get api_test_running;

  /// No description provided for @api_test_output_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Start tests\" to run API tests...'**
  String get api_test_output_placeholder;

  /// No description provided for @scan_not_isbn_ean.
  ///
  /// In en, this message translates to:
  /// **'Please scan an ISBN barcode; this is an EAN'**
  String get scan_not_isbn_ean;

  /// No description provided for @please_enter_title.
  ///
  /// In en, this message translates to:
  /// **'Please enter title'**
  String get please_enter_title;

  /// No description provided for @query_failed_error.
  ///
  /// In en, this message translates to:
  /// **'Query failed: {error}'**
  String query_failed_error(Object error);

  /// No description provided for @error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error_prefix(Object message);

  /// No description provided for @isbn_error_invalid_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid ISBN format'**
  String get isbn_error_invalid_format;

  /// No description provided for @provider_book_record_sale_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to record sale: {error}'**
  String provider_book_record_sale_failed(Object error);

  /// No description provided for @isbn_already_exists.
  ///
  /// In en, this message translates to:
  /// **'ISBN already exists in database'**
  String get isbn_already_exists;

  /// No description provided for @cannot_find_isbn_ncl.
  ///
  /// In en, this message translates to:
  /// **'Unable to find book information. See: {url}'**
  String cannot_find_isbn_ncl(Object url);

  /// No description provided for @load_books_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load books: {error}'**
  String load_books_failed(Object error);

  /// No description provided for @add_book_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add book: {error}'**
  String add_book_failed(Object error);

  /// No description provided for @update_book_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update book: {error}'**
  String update_book_failed(Object error);

  /// No description provided for @delete_book_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete book: {error}'**
  String delete_book_failed(Object error);

  /// No description provided for @settings_rate_title.
  ///
  /// In en, this message translates to:
  /// **'Rate this App'**
  String get settings_rate_title;

  /// No description provided for @settings_rate_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoying the app? Leave us a review'**
  String get settings_rate_subtitle;

  /// No description provided for @free_limit_reached.
  ///
  /// In en, this message translates to:
  /// **'Free version limit of {limit} books reached. Unlock unlimited books to continue.'**
  String free_limit_reached(int limit);

  /// No description provided for @paywall_title.
  ///
  /// In en, this message translates to:
  /// **'Unlock Unlimited Books'**
  String get paywall_title;

  /// No description provided for @paywall_subtitle.
  ///
  /// In en, this message translates to:
  /// **'The free version stores up to {limit} books. Unlock once, keep cataloging forever.'**
  String paywall_subtitle(int limit);

  /// No description provided for @paywall_feature_unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited books in your library'**
  String get paywall_feature_unlimited;

  /// No description provided for @paywall_feature_profit.
  ///
  /// In en, this message translates to:
  /// **'Full profit tracking and statistics, always free'**
  String get paywall_feature_profit;

  /// No description provided for @paywall_feature_once.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase — no subscription'**
  String get paywall_feature_once;

  /// No description provided for @paywall_buy.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {price}'**
  String paywall_buy(String price);

  /// No description provided for @paywall_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get paywall_restore;

  /// No description provided for @paywall_unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlimited books unlocked'**
  String get paywall_unlocked;

  /// No description provided for @paywall_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Store unavailable'**
  String get paywall_unavailable;

  /// No description provided for @settings_unlock_title.
  ///
  /// In en, this message translates to:
  /// **'Unlock Unlimited Books'**
  String get settings_unlock_title;

  /// No description provided for @settings_unlock_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Free version: up to {limit} books'**
  String settings_unlock_subtitle(int limit);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
