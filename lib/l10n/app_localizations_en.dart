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
  String get unsavedChangesContent =>
      'You have unsaved changes. Save before leaving?';

  @override
  String get discard => 'Discard';

  @override
  String get saveAndLeave => 'Save and leave';

  @override
  String get cancel => 'Cancel';

  @override
  String get unfinishedSearchTitle => 'Unfinished search or changes';

  @override
  String get unfinishedSearchContent =>
      'You have an unfinished search or input. Perform search, discard changes, or continue editing?';

  @override
  String get performSearch => 'Search';

  @override
  String get pleaseFillRequiredFields => 'Please fill all required fields';

  @override
  String get bookList_search_hint => 'Please enter title';

  @override
  String search_failed(Object error) {
    return 'Search failed: $error';
  }

  @override
  String get search_button => 'Search';

  @override
  String get manual_isbn_label => 'Manual ISBN';

  @override
  String get manual_isbn_title => 'Manual ISBN';

  @override
  String get book_added => 'Book added';

  @override
  String get book_deleted => 'Book deleted';

  @override
  String get delete_confirm_title => 'Delete confirmation';

  @override
  String get delete_confirm_content =>
      'Are you sure you want to delete this book?';

  @override
  String get delete_action => 'Delete';

  @override
  String get my_books_title => 'My books';

  @override
  String get filter_all => 'All';

  @override
  String get filter_unread => 'Unread';

  @override
  String get filter_reading => 'Reading';

  @override
  String get filter_read => 'Read';

  @override
  String get empty_hint => 'Try a different filter or add a book';

  @override
  String get search_by_title_title => 'Search by title';

  @override
  String get search_by_title_subtitle =>
      'Enter title/author, search Google Books';

  @override
  String get scan_title => 'Scan ISBN';

  @override
  String get scan_subtitle => 'Use camera to scan (supports 978/979)';

  @override
  String lexile_label(Object score) {
    return 'Lexile: ${score}L';
  }

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String lexile_load_failed(Object error) {
    return 'Load failed: $error';
  }

  @override
  String get lexile_clipboard_none => 'No Lexile value detected in clipboard';

  @override
  String get lexile_manual_title => 'Manual Lexile input';

  @override
  String get lexile_cancel => 'Cancel';

  @override
  String get lexile_fill => 'Fill';

  @override
  String get lexile_manual_label => 'Manual input';

  @override
  String get statistics_title => 'Statistics';

  @override
  String stats_reading_label(Object count) {
    return 'Reading: $count books';
  }

  @override
  String stats_unread_label(Object count) {
    return 'Unread: $count books';
  }

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_sources_subtitle => 'Toggle ISBN sources to try in order';

  @override
  String get settings_manual_query_subtitle => 'Manual book lookup';

  @override
  String get settings_tnla_title => 'Taiwan National Library ISBN';

  @override
  String get settings_tnla_subtitle => 'Lookup Taiwan-published books';

  @override
  String get settings_bok_title => 'Books.com.tw';

  @override
  String get settings_bok_subtitle => 'Taiwan\'s largest online bookstore';

  @override
  String get settings_eslite_title => 'Eslite';

  @override
  String get settings_eslite_subtitle => 'Eslite online bookstore';

  @override
  String get settings_google_title => 'Google Books';

  @override
  String get settings_google_subtitle => 'Global books database';

  @override
  String get lexile_title => 'Lexile Lookup';

  @override
  String get no_results_text => 'No results (or no usable ISBN)';

  @override
  String get manual_isbn_hint => 'Enter 10 or 13 digit ISBN';

  @override
  String get book_not_found => 'No book information found';

  @override
  String get filter_no_books => 'No books for this filter';

  @override
  String get refresh_tooltip => 'Refresh';

  @override
  String get example_lexile_hint => 'e.g.: 850';

  @override
  String get clipboard_paste_tooltip => 'Paste from clipboard';

  @override
  String get author_optional => 'Author (optional)';

  @override
  String get new_book => 'New Book';

  @override
  String get edit_book => 'Edit Book';

  @override
  String get lexile_need_title_author =>
      'Please enter title and author before searching Lexile';

  @override
  String lexile_refilled(Object value) {
    return 'Lexile filled: ${value}L';
  }

  @override
  String get photo_taken => 'Photo captured';

  @override
  String photo_failed(Object error) {
    return 'Photo failed: $error';
  }

  @override
  String get book_saved => 'Book saved';

  @override
  String get save_failed => 'Save failed';

  @override
  String get save_book_button => 'Save Book';

  @override
  String get label_title_required => 'Title *';

  @override
  String get label_author_required => 'Author *';

  @override
  String get label_publisher_required => 'Publisher *';

  @override
  String get label_description => 'Description';

  @override
  String get label_purchase_price_required => 'Purchase price (NT\$) *';

  @override
  String get label_sale_price => 'Sale price (NT\$)';

  @override
  String get purchase_date_title => 'Purchase Date';

  @override
  String get sale_date_title => 'Sale Date';

  @override
  String get set_sale_date_label => 'Set sale date';

  @override
  String get profit_label => 'Profit';

  @override
  String settings_enabled_sources(Object enabled, Object total) {
    return 'Enabled sources: $enabled / $total';
  }

  @override
  String get settings_sources_explain =>
      'The system will try enabled sources in order and fall back to the next if a source fails. All APIs are free third-party services and may vary in reliability.';

  @override
  String get statistics_tab_reading => 'Reading Stats';

  @override
  String get statistics_tab_finance => 'Finance Stats';

  @override
  String get stat_overview_title => 'Reading Overview';

  @override
  String get stat_total_books => 'Total books';

  @override
  String get stat_read => 'Read';

  @override
  String get stat_reading => 'Reading';

  @override
  String get stat_unread => 'Unread';

  @override
  String get stat_completion_title => 'Completion';

  @override
  String get finance_title => 'Finance Overview';

  @override
  String get finance_total_spent => 'Total spent';

  @override
  String get finance_total_earned => 'Total earned';

  @override
  String get finance_total_profit => 'Total profit';

  @override
  String get settings_common_websites_title => 'Common lookup websites';

  @override
  String get take_photo => 'Take photo';

  @override
  String language_label(Object value) {
    return 'Language: $value';
  }

  @override
  String get label_lexile => 'Lexile (Measure)';

  @override
  String get profit_calculation => 'Profit calculation';

  @override
  String get no_enabled_sources =>
      'No ISBN sources enabled, please enable sources in Settings';

  @override
  String get searching_title => 'Searching...';

  @override
  String source_label(Object value) {
    return 'Source: $value';
  }

  @override
  String get cannot_find_book => 'Unable to find book information';

  @override
  String get api_test_title => 'ISBN API Test';

  @override
  String get api_test_start => 'Start tests';

  @override
  String get api_test_running => 'Testing...';

  @override
  String get api_test_output_placeholder =>
      'Tap "Start tests" to run API tests...';

  @override
  String get scan_not_isbn_ean => 'Please scan an ISBN barcode; this is an EAN';

  @override
  String get please_enter_title => 'Please enter title';

  @override
  String query_failed_error(Object error) {
    return 'Query failed: $error';
  }

  @override
  String error_prefix(Object message) {
    return 'Error: $message';
  }

  @override
  String get isbn_error_invalid_format => 'Invalid ISBN format';

  @override
  String provider_book_record_sale_failed(Object error) {
    return 'Failed to record sale: $error';
  }

  @override
  String get isbn_already_exists => 'ISBN already exists in database';

  @override
  String cannot_find_isbn_ncl(Object url) {
    return 'Unable to find book information. See: $url';
  }

  @override
  String load_books_failed(Object error) {
    return 'Failed to load books: $error';
  }

  @override
  String add_book_failed(Object error) {
    return 'Failed to add book: $error';
  }

  @override
  String update_book_failed(Object error) {
    return 'Failed to update book: $error';
  }

  @override
  String delete_book_failed(Object error) {
    return 'Failed to delete book: $error';
  }
}
