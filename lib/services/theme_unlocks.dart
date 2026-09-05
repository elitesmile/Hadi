import 'package:shared_preferences/shared_preferences.dart';

import '../models/tile_theme.dart';

/// يتتبّع مجموعات الرموز (Themes) المملوكة والمختارة حاليًا.
class ThemeUnlocks {
  ThemeUnlocks._();

  static const _ownedKey = 'owned_theme_ids';
  static const _selectedKey = 'selected_theme_id';

  static Future<Set<String>> getOwnedThemeIds() async {
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList(_ownedKey) ?? [];
    return {kDefaultThemeId, ...purchased};
  }

  static Future<void> unlock(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    final owned = prefs.getStringList(_ownedKey) ?? [];
    if (!owned.contains(themeId)) {
      owned.add(themeId);
      await prefs.setStringList(_ownedKey, owned);
    }
  }

  static Future<String> getSelectedThemeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedKey) ?? kDefaultThemeId;
  }

  static Future<void> select(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedKey, themeId);
  }
}
