import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/coin_package.dart';
import '../models/tile_theme.dart';
import '../services/ads_entitlement.dart';
import '../services/coin_wallet.dart';
import '../services/store_service.dart';
import '../services/theme_unlocks.dart';
import '../theme/app_colors.dart';

/// شاشة المتجر: شحن الكوينز، إزالة الإعلانات، ومجموعات الأشكال (Themes).
class CoinStoreScreen extends StatefulWidget {
  const CoinStoreScreen({super.key});

  @override
  State<CoinStoreScreen> createState() => _CoinStoreScreenState();
}

class _CoinStoreScreenState extends State<CoinStoreScreen> {
  bool _loading = true;
  bool _storeAvailable = false;
  Map<String, ProductDetails> _products = {};
  int? _balance;
  bool _adsRemoved = false;
  Set<String> _ownedThemeIds = {};
  String _selectedThemeId = kDefaultThemeId;
  final Set<String> _purchasingIds = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    StoreService.listenToPurchases(
      onCredited: (productId, message) async {
        await _refreshEntitlements();
        if (!mounted) return;
        setState(() => _purchasingIds.remove(productId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ $message'), backgroundColor: AppColors.matched),
        );
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _purchasingIds.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ $message'), backgroundColor: AppColors.wrong),
        );
      },
    );

    final available = await StoreService.isAvailable();
    final products = available ? await StoreService.queryProducts() : <String, ProductDetails>{};

