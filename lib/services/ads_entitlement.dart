import 'package:shared_preferences/shared_preferences.dart';

/// يتتبّع ما إذا اشترى المستخدم "إزالة الإعلانات" (منتج غير استهلاكي).
class AdsEntitlement {
  AdsEntitlement._();

  static const _prefsKey = 'ads_removed';

  static Future<bool> isRemoved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> setRemoved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }
}
