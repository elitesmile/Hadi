import 'package:shared_preferences/shared_preferences.dart';

/// إدارة رصيد الكوينز المحفوظ محليًا على الجهاز.
///
/// كل جلسة لعب (5 محاولات) تكلّف [costPerSession] كوين، تُخصم مقدّمًا عند
/// الضغط على "ابدأ اللعب". لا يوجد حاليًا أي وسيلة لشراء كوينز إضافية —
/// هذه نقطة توسّع مستقبلية (شراء داخل التطبيق أو مشاهدة إعلان لكوينز مجانية).
class CoinWallet {
  CoinWallet._();

  static const int startingBalance = 200;
  static const int costPerSession = 50;
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
}
