import 'package:shared_preferences/shared_preferences.dart';

/// إدارة رصيد الكوينز المحفوظ محليًا على الجهاز.
///
/// كل جلسة لعب (5 محاولات) تكلّف [costPerSession] كوين، تُخصم مقدّمًا عند
/// الضغط على "ابدأ اللعب". الرصيد يزداد عبر:
/// - شراء حزم كوينز حقيقية داخل التطبيق (راجع StoreService).
/// - جائزة افتراضية تُمنح عند اجتياز التحدي (راجع [challengeRewardCoins]).
class CoinWallet {
  CoinWallet._();

  static const int startingBalance = 200;
  static const int costPerSession = 50;

  /// جائزة كوينز افتراضية (وهمية داخل اللعبة، ليست مالًا حقيقيًا) تُمنح
  /// فور اجتياز التحدي (الفوز في 3 محاولات من أصل 5).
  static const int challengeRewardCoins = 5000;

  static const _prefsKey = 'coin_balance';

  static Future<int> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsKey) ?? startingBalance;
  }

  /// يحاول خصم [costPerSession] كوين. يُرجع الرصيد الجديد إن نجح، أو null
  /// إن كان الرصيد غير كافٍ (لا يُخصم شيء في هذه الحالة).
  static Future<int?> trySpendSessionCost() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_prefsKey) ?? startingBalance;
    if (current < costPerSession) return null;
    final updated = current - costPerSession;
    await prefs.setInt(_prefsKey, updated);
    return updated;
  }

  /// يضيف [amount] كوين إلى الرصيد (نتيجة شراء داخل التطبيق أو جائزة
  /// افتراضية) ويُرجع الرصيد الجديد.
  static Future<int> addCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_prefsKey) ?? startingBalance;
    final updated = current + amount;
    await prefs.setInt(_prefsKey, updated);
    return updated;
  }
}
