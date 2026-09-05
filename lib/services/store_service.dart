import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/coin_package.dart';
import '../models/tile_theme.dart';
import 'ads_entitlement.dart';
import 'coin_wallet.dart';
import 'theme_unlocks.dart';

/// معرّف منتج شراء "إزالة الإعلانات" (غير استهلاكي — يُشترى مرة واحدة).
const String kRemoveAdsProductId = 'remove_ads';

/// طبقة رقيقة فوق حزمة in_app_purchase الرسمية تدير كل منتجات المتجر:
/// حزم الكوينز (استهلاكية)، إزالة الإعلانات ومجموعات الأشكال (غير
/// استهلاكية — تُملَك للأبد).
///
/// ملاحظة مهمة: الشراء الحقيقي يعمل فقط بعد إنشاء نفس معرّفات المنتجات
/// في App Store Connect وGoogle Play Console. راجع docs/PUBLISHING_IAP.md.
class StoreService {
  StoreService._();

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  static Set<String> get _allProductIds => {
        ...kCoinPackages.map((p) => p.productId),
        kRemoveAdsProductId,
        ...kTileThemes.where((t) => !t.free).map((t) => t.id),
      };

  static Future<bool> isAvailable() => _iap.isAvailable();

  /// يجلب تفاصيل كل المنتجات (الأسعار الحقيقية بعملة المستخدم) من المتجر.
  /// يُرجع خريطة فارغة إن كان المتجر غير متاح أو المنتجات غير مُعرَّفة بعد.
  static Future<Map<String, ProductDetails>> queryProducts() async {
    final available = await isAvailable();
    if (!available) return {};

    final response = await _iap.queryProductDetails(_allProductIds);
    return {for (final product in response.productDetails) product.id: product};
  }

  /// يبدأ الاستماع لتحديثات الشراء. يجب استدعاؤها مرة واحدة عند فتح شاشة
  /// المتجر، و[dispose] عند إغلاقها.
  static void listenToPurchases({
    required void Function(String productId, String message) onCredited,
    required void Function(String message) onError,
  }) {
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      (purchases) async {
        for (final purchase in purchases) {
          switch (purchase.status) {
            case PurchaseStatus.pending:
              break;
            case PurchaseStatus.error:
              onError(purchase.error?.message ?? 'فشلت عملية الشراء، حاول مرة أخرى.');
            case PurchaseStatus.canceled:
              break;
            case PurchaseStatus.purchased:
            case PurchaseStatus.restored:
              final message = await _creditPurchase(purchase.productID);
              if (message != null) onCredited(purchase.productID, message);
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        }
      },
      onError: (Object error) => onError('$error'),
    );
  }

  static Future<String?> _creditPurchase(String productId) async {
    final coinPackage = _findCoinPackage(productId);
    if (coinPackage != null) {
      await CoinWallet.addCoins(coinPackage.coins);
      return 'تمت إضافة ${coinPackage.coins} كوين إلى رصيدك!';
    }
    if (productId == kRemoveAdsProductId) {
      await AdsEntitlement.setRemoved();
      return 'تمت إزالة الإعلانات نهائيًا. استمتع باللعب!';
    }
    final theme = _findPurchasableTheme(productId);
    if (theme != null) {
      await ThemeUnlocks.unlock(theme.id);
      return 'تم فتح مجموعة "${theme.name}"! فعّلها من المتجر.';
    }
    return null;
  }

  /// شراء حزمة كوينز (منتج استهلاكي يمكن شراؤه بشكل متكرر).
  static Future<void> buyCoinPackage(ProductDetails product) {
    return _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  /// شراء إزالة الإعلانات أو مجموعة أشكال (منتج غير استهلاكي، يُملَك مرة واحدة).
  static Future<void> buyNonConsumable(ProductDetails product) {
    return _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  static CoinPackage? _findCoinPackage(String productId) {
    for (final package in kCoinPackages) {
      if (package.productId == productId) return package;
    }
    return null;
  }

  static TileTheme? _findPurchasableTheme(String productId) {
    for (final theme in kTileThemes) {
      if (!theme.free && theme.id == productId) return theme;
    }
    return null;
  }
}
