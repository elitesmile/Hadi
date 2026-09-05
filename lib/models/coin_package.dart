/// حزمة كوينز قابلة للشراء داخل التطبيق.
///
/// [productId] يجب أن يطابق حرفيًا معرّف المنتج المُنشأ في App Store
/// Connect (iOS) وGoogle Play Console (Android) — راجع
/// docs/PUBLISHING_IAP.md لمعرفة كيفية إنشاء هذه المنتجات قبل النشر.
class CoinPackage {
  final String productId;
  final int coins;

  /// سعر احتياطي يُعرض فقط إن تعذّر جلب السعر الحقيقي من المتجر
  /// (مثلًا أثناء التطوير قبل ربط حسابات المتجرين).
  final String fallbackPriceLabel;

  const CoinPackage({
    required this.productId,
    required this.coins,
    required this.fallbackPriceLabel,
  });
}

const List<CoinPackage> kCoinPackages = [
  CoinPackage(productId: 'coins_pack_small', coins: 500, fallbackPriceLabel: '4.99\$'),
  CoinPackage(productId: 'coins_pack_medium', coins: 1500, fallbackPriceLabel: '9.99\$'),
  CoinPackage(productId: 'coins_pack_large', coins: 4000, fallbackPriceLabel: '19.99\$'),
];
