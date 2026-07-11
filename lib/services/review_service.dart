import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 在正向時刻（成功新增書籍累積 N 次）請求 App Store 評分。
/// 系統本身有 3 次/365 天節流，這裡只負責挑對時機、只主動觸發一次。
class ReviewService {
  static const _countKey = 'review_success_count';
  static const _promptedKey = 'review_prompted';
  static const _threshold = 5;
  static const _appStoreId = '6756864904';

  /// 成功新增一本書後呼叫。
  static Future<void> recordSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_promptedKey) ?? false) return;

    final count = (prefs.getInt(_countKey) ?? 0) + 1;
    await prefs.setInt(_countKey, count);
    if (count < _threshold) return;

    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await prefs.setBool(_promptedKey, true);
      await review.requestReview();
    }
  }

  /// 設定頁「為 App 評分」：直接開商店評論頁，不受系統節流限制。
  static Future<void> openStoreListing() =>
      InAppReview.instance.openStoreListing(appStoreId: _appStoreId);
}
