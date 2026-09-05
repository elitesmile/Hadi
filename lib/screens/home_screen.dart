import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_entitlement.dart';
import '../services/ads_service.dart';
import '../services/coin_wallet.dart';
import '../theme/app_colors.dart';
import 'coin_store_screen.dart';
import 'game_screen.dart';

/// مكافأة الكوينز مقابل مشاهدة إعلان اختياري كامل حتى النهاية.
const int kRewardedAdCoins = 20;

/// شاشة البداية: عنوان اللعبة، شرح مختصر لقواعدها، رصيد الكوينز، وزر بدء
/// اللعب الذي يخصم تكلفة الجلسة قبل الدخول.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _balance;
  bool _adsRemoved = false;
  bool _watchingAd = false;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final balance = await CoinWallet.getBalance();
    final adsRemoved = await AdsEntitlement.isRemoved();
    if (!mounted) return;
    setState(() {
      _balance = balance;
      _adsRemoved = adsRemoved;
    });
  }

  Future<void> _loadBannerAd() async {
    if (await AdsEntitlement.isRemoved()) return;
    try {
      final ad = BannerAd(
        adUnitId: AdsService.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (loadedAd) {
            if (!mounted) {
              loadedAd.dispose();
              return;
            }
            setState(() => _bannerAd = loadedAd as BannerAd);
          },
          onAdFailedToLoad: (loadedAd, error) => loadedAd.dispose(),
        ),
      );
      await ad.load();
    } catch (_) {
      // بيئة بدون منصة إعلانات حقيقية (كالاختبارات) — نتجاهل بأمان.
    }
  }

  Future<void> _onPlayPressed() async {
    final newBalance = await CoinWallet.trySpendSessionCost();
    if (!mounted) return;
    if (newBalance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🪙 رصيدك غير كافٍ! تحتاج 50 كوين على الأقل لبدء التحدي.'),
          backgroundColor: AppColors.wrong,
        ),
      );
      return;
    }
    setState(() => _balance = newBalance);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
    await AdsService.showInterstitialIfReady();
    _loadState(); // تحديث الرصيد المعروض بعد العودة (قد تغيّر أثناء اللعب)
  }

  Future<void> _onStorePressed() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CoinStoreScreen()),
    );
    _loadState();
    _loadBannerAd(); // قد يكون المستخدم اشترى إزالة الإعلانات داخل المتجر
  }

  Future<void> _onWatchAdPressed() async {
    setState(() => _watchingAd = true);
    final started = await AdsService.showRewardedAd(
      onEarnedReward: () async {
        final newBalance = await CoinWallet.addCoins(kRewardedAdCoins);
        if (!mounted) return;
        setState(() => _balance = newBalance);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ حصلت على $kRewardedAdCoins كوين مجانًا!'),
            backgroundColor: AppColors.matched,
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() => _watchingAd = false);
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏳ الإعلان غير جاهز الآن، حاول بعد قليل.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _balance;
    final canAfford = balance == null || balance >= CoinWallet.costPerSession;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🧠', style: TextStyle(fontSize: 72)),
                      const SizedBox(height: 16),
                      const Text(
                        'ذاكرة البلاطات',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _coinBadge(balance),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: AppColors.accent),
                            tooltip: 'المتجر',
                            icon: const Icon(Icons.storefront, color: AppColors.background),
                            onPressed: _onStorePressed,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.tileBack.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '6 بلاطات مقلوبة تخفي 3 أزواج متشابهة (طائرة، سيارة، باخرة).\n'
                          'أمامك 5 محاولات، ويجب أن تفوز في 2 منها على الأقل لتجتاز التحدي.\n'
                          'كل مرة تريد اللعب فيها تُخصم 50 كوين من رصيدك.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textOnDark, height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: canAfford ? AppColors.accent : AppColors.tileBack,
                            foregroundColor: canAfford ? AppColors.background : AppColors.textOnDark,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: canAfford ? _onPlayPressed : null,
                          child: Text(
                            'ابدأ اللعب (${CoinWallet.costPerSession} 🪙)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (!canAfford) ...[
                        const SizedBox(height: 10),
                        const Text(
                          '🪙 رصيدك غير كافٍ لبدء تحدٍّ جديد.',
                          style: TextStyle(color: AppColors.wrong, fontWeight: FontWeight.bold),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textOnDark,
                            side: const BorderSide(color: AppColors.tileBackHighlight),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _watchingAd ? null : _onWatchAdPressed,
                          icon: const Icon(Icons.smart_display_outlined),
                          label: Text(_watchingAd
                              ? 'جارٍ التحميل...'
                              : 'شاهد إعلانًا واحصل على $kRewardedAdCoins كوين مجانًا'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_adsRemoved && _bannerAd != null)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _coinBadge(int? balance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            balance == null ? '...' : '$balance كوين',
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
