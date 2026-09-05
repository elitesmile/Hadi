import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_entitlement.dart';

/// طبقة إدارة الإعلانات (AdMob): تهيئة الحزمة، طلب موافقة الخصوصية
/// (UMP/GDPR)، وتحميل/عرض الإعلانات البينية وإعلانات المكافأة.
///
/// ⚠️ معرّفات الوحدات الإعلانية أدناه هي معرّفات آبل/جوجل التجريبية
/// الرسمية (Test Ad Unit IDs) — تعمل فورًا للتجربة لكنها **لا تُدرّ أي
/// عائد حقيقي**. استبدلها بمعرّفاتك الحقيقية من حساب AdMob قبل النشر،
/// راجع docs/PUBLISHING_ADS.md.
class AdsService {
  AdsService._();

  static bool _initialized = false;
  static bool _consentRequested = false;

  static String get bannerAdUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get interstitialAdUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';

  static String get rewardedAdUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/1712485313'
      : 'ca-app-pub-3940256099942544/5224354917';

  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;

  /// يهيّئ SDK ويطلب موافقة الخصوصية (GDPR/UMP) إن كانت مطلوبة جغرافيًا،
  /// ثم يحمّل أول إعلان بيني وإعلان مكافأة مسبقًا. آمن للاستدعاء عدة مرات.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _requestConsent();
      await MobileAds.instance.initialize();
      _initialized = true;
      unawaited(_loadInterstitial());
      unawaited(_loadRewarded());
    } catch (e) {
      // يحدث هذا عادة في بيئة بدون منصة حقيقية (كاختبارات الوحدة)، أو
      // بدون اتصال إنترنت — نتجاهله بأمان بدل تعطيل التطبيق بالكامل.
      debugPrint('AdsService.init failed (safe to ignore in tests): $e');
    }
  }

  static Future<void> _requestConsent() async {
    if (_consentRequested) return;
    _consentRequested = true;
    final completer = Completer<void>();
    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            await _loadAndShowConsentForm();
          }
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError error) {
        debugPrint('UMP consent request failed: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );
    // لا ننتظر أكثر من ثانيتين حتى لا نعطّل بدء التطبيق إن تأخّرت الشبكة.
    await completer.future.timeout(const Duration(seconds: 2), onTimeout: () {});
  }

  static Future<void> _loadAndShowConsentForm() {
    final completer = Completer<void>();
    ConsentForm.loadConsentForm(
      (ConsentForm form) {
        form.show((FormError? error) {
          completer.complete();
        });
      },
      (FormError error) {
        debugPrint('Loading consent form failed: ${error.message}');
        completer.complete();
      },
    );
    return completer.future;
  }

  static Future<void> _loadInterstitial() async {
    if (await AdsEntitlement.isRemoved()) return;
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => debugPrint('Interstitial failed: $error'),
      ),
    );
  }

  static Future<void> _loadRewarded() async {
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) => debugPrint('Rewarded ad failed: $error'),
      ),
    );
  }

  /// يعرض إعلانًا بينيًا إن كان محمَّلًا ولم يشترِ المستخدم إزالة
  /// الإعلانات، ثم يحمّل واحدًا جديدًا للمرة القادمة. لا يفعل شيئًا
  /// إن لم يكن هناك إعلان جاهز (لا يُعطّل تدفق اللعبة أبدًا).
  static Future<void> showInterstitialIfReady() async {
    if (await AdsEntitlement.isRemoved()) return;
    final ad = _interstitialAd;
    if (ad == null) return;
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(_loadInterstitial());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        unawaited(_loadInterstitial());
      },
    );
    await ad.show();
  }

  static bool get isRewardedAdReady => _rewardedAd != null;

  /// يعرض إعلان مكافأة، ويستدعي [onEarnedReward] فقط إن أكمل المستخدم
  /// المشاهدة فعلًا. يُرجع false فورًا إن لم يكن هناك إعلان جاهز، حتى
  /// تُظهر الواجهة رسالة "الإعلان غير متاح الآن" بدل تجميد الشاشة.
  static Future<bool> showRewardedAd({required void Function() onEarnedReward}) async {
    final ad = _rewardedAd;
    if (ad == null) return false;
    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(_loadRewarded());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        unawaited(_loadRewarded());
      },
    );
    await ad.show(onUserEarnedReward: (_, reward) => onEarnedReward());
    return true;
  }
}
