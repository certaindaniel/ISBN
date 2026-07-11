import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Freemium：免費 [freeBookLimit] 本，非消耗型 IAP 解鎖無限書籍。
/// 單例讓 BookProvider 可同步查 [isUnlocked]。
// ponytail: 解鎖狀態存本地 flag、無伺服器收據驗證；低價工具 app 夠用，
// 若日後出現盜版問題再上 App Store Server API 驗證。
class PurchaseService extends ChangeNotifier {
  static final PurchaseService instance = PurchaseService._();
  PurchaseService._();

  static const String productId = 'com.daniel.isbn.unlimited';
  static const int freeBookLimit = 20;
  static const String _unlockedKey = 'iap_unlimited_unlocked';

  /// 老買家豁免：freemium 從 build 10（v1.1.0）開始，
  /// originalAppVersion（iOS 上為 CFBundleVersion）小於此值代表當年花錢買斷，直接解鎖。
  /// 注意：sandbox/TestFlight 的 originalAppVersion 恆為 "1.0"，測試 paywall 需暫時關掉此判斷。
  static const int _firstFreeBuild = 10;
  static const MethodChannel _appTransactionChannel =
      MethodChannel('com.daniel.isbn/app_transaction');

  // lazy：避免單純讀 isUnlocked（如測試、BookProvider gate）就初始化平台 channel
  InAppPurchase get _iap => InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? product;
  bool storeAvailable = false;
  bool purchasePending = false;
  String? lastError;
  bool _unlocked = false;

  bool get isUnlocked => _unlocked;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _unlocked = prefs.getBool(_unlockedKey) ?? false;
    notifyListeners();

    if (!_unlocked) {
      await _grandfatherPaidBuyers(prefs);
    }

    storeAvailable = await _iap.isAvailable();
    if (!storeAvailable) {
      notifyListeners();
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) {
        lastError = e.toString();
        purchasePending = false;
        notifyListeners();
      },
    );

    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isNotEmpty) {
      product = response.productDetails.first;
    }
    notifyListeners();
  }

  /// 在 app 還是 NT$30 買斷時期購買的使用者，自動視同已解鎖。
  Future<void> _grandfatherPaidBuyers(SharedPreferences prefs) async {
    try {
      final original = await _appTransactionChannel
          .invokeMethod<String>('getOriginalAppVersion');
      final build = int.tryParse(original?.split('.').first ?? '');
      if (build != null && build < _firstFreeBuild) {
        _unlocked = true;
        await prefs.setBool(_unlockedKey, true);
        notifyListeners();
      }
    } on Exception {
      // 非 iOS、iOS < 16 或查詢失敗：不豁免，照一般 IAP 流程
    }
  }

  Future<void> buy() async {
    final details = product;
    if (details == null || purchasePending) return;
    lastError = null;
    purchasePending = true;
    notifyListeners();
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  Future<void> restore() async {
    if (purchasePending) return;
    lastError = null;
    purchasePending = true;
    notifyListeners();
    await _iap.restorePurchases();
    purchasePending = false;
    notifyListeners();
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == productId &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        _unlocked = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_unlockedKey, true);
      }
      if (purchase.status == PurchaseStatus.error) {
        lastError = purchase.error?.message;
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    purchasePending = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
