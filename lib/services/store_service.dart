import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/coin_package.dart';
import 'coin_wallet.dart';

/// طبقة رقيقة فوق حزمة in_app_purchase الرسمية لإدارة شراء حزم الكوينز.
///
/// ملاحظة مهمة: الشراء الحقيقي يعمل فقط بعد إنشاء معرّفات المنتجات في
/// App Store Connect وGoogle Play Console بنفس القيم في [kCoinPackages]،
/// ورفع نسخة على الأقل كمسودة في كل متجر. راجع docs/PUBLISHING_IAP.md.
class StoreService {
  StoreService._();

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  static Future<bool> isAvailable() => _iap.isAvailable();

  /// يجلب تفاصيل المنتجات (الأسعار الحقيقية بعملة المستخدم) من المتجر.
  /// يُرجع خريطة فارغة إن كان المتجر غير متاح أو المنتجات غير مُعرَّفة بعد.
  static Future<Map<String, ProductDetails>> queryProducts() async {
    final available = await isAvailable();
    if (!available) return {};

    final ids = kCoinPackages.map((p) => p.productId).toSet();
    final response = await _iap.queryProductDetails(ids);
    return {for (final product in response.productDetails) product.id: product};
  }

  /// يبدأ الاستماع لتحديثات الشراء. يجب استدعاؤها مرة واحدة عند فتح شاشة
  /// المتجر، و[dispose] عند إغلاقها.
  static void listenToPurchases({
    required void Function(CoinPackage package, int newBalance) onCoinsCredited,
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
              final package = _findPackage(purchase.productID);
              if (package != null) {
                final newBalance = await CoinWallet.addCoins(package.coins);
                onCoinsCredited(package, newBalance);
              }
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        }
      },
      onError: (Object error) => onError('$error'),
    );
  }

  static Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    // الكوينز عملة استهلاكية (تُشترى بشكل متكرر)، لذا نستخدم buyConsumable.
    await _iap.buyConsumable(purchaseParam: param);
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  static CoinPackage? _findPackage(String productId) {
    for (final package in kCoinPackages) {
      if (package.productId == productId) return package;
    }
    return null;
  }
}
