import 'package:flutter/material.dart';

/// لوحة ألوان اللعبة الثابتة (نفس الألوان في الوضع الفاتح والداكن
/// حفاظًا على هوية بصرية موحّدة للعبة).
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF1E1B4B); // بنفسجي داكن
  static const Color backgroundLight = Color(0xFF4C1D95);
  static const Color tileBack = Color(0xFF6D28D9);
  static const Color tileBackHighlight = Color(0xFF8B5CF6);
  static const Color tileFront = Color(0xFFFDF4FF);
  static const Color matched = Color(0xFF34D399);
  static const Color wrong = Color(0xFFF87171);
  static const Color accent = Color(0xFFFBBF24);
  static const Color textOnDark = Color(0xFFF5F3FF);
}
