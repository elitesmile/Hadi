import 'package:flutter/material.dart';

/// مجموعة رموز بديلة (شكلية بحتة) يمكن للاعب شراءها وتفعيلها بدل
/// المجموعة الافتراضية (طائرة/سيارة/باخرة). كل قيمة شراء ثابتة ومعروفة
/// مسبقًا (وليست عشوائية) لتفادي أي تصنيف كصناديق غنائم.
class TileTheme {
  /// معرّف المجموعة، وهو نفسه معرّف المنتج (Product ID) عند الشراء —
  /// باستثناء المجموعة المجانية [kDefaultThemeId] التي لا تحتاج شراء.
  final String id;
  final String name;
  final bool free;

  /// يجب أن يطابق طولها kPairsCount في game_screen.dart (حاليًا 3).
  final List<(String emoji, Color color)> symbols;

  const TileTheme({
    required this.id,
    required this.name,
    required this.symbols,
    this.free = false,
  });
}

const String kDefaultThemeId = 'theme_default';

const List<TileTheme> kTileThemes = [
  TileTheme(
    id: kDefaultThemeId,
    name: 'المركبات',
    free: true,
    symbols: [
      ('✈️', Color(0xFF60A5FA)),
      ('🚗', Color(0xFFFB923C)),
      ('🚢', Color(0xFF2DD4BF)),
    ],
  ),
  TileTheme(
    id: 'theme_ocean',
    name: 'أعماق البحر',
    symbols: [
      ('🐠', Color(0xFF38BDF8)),
      ('🐙', Color(0xFFA78BFA)),
      ('🦀', Color(0xFFF87171)),
    ],
  ),
  TileTheme(
    id: 'theme_space',
    name: 'الفضاء',
    symbols: [
      ('🚀', Color(0xFFF472B6)),
      ('🛸', Color(0xFF34D399)),
      ('🪐', Color(0xFFFBBF24)),
    ],
  ),
];

TileTheme themeById(String id) => kTileThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => kTileThemes.first,
    );
