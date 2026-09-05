import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/coin_package.dart';
import '../services/coin_wallet.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';

/// شاشة شحن الكوينز عبر الشراء داخل التطبيق (In-App Purchase).
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
  final Set<String> _purchasingIds = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    StoreService.listenToPurchases(
      onCoinsCredited: (package, newBalance) {
        if (!mounted) return;
        setState(() {
          _balance = newBalance;
          _purchasingIds.remove(package.productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تمت إضافة ${package.coins} كوين إلى رصيدك!'),
            backgroundColor: AppColors.matched,
          ),
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

    final balance = await CoinWallet.getBalance();
    final available = await StoreService.isAvailable();
    final products = available ? await StoreService.queryProducts() : <String, ProductDetails>{};

    if (!mounted) return;
    setState(() {
      _balance = balance;
      _storeAvailable = available;
      _products = products;
      _loading = false;
    });
  }

  @override
  void dispose() {
    StoreService.dispose();
    super.dispose();
  }

  Future<void> _onBuyPressed(CoinPackage package) async {
    final product = _products[package.productId];
    if (product == null) return;
    setState(() => _purchasingIds.add(package.productId));
    try {
      await StoreService.buy(product);
    } catch (e) {
      if (!mounted) return;
      setState(() => _purchasingIds.remove(package.productId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ تعذّر بدء الشراء: $e'), backgroundColor: AppColors.wrong),
      );
    }
  }

  /// وضع تطوير فقط: يضيف الكوينز مباشرة بدون المرور بمتجر حقيقي، لاختبار
  /// الواجهة قبل ربط حسابات App Store Connect / Google Play Console.
  Future<void> _debugCreditPackage(CoinPackage package) async {
    final newBalance = await CoinWallet.addCoins(package.coins);
    if (!mounted) return;
    setState(() => _balance = newBalance);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🧪 (وضع التطوير) أُضيف ${package.coins} كوين تجريبيًا')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('شحن الكوينز'),
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
                  const SizedBox(height: 8),
                  for (final package in kCoinPackages) _packageCard(package),
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.tileBackHighlight),
                    const SizedBox(height: 8),
                    const Text(
                      '🧪 وضع التطوير — محاكاة شراء بدون متجر حقيقي',
                      style: TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    for (final package in kCoinPackages) _debugPackageRow(package),
                  ],
                ],
              ),
      ),
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
      margin: const EdgeInsets.only(bottom: 8),
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

  Widget _packageCard(CoinPackage package) {
    final product = _products[package.productId];
    final priceLabel = product?.price ?? package.fallbackPriceLabel;
    final isPurchasing = _purchasingIds.contains(package.productId);
    final canBuy = _storeAvailable && product != null && !isPurchasing;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tileFront.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.tileBackHighlight.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Text('🪙', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${package.coins} كوين',
              style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.background),
            onPressed: canBuy ? () => _onBuyPressed(package) : null,
            child: isPurchasing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                  )
                : Text(priceLabel),
          ),
        ],
      ),
    );
  }

  Widget _debugPackageRow(CoinPackage package) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.textOnDark),
        onPressed: () => _debugCreditPackage(package),
        child: Text('+ ${package.coins} كوين (محاكاة)'),
      ),
    );
  }
}
