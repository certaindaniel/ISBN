// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'ISBN 書籍管理';

  @override
  String get books => '書籍';

  @override
  String get statistics => '統計';

  @override
  String get unsavedChangesTitle => '有未儲存的變更';

  @override
  String get unsavedChangesContent => '您有未儲存的變更，要儲存後離開嗎？';

  @override
  String get discard => '放棄變更';

  @override
  String get saveAndLeave => '儲存並離開';

  @override
  String get cancel => '取消';

  @override
  String get unfinishedSearchTitle => '有未完成的查詢或變更';

  @override
  String get unfinishedSearchContent => '您有尚未完成的查詢或輸入，要執行查詢、放棄變更還是繼續編輯？';

  @override
  String get performSearch => '執行查詢';

  @override
  String get pleaseFillRequiredFields => '請填入所有必填欄位';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn(): super('zh_CN');

  @override
  String get appTitle => 'ISBN 书籍管理';

  @override
  String get books => '书籍';

  @override
  String get statistics => '统计';

  @override
  String get unsavedChangesTitle => '有未保存的更改';

  @override
  String get unsavedChangesContent => '您有未保存的更改，要保存后离开吗？';

  @override
  String get discard => '放弃更改';

  @override
  String get saveAndLeave => '保存并离开';

  @override
  String get cancel => '取消';

  @override
  String get unfinishedSearchTitle => '有未完成的查询或更改';

  @override
  String get unfinishedSearchContent => '您有尚未完成的查询或输入，要执行查询、放弃更改还是继续编辑？';

  @override
  String get performSearch => '执行查询';

  @override
  String get pleaseFillRequiredFields => '请填写所有必填栏位';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw(): super('zh_TW');

  @override
  String get appTitle => 'ISBN 書籍管理';

  @override
  String get books => '書籍';

  @override
  String get statistics => '統計';

  @override
  String get unsavedChangesTitle => '有未儲存的變更';

  @override
  String get unsavedChangesContent => '您有未儲存的變更，要儲存後離開嗎？';

  @override
  String get discard => '放棄變更';

  @override
  String get saveAndLeave => '儲存並離開';

  @override
  String get cancel => '取消';

  @override
  String get unfinishedSearchTitle => '有未完成的查詢或變更';

  @override
  String get unfinishedSearchContent => '您有尚未完成的查詢或輸入，要執行查詢、放棄變更還是繼續編輯？';

  @override
  String get performSearch => '執行查詢';

  @override
  String get pleaseFillRequiredFields => '請填入所有必填欄位';
}
