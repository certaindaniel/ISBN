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

  @override
  String get bookList_search_hint => '請輸入書名';

  @override
  String search_failed(Object error) {
    return '查詢失敗: $error';
  }

  @override
  String get search_button => '查詢';

  @override
  String get manual_isbn_label => '手動輸入 ISBN';

  @override
  String get manual_isbn_title => '手動輸入 ISBN';

  @override
  String get book_added => '已新增書籍';

  @override
  String get book_deleted => '書籍已刪除';

  @override
  String get delete_confirm_title => '刪除確認';

  @override
  String get delete_confirm_content => '確定要刪除此書籍嗎？';

  @override
  String get delete_action => '刪除';

  @override
  String get my_books_title => '我的書籍';

  @override
  String get filter_all => '全部';

  @override
  String get filter_unread => '未讀';

  @override
  String get filter_reading => '閱讀中';

  @override
  String get filter_read => '已讀';

  @override
  String get empty_hint => '換個篩選或新增一本試試看';

  @override
  String get search_by_title_title => '以書名查詢';

  @override
  String get search_by_title_subtitle => '輸入書名/作者，用 Google Books 搜尋';

  @override
  String get scan_title => '掃描 ISBN';

  @override
  String get scan_subtitle => '使用相機掃描條碼（支援 978/979）';

  @override
  String lexile_label(Object score) {
    return 'Lexile: ${score}L';
  }

  @override
  String get edit => '編輯';

  @override
  String get delete => '刪除';

  @override
  String lexile_load_failed(Object error) {
    return '載入失敗: $error';
  }

  @override
  String get lexile_clipboard_none => '剪貼簿未偵測到 Lexile 值';

  @override
  String get lexile_manual_title => '手動輸入 Lexile 值';

  @override
  String get lexile_cancel => '取消';

  @override
  String get lexile_fill => '回填';

  @override
  String get lexile_manual_label => '手動輸入';

  @override
  String get statistics_title => '統計報告';

  @override
  String stats_reading_label(Object count) {
    return '閱讀中: $count 本';
  }

  @override
  String stats_unread_label(Object count) {
    return '未讀: $count 本';
  }

  @override
  String get settings_title => '設定';

  @override
  String get settings_sources_subtitle => '可切換使用的 ISBN 查詢來源，依序嘗試';

  @override
  String get settings_manual_query_subtitle => '手動查詢書籍資訊';

  @override
  String get settings_tnla_title => '台灣國家圖書館 ISBN';

  @override
  String get settings_tnla_subtitle => '查詢台灣出版書籍資訊';

  @override
  String get settings_bok_title => '博客來';

  @override
  String get settings_bok_subtitle => '台灣最大網路書店';

  @override
  String get settings_openlibrary_title => 'Open Library';

  @override
  String get settings_openlibrary_subtitle => '完全免費開放資料，補足封面與基本元資料。';

  @override
  String get settings_eslite_title => '誠品書店';

  @override
  String get settings_eslite_subtitle => '誠品線上書店';

  @override
  String get settings_google_title => 'Google Books';

  @override
  String get settings_google_subtitle => '全球書籍資料庫';

  @override
  String get settings_wikipedia_title => 'Wikipedia';

  @override
  String get settings_wikipedia_subtitle => '維基百科參考書籍資訊，補充文獻數據。';

  @override
  String get settings_jike_title => '中文第三方免費 API';

  @override
  String get settings_jike_subtitle => '社群維護的中文書資訊，穩定度較低，預設關閉。';

  @override
  String get lexile_title => 'Lexile 查詢';

  @override
  String get no_results_text => '查無結果（或無可用 ISBN）';

  @override
  String get manual_isbn_hint => '請輸入 10 或 13 位 ISBN';

  @override
  String get please_enter_isbn => '請輸入 ISBN';

  @override
  String get scan_area_hint => '將書籍條碼放在掃描區域';

  @override
  String get book_not_found => '查無書籍資訊';

  @override
  String get filter_no_books => '這個篩選沒有書籍';

  @override
  String get refresh_tooltip => '重新整理';

  @override
  String get example_lexile_hint => '例如：850';

  @override
  String get clipboard_paste_tooltip => '貼上回填';

  @override
  String get author_optional => '作者（可選）';

  @override
  String get new_book => '新增書籍';

  @override
  String get edit_book => '編輯書籍';

  @override
  String get lexile_need_title_author => '請先填入書名與作者再查詢 Lexile';

  @override
  String lexile_refilled(Object value) {
    return '已回填 Lexile：${value}L';
  }

  @override
  String get photo_taken => '已拍攝書籍封面';

  @override
  String photo_failed(Object error) {
    return '拍照失敗: $error';
  }

  @override
  String get book_saved => '書籍已儲存';

  @override
  String get save_failed => '儲存失敗';

  @override
  String get save_book_button => '保存書籍';

  @override
  String get label_title_required => '書名 *';

  @override
  String get label_author_required => '作者 *';

  @override
  String get label_publisher_required => '出版社 *';

  @override
  String get label_description => '描述';

  @override
  String get label_purchase_price_required => '購買價格 (元) *';

  @override
  String get label_sale_price => '售出價格 (元)';

  @override
  String get purchase_date_title => '購買日期';

  @override
  String get sale_date_title => '售出日期';

  @override
  String get set_sale_date_label => '設定售出日期';

  @override
  String get profit_label => '利潤';

  @override
  String settings_enabled_sources(Object enabled, Object total) {
    return '已啟用來源：$enabled / $total';
  }

  @override
  String get settings_sources_explain =>
      '系統會依照上列順序逐一查詢，失敗時自動換下一個來源。所有 API 均為免費第三方服務，穩定度可能會有所差異。';

  @override
  String get statistics_tab_reading => '閱讀統計';

  @override
  String get statistics_tab_finance => '金額統計';

  @override
  String get stat_overview_title => '閱讀進度';

  @override
  String get stat_total_books => '總書籍';

  @override
  String get stat_read => '已讀';

  @override
  String get stat_reading => '閱讀中';

  @override
  String get stat_unread => '未讀';

  @override
  String get stat_completion_title => '閱讀完成度';

  @override
  String get finance_title => '金額統計';

  @override
  String get finance_total_spent => '總支出';

  @override
  String get finance_total_earned => '總收入';

  @override
  String get finance_total_profit => '總利潤';

  @override
  String get settings_common_websites_title => '常用查詢網頁';

  @override
  String get take_photo => '拍攝封面';

  @override
  String language_label(Object value) {
    return '語言：$value';
  }

  @override
  String get label_lexile => '藍思值 (Lexile Measure)';

  @override
  String get profit_calculation => '利潤計算';

  @override
  String get no_enabled_sources => '尚未啟用任何查詢來源，請到設定頁開啟來源';

  @override
  String get searching_title => '查詢中...';

  @override
  String source_label(Object value) {
    return '來源：$value';
  }

  @override
  String get cannot_find_book => '無法查詢到書籍資訊';

  @override
  String get api_test_title => 'ISBN API 測試';

  @override
  String get api_test_start => '開始測試';

  @override
  String get api_test_running => '測試進行中...';

  @override
  String get api_test_output_placeholder => '點擊「開始測試」執行 API 測試...';

  @override
  String get scan_not_isbn_ean => '請掃描 ISBN 條碼，這個是 EAN';

  @override
  String get please_enter_title => '請輸入書名';

  @override
  String query_failed_error(Object error) {
    return '查詢失敗: $error';
  }

  @override
  String error_prefix(Object message) {
    return '錯誤: $message';
  }

  @override
  String get isbn_error_invalid_format => '無效的 ISBN 格式';

  @override
  String provider_book_record_sale_failed(Object error) {
    return '記錄售出失敗：$error';
  }

  @override
  String get isbn_already_exists => 'ISBN 已存在於資料庫';

  @override
  String cannot_find_isbn_ncl(Object url) {
    return '無法查詢到此 ISBN 的書籍資訊，可前往 NCL 查詢：$url';
  }

  @override
  String load_books_failed(Object error) {
    return '載入書籍失敗: $error';
  }

  @override
  String add_book_failed(Object error) {
    return '新增書籍失敗: $error';
  }

  @override
  String update_book_failed(Object error) {
    return '更新書籍失敗: $error';
  }

  @override
  String delete_book_failed(Object error) {
    return '刪除書籍失敗: $error';
  }

  @override
  String get settings_rate_title => '為 App 評分';

  @override
  String get settings_rate_subtitle => '喜歡這個 App 嗎？留個評論支持我們';

  @override
  String free_limit_reached(int limit) {
    return '已達免費版 $limit 本上限，解鎖無限書籍即可繼續建檔。';
  }

  @override
  String get paywall_title => '解鎖無限書籍';

  @override
  String paywall_subtitle(int limit) {
    return '免費版最多可建檔 $limit 本書。一次解鎖，永久使用。';
  }

  @override
  String get paywall_feature_unlimited => '書庫數量無上限';

  @override
  String get paywall_feature_profit => '利潤追蹤與統計功能永久免費';

  @override
  String get paywall_feature_once => '一次性買斷，無訂閱';

  @override
  String paywall_buy(String price) {
    return '以 $price 解鎖';
  }

  @override
  String get paywall_restore => '恢復購買';

  @override
  String get paywall_unlocked => '已解鎖無限書籍';

  @override
  String get paywall_unavailable => '商店暫時無法使用';

  @override
  String get settings_unlock_title => '解鎖無限書籍';

  @override
  String settings_unlock_subtitle(int limit) {
    return '免費版最多 $limit 本';
  }
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

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

  @override
  String get bookList_search_hint => '请输入书名';

  @override
  String search_failed(Object error) {
    return '查询失败: $error';
  }

  @override
  String get search_button => '查询';

  @override
  String get manual_isbn_label => '手动输入 ISBN';

  @override
  String get manual_isbn_title => '手动输入 ISBN';

  @override
  String get book_added => '已新增书籍';

  @override
  String get book_deleted => '书籍已删除';

  @override
  String get delete_confirm_title => '删除确认';

  @override
  String get delete_confirm_content => '确定要删除此书籍吗？';

  @override
  String get delete_action => '删除';

  @override
  String get my_books_title => '我的书籍';

  @override
  String get filter_all => '全部';

  @override
  String get filter_unread => '未读';

  @override
  String get filter_reading => '阅读中';

  @override
  String get filter_read => '已读';

  @override
  String get empty_hint => '换个筛选或新增一本试试看';

  @override
  String get search_by_title_title => '以书名查询';

  @override
  String get search_by_title_subtitle => '输入书名/作者，用 Google Books 搜寻';

  @override
  String get scan_title => '扫描 ISBN';

  @override
  String get scan_subtitle => '使用相机扫描条码（支持 978/979）';

  @override
  String lexile_label(Object score) {
    return 'Lexile: ${score}L';
  }

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String lexile_load_failed(Object error) {
    return '加载失败: $error';
  }

  @override
  String get lexile_clipboard_none => '剪贴板未检测到 Lexile 值';

  @override
  String get lexile_manual_title => '手动输入 Lexile 值';

  @override
  String get lexile_cancel => '取消';

  @override
  String get lexile_fill => '回填';

  @override
  String get lexile_manual_label => '手动输入';

  @override
  String get statistics_title => '统计报告';

  @override
  String stats_reading_label(Object count) {
    return '阅读中: $count 本';
  }

  @override
  String stats_unread_label(Object count) {
    return '未读: $count 本';
  }

  @override
  String get settings_title => '设置';

  @override
  String get settings_sources_subtitle => '可切换使用的 ISBN 查询来源，依序尝试';

  @override
  String get settings_manual_query_subtitle => '手动查询书籍信息';

  @override
  String get settings_tnla_title => '台湾国家图书馆 ISBN';

  @override
  String get settings_tnla_subtitle => '查询台湾出版书籍信息';

  @override
  String get settings_bok_title => '博客来';

  @override
  String get settings_bok_subtitle => '台湾最大网络书店';

  @override
  String get settings_openlibrary_title => 'Open Library';

  @override
  String get settings_openlibrary_subtitle => '完全免费开放资料，补充封面与基本元资料。';

  @override
  String get settings_eslite_title => '诚品书店';

  @override
  String get settings_eslite_subtitle => '诚品线上书店';

  @override
  String get settings_google_title => 'Google Books';

  @override
  String get settings_google_subtitle => '全球书籍数据库';

  @override
  String get settings_wikipedia_title => 'Wikipedia';

  @override
  String get settings_wikipedia_subtitle => '维基百科参考书籍资讯，补充文献数据。';

  @override
  String get settings_jike_title => '中文第三方免費 API';

  @override
  String get settings_jike_subtitle => '社群维护的中文书资讯，稳定度较低，预设关闭。';

  @override
  String get lexile_title => 'Lexile 查询';

  @override
  String get no_results_text => '查无结果（或无可用 ISBN）';

  @override
  String get manual_isbn_hint => '请输入 10 或 13 位 ISBN';

  @override
  String get please_enter_isbn => '请输入 ISBN';

  @override
  String get scan_area_hint => '将书籍条码放在扫描区域';

  @override
  String get book_not_found => '查无书籍信息';

  @override
  String get refresh_tooltip => '重新整理';

  @override
  String get example_lexile_hint => '例如：850';

  @override
  String get clipboard_paste_tooltip => '贴上回填';

  @override
  String get author_optional => '作者（可选）';

  @override
  String get new_book => '新增书籍';

  @override
  String get edit_book => '编辑书籍';

  @override
  String get lexile_need_title_author => '请先填入书名与作者再查询 Lexile';

  @override
  String lexile_refilled(Object value) {
    return '已回填 Lexile：${value}L';
  }

  @override
  String get photo_taken => '已拍摄书籍封面';

  @override
  String photo_failed(Object error) {
    return '拍照失败: $error';
  }

  @override
  String get book_saved => '书籍已保存';

  @override
  String get save_failed => '保存失败';

  @override
  String get save_book_button => '保存书籍';

  @override
  String get label_title_required => '书名 *';

  @override
  String get label_author_required => '作者 *';

  @override
  String get label_publisher_required => '出版社 *';

  @override
  String get label_description => '描述';

  @override
  String get label_purchase_price_required => '购买价格 (元) *';

  @override
  String get label_sale_price => '售价 (元)';

  @override
  String get purchase_date_title => '购买日期';

  @override
  String get sale_date_title => '售出日期';

  @override
  String get set_sale_date_label => '設定售出日期';

  @override
  String get profit_label => '利润';

  @override
  String settings_enabled_sources(Object enabled, Object total) {
    return '已启用来源：$enabled / $total';
  }

  @override
  String get settings_sources_explain =>
      '系统会依照上列顺序逐一查询，失败时自动换下一个来源。所有 API 均为免费第三方服务，稳定度可能会有所差异。';

  @override
  String get statistics_tab_reading => '阅读统计';

  @override
  String get statistics_tab_finance => '金额统计';

  @override
  String get stat_overview_title => '阅读进度';

  @override
  String get stat_total_books => '总书籍';

  @override
  String get stat_read => '已读';

  @override
  String get stat_reading => '阅读中';

  @override
  String get stat_unread => '未读';

  @override
  String get stat_completion_title => '阅读完成度';

  @override
  String get finance_title => '金额统计';

  @override
  String get finance_total_spent => '总支出';

  @override
  String get finance_total_earned => '总收入';

  @override
  String get finance_total_profit => '总利润';

  @override
  String get settings_common_websites_title => '常用查询网页';

  @override
  String get take_photo => '拍摄封面';

  @override
  String language_label(Object value) {
    return '语言：$value';
  }

  @override
  String get label_lexile => '蓝思值 (Lexile Measure)';

  @override
  String get profit_calculation => '利润计算';

  @override
  String get no_enabled_sources => '尚未启用任何查询来源，请到设置页开启来源';

  @override
  String get searching_title => '查询中...';

  @override
  String source_label(Object value) {
    return '来源：$value';
  }

  @override
  String get cannot_find_book => '无法查询到书籍信息';

  @override
  String get api_test_title => 'ISBN API 测试';

  @override
  String get api_test_start => '开始测试';

  @override
  String get api_test_running => '测试进行中...';

  @override
  String get api_test_output_placeholder => '点击「开始测试」执行 API 测试...';

  @override
  String get scan_not_isbn_ean => '请扫描 ISBN 条码，这个是 EAN';

  @override
  String get please_enter_title => '请输入书名';

  @override
  String query_failed_error(Object error) {
    return '查询失败: $error';
  }

  @override
  String error_prefix(Object message) {
    return '错误: $message';
  }

  @override
  String get isbn_error_invalid_format => '无效的 ISBN 格式';

  @override
  String provider_book_record_sale_failed(Object error) {
    return '记录售出失败：$error';
  }

  @override
  String get isbn_already_exists => 'ISBN 已存在于数据库';

  @override
  String cannot_find_isbn_ncl(Object url) {
    return '无法查询到此 ISBN 的书籍信息，可前往 NCL 查询：$url';
  }

  @override
  String load_books_failed(Object error) {
    return '加载书籍失败: $error';
  }

  @override
  String add_book_failed(Object error) {
    return '新增书籍失败: $error';
  }

  @override
  String update_book_failed(Object error) {
    return '更新书籍失败: $error';
  }

  @override
  String delete_book_failed(Object error) {
    return '删除书籍失败: $error';
  }

  @override
  String get settings_rate_title => '为 App 评分';

  @override
  String get settings_rate_subtitle => '喜欢这个 App 吗？留个评论支持我们';

  @override
  String free_limit_reached(int limit) {
    return '已达免费版 $limit 本上限，解锁无限书籍即可繼續建档。';
  }

  @override
  String get paywall_title => '解锁无限书籍';

  @override
  String paywall_subtitle(int limit) {
    return '免费版最多可建档 $limit 本书。一次解锁，永久使用。';
  }

  @override
  String get paywall_feature_unlimited => '书库数量无上限';

  @override
  String get paywall_feature_profit => '利润追踪与统计功能永久免费';

  @override
  String get paywall_feature_once => '一次性买断，无订阅';

  @override
  String paywall_buy(String price) {
    return '以 $price 解锁';
  }

  @override
  String get paywall_restore => '恢复购买';

  @override
  String get paywall_unlocked => '已解锁无限书籍';

  @override
  String get paywall_unavailable => '商店暂时无法使用';

  @override
  String get settings_unlock_title => '解锁无限书籍';

  @override
  String settings_unlock_subtitle(int limit) {
    return '免费版最多 $limit 本';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

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

  @override
  String get bookList_search_hint => '請輸入書名';

  @override
  String search_failed(Object error) {
    return '查詢失敗: $error';
  }

  @override
  String get search_button => '查詢';

  @override
  String get manual_isbn_label => '手動輸入 ISBN';

  @override
  String get manual_isbn_title => '手動輸入 ISBN';

  @override
  String get book_added => '已新增書籍';

  @override
  String get book_deleted => '書籍已刪除';

  @override
  String get delete_confirm_title => '刪除確認';

  @override
  String get delete_confirm_content => '確定要刪除此書籍嗎？';

  @override
  String get delete_action => '刪除';

  @override
  String get my_books_title => '我的書籍';

  @override
  String get filter_all => '全部';

  @override
  String get filter_unread => '未讀';

  @override
  String get filter_reading => '閱讀中';

  @override
  String get filter_read => '已讀';

  @override
  String get empty_hint => '換個篩選或新增一本試試看';

  @override
  String get search_by_title_title => '以書名查詢';

  @override
  String get search_by_title_subtitle => '輸入書名/作者，用 Google Books 搜尋';

  @override
  String get scan_title => '掃描 ISBN';

  @override
  String get scan_subtitle => '使用相機掃描條碼（支援 978/979）';

  @override
  String lexile_label(Object score) {
    return 'Lexile: ${score}L';
  }

  @override
  String get edit => '編輯';

  @override
  String get delete => '刪除';

  @override
  String lexile_load_failed(Object error) {
    return '載入失敗: $error';
  }

  @override
  String get lexile_clipboard_none => '剪貼簿未偵測到 Lexile 值';

  @override
  String get lexile_manual_title => '手動輸入 Lexile 值';

  @override
  String get lexile_cancel => '取消';

  @override
  String get lexile_fill => '回填';

  @override
  String get lexile_manual_label => '手動輸入';

  @override
  String get statistics_title => '統計報告';

  @override
  String stats_reading_label(Object count) {
    return '閱讀中: $count 本';
  }

  @override
  String stats_unread_label(Object count) {
    return '未讀: $count 本';
  }

  @override
  String get settings_title => '設定';

  @override
  String get settings_sources_subtitle => '可切換使用的 ISBN 查詢來源，依序嘗試';

  @override
  String get settings_manual_query_subtitle => '手動查詢書籍資訊';

  @override
  String get settings_tnla_title => '台灣國家圖書館 ISBN';

  @override
  String get settings_tnla_subtitle => '查詢台灣出版書籍資訊';

  @override
  String get settings_bok_title => '博客來';

  @override
  String get settings_bok_subtitle => '台灣最大網路書店';

  @override
  String get settings_openlibrary_title => 'Open Library';

  @override
  String get settings_openlibrary_subtitle => '完全免費開放資料，補足封面與基本元資料。';

  @override
  String get settings_eslite_title => '誠品書店';

  @override
  String get settings_eslite_subtitle => '誠品線上書店';

  @override
  String get settings_google_title => 'Google Books';

  @override
  String get settings_google_subtitle => '全球書籍資料庫';

  @override
  String get settings_wikipedia_title => 'Wikipedia';

  @override
  String get settings_wikipedia_subtitle => '維基百科參考書籍資訊，補充文獻數據。';

  @override
  String get settings_jike_title => '中文第三方免費 API';

  @override
  String get settings_jike_subtitle => '社群維護的中文書資訊，穩定度較低，預設關閉。';

  @override
  String get lexile_title => 'Lexile 查詢';

  @override
  String get no_results_text => '查無結果（或無可用 ISBN）';

  @override
  String get manual_isbn_hint => '請輸入 10 或 13 位 ISBN';

  @override
  String get please_enter_isbn => '請輸入 ISBN';

  @override
  String get scan_area_hint => '將書籍條碼放在掃描區域';

  @override
  String get book_not_found => '查無書籍資訊';

  @override
  String get filter_no_books => '這個篩選沒有書籍';

  @override
  String get refresh_tooltip => '重新整理';

  @override
  String get example_lexile_hint => '例如：850';

  @override
  String get clipboard_paste_tooltip => '貼上回填';

  @override
  String get author_optional => '作者（可選）';

  @override
  String get new_book => '新增書籍';

  @override
  String get edit_book => '編輯書籍';

  @override
  String get lexile_need_title_author => '請先填入書名與作者再查詢 Lexile';

  @override
  String lexile_refilled(Object value) {
    return '已回填 Lexile：${value}L';
  }

  @override
  String get photo_taken => '已拍攝書籍封面';

  @override
  String photo_failed(Object error) {
    return '拍照失敗: $error';
  }

  @override
  String get book_saved => '書籍已儲存';

  @override
  String get save_failed => '儲存失敗';

  @override
  String get save_book_button => '保存書籍';

  @override
  String get label_title_required => '書名 *';

  @override
  String get label_author_required => '作者 *';

  @override
  String get label_publisher_required => '出版社 *';

  @override
  String get label_description => '描述';

  @override
  String get label_purchase_price_required => '購買價格 (元) *';

  @override
  String get label_sale_price => '售出價格 (元)';

  @override
  String get purchase_date_title => '購買日期';

  @override
  String get sale_date_title => '售出日期';

  @override
  String get set_sale_date_label => '設定售出日期';

  @override
  String get profit_label => '利潤';

  @override
  String settings_enabled_sources(Object enabled, Object total) {
    return '已啟用來源：$enabled / $total';
  }

  @override
  String get settings_sources_explain =>
      '系統會依照上列順序逐一查詢，失敗時自動換下一個來源。所有 API 均為免費第三方服務，穩定度可能會有所差異。';

  @override
  String get statistics_tab_reading => '閱讀統計';

  @override
  String get statistics_tab_finance => '金額統計';

  @override
  String get stat_overview_title => '閱讀進度';

  @override
  String get stat_total_books => '總書籍';

  @override
  String get stat_read => '已讀';

  @override
  String get stat_reading => '閱讀中';

  @override
  String get stat_unread => '未讀';

  @override
  String get stat_completion_title => '閱讀完成度';

  @override
  String get finance_title => '金額統計';

  @override
  String get finance_total_spent => '總支出';

  @override
  String get finance_total_earned => '總收入';

  @override
  String get finance_total_profit => '總利潤';

  @override
  String get settings_common_websites_title => '常用查詢網頁';

  @override
  String get take_photo => '拍攝封面';

  @override
  String language_label(Object value) {
    return '語言：$value';
  }

  @override
  String get label_lexile => '藍思值 (Lexile Measure)';

  @override
  String get profit_calculation => '利潤計算';

  @override
  String get no_enabled_sources => '尚未啟用任何查詢來源，請到設定頁開啟來源';

  @override
  String get searching_title => '查詢中...';

  @override
  String source_label(Object value) {
    return '來源：$value';
  }

  @override
  String get cannot_find_book => '無法查詢到書籍資訊';

  @override
  String get api_test_title => 'ISBN API 測試';

  @override
  String get api_test_start => '開始測試';

  @override
  String get api_test_running => '測試進行中...';

  @override
  String get api_test_output_placeholder => '點擊「開始測試」執行 API 測試...';

  @override
  String get scan_not_isbn_ean => '請掃描 ISBN 條碼，這個是 EAN';

  @override
  String get please_enter_title => '請輸入書名';

  @override
  String query_failed_error(Object error) {
    return '查詢失敗: $error';
  }

  @override
  String error_prefix(Object message) {
    return '錯誤: $message';
  }

  @override
  String get isbn_error_invalid_format => '無效的 ISBN 格式';

  @override
  String provider_book_record_sale_failed(Object error) {
    return '記錄售出失敗：$error';
  }

  @override
  String get isbn_already_exists => 'ISBN 已存在於資料庫';

  @override
  String cannot_find_isbn_ncl(Object url) {
    return '無法查詢到此 ISBN 的書籍資訊，可前往 NCL 查詢：$url';
  }

  @override
  String load_books_failed(Object error) {
    return '載入書籍失敗: $error';
  }

  @override
  String add_book_failed(Object error) {
    return '新增書籍失敗: $error';
  }

  @override
  String update_book_failed(Object error) {
    return '更新書籍失敗: $error';
  }

  @override
  String delete_book_failed(Object error) {
    return '刪除書籍失敗: $error';
  }

  @override
  String get settings_rate_title => '為 App 評分';

  @override
  String get settings_rate_subtitle => '喜歡這個 App 嗎？留個評論支持我們';

  @override
  String free_limit_reached(int limit) {
    return '已達免費版 $limit 本上限，解鎖無限書籍即可繼續建檔。';
  }

  @override
  String get paywall_title => '解鎖無限書籍';

  @override
  String paywall_subtitle(int limit) {
    return '免費版最多可建檔 $limit 本書。一次解鎖，永久使用。';
  }

  @override
  String get paywall_feature_unlimited => '書庫數量無上限';

  @override
  String get paywall_feature_profit => '利潤追蹤與統計功能永久免費';

  @override
  String get paywall_feature_once => '一次性買斷，無訂閱';

  @override
  String paywall_buy(String price) {
    return '以 $price 解鎖';
  }

  @override
  String get paywall_restore => '恢復購買';

  @override
  String get paywall_unlocked => '已解鎖無限書籍';

  @override
  String get paywall_unavailable => '商店暫時無法使用';

  @override
  String get settings_unlock_title => '解鎖無限書籍';

  @override
  String settings_unlock_subtitle(int limit) {
    return '免費版最多 $limit 本';
  }
}