    if (!mounted) return;
    setState(() {
      _storeAvailable = available;
      _products = products;
      _loading = false;
    });
    await _refreshEntitlements();
  }

  Future<void> _refreshEntitlements() async {
    final balance = await CoinWallet.getBalance();
    final adsRemoved = await AdsEntitlement.isRemoved();
    final owned = await ThemeUnlocks.getOwnedThemeIds();
    final selected = await ThemeUnlocks.getSelectedThemeId();
    if (!mounted) return;
    setState(() {
      _balance = balance;
      _adsRemoved = adsRemoved;
      _ownedThemeIds = owned;
      _selectedThemeId = selected;
    });
  }

  @override
  void dispose() {
    StoreService.dispose();
    super.dispose();
  }

  Future<void> _buyCoinPackage(CoinPackage package) async {
    final product = _products[package.productId];
    if (product == null) return;
    setState(() => _purchasingIds.add(package.productId));
    try {
      await StoreService.buyCoinPackage(product);
    } catch (e) {
      _onBuyError(package.productId, e);
    }
  }

  Future<void> _buyNonConsumable(String productId) async {
    final product = _products[productId];
    if (product == null) return;
    setState(() => _purchasingIds.add(productId));
    try {
      await StoreService.buyNonConsumable(product);
    } catch (e) {
      _onBuyError(productId, e);
    }
  }

  void _onBuyError(String productId, Object error) {
    if (!mounted) return;
    setState(() => _purchasingIds.remove(productId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('⚠️ تعذّر بدء الشراء: $error'), backgroundColor: AppColors.wrong),
    );
  }

  Future<void> _selectTheme(String themeId) async {
    await ThemeUnlocks.select(themeId);
    await _refreshEntitlements();
  }

  /// وضع تطوير فقط: يمنح المُلكية مباشرة بدون المرور بمتجر حقيقي، لاختبار
  /// الواجهة قبل ربط حسابات App Store Connect / Google Play Console.
  Future<void> _debugCreditCoins(CoinPackage package) async {
    await CoinWallet.addCoins(package.coins);
    await _refreshEntitlements();
    _showDebugSnack('${package.coins} كوين');
  }

  Future<void> _debugRemoveAds() async {
    await AdsEntitlement.setRemoved();
    await _refreshEntitlements();
    _showDebugSnack('إزالة الإعلانات');
  }

  Future<void> _debugUnlockTheme(TileTheme theme) async {
    await ThemeUnlocks.unlock(theme.id);
    await _refreshEntitlements();
    _showDebugSnack('مجموعة "${theme.name}"');
  }

  void _showDebugSnack(String what) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🧪 (وضع التطوير) مُنح: $what')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('المتجر'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _balanceHeader(),
                  const SizedBox(height: 20),
                  if (!_storeAvailable) _unavailableBanner(),
                  _sectionTitle('🪙 حزم الكوينز'),
                  for (final package in kCoinPackages) _coinPackageCard(package),
                  const SizedBox(height: 20),
                  _sectionTitle('🚫 إزالة الإعلانات'),
                  _removeAdsCard(),
                  const SizedBox(height: 20),
                  _sectionTitle('🎨 مجموعات الأشكال'),
                  for (final theme in kTileThemes) _themeCard(theme),
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.tileBackHighlight),
                    const SizedBox(height: 8),
                    const Text(
                      '🧪 وضع التطوير — محاكاة الشراء بدون متجر حقيقي',
                      style: TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    for (final package in kCoinPackages)
                      _debugRow('+ ${package.coins} كوين', () => _debugCreditCoins(package)),
                    _debugRow('إزالة الإعلانات', _debugRemoveAds),
                    for (final theme in kTileThemes.where((t) => !t.free))
                      _debugRow('فتح "${theme.name}"', () => _debugUnlockTheme(theme)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _balanceHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.tileBack.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '🪙 رصيدك الحالي: ${_balance ?? '...'} كوين',
        style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _unavailableBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.wrong.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.wrong.withValues(alpha: 0.4)),
      ),
      child: const Text(
        'المتجر غير متاح حاليًا على هذا الجهاز (يحتاج نشر التطبيق وربط '
        'منتجات الشراء في App Store Connect / Google Play Console أولًا).',
        style: TextStyle(color: AppColors.textOnDark, height: 1.6),
      ),
    );
  }

  Widget _buyButton({required bool canBuy, required bool isPurchasing, required String label, required VoidCallback onTap}) {
    return FilledButton(
      style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.background),
      onPressed: canBuy ? onTap : null,
      child: isPurchasing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
            )
          : Text(label),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tileFront.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.tileBackHighlight.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }

  Widget _coinPackageCard(CoinPackage package) {
    final product = _products[package.productId];
    final priceLabel = product?.price ?? package.fallbackPriceLabel;
    final isPurchasing = _purchasingIds.contains(package.productId);
    final canBuy = _storeAvailable && product != null && !isPurchasing;

    return _cardShell(
      child: Row(
        children: [
          const Text('🪙', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${package.coins} كوين',
                style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          _buyButton(
            canBuy: canBuy,
            isPurchasing: isPurchasing,
            label: priceLabel,
            onTap: () => _buyCoinPackage(package),
          ),
        ],
      ),
    );
  }

  Widget _removeAdsCard() {
    if (_adsRemoved) {
      return _cardShell(
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.matched),
            SizedBox(width: 12),
            Expanded(
              child: Text('تمت إزالة الإعلانات ✔️',
                  style: TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
    final product = _products[kRemoveAdsProductId];
    final isPurchasing = _purchasingIds.contains(kRemoveAdsProductId);
    final canBuy = _storeAvailable && product != null && !isPurchasing;
    return _cardShell(
      child: Row(
        children: [
          const Text('🚫', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('إزالة كل الإعلانات نهائيًا',
                style: TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          _buyButton(
            canBuy: canBuy,
            isPurchasing: isPurchasing,
            label: product?.price ?? '2.99\$',
            onTap: () => _buyNonConsumable(kRemoveAdsProductId),
          ),
        ],
      ),
    );
  }

  Widget _themeCard(TileTheme theme) {
    final owned = theme.free || _ownedThemeIds.contains(theme.id);
    final isSelected = _selectedThemeId == theme.id;
    final product = _products[theme.id];
    final isPurchasing = _purchasingIds.contains(theme.id);
    final canBuy = _storeAvailable && product != null && !isPurchasing;

    return _cardShell(
      child: Row(
        children: [
          Row(
            children: theme.symbols
                .map((s) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(s.$1, style: const TextStyle(fontSize: 22)),
                    ))
                .toList(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(theme.name,
                style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          if (owned)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: isSelected ? AppColors.matched : AppColors.textOnDark,
                side: BorderSide(color: isSelected ? AppColors.matched : AppColors.tileBackHighlight),
              ),
              onPressed: isSelected ? null : () => _selectTheme(theme.id),
              child: Text(isSelected ? 'مفعّلة ✔️' : 'تفعيل'),
            )
          else
            _buyButton(
              canBuy: canBuy,
              isPurchasing: isPurchasing,
              label: product?.price ?? '1.99\$',
              onTap: () => _buyNonConsumable(theme.id),
            ),
        ],
      ),
    );
  }

  Widget _debugRow(String label, Future<void> Function() onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.textOnDark),
        onPressed: onTap,
        child: Text('+ $label (محاكاة)'),
      ),
    );
  }
}
