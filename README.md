# 🧠 ذاكرة البلاطات (Thakirat Albilat)

لعبة ذاكرة بسيطة مبنية بـ Flutter: 6 بلاطات مقلوبة تخفي 3 أزواج من الرموز
المتشابهة (فواكه، حيوانات، وأشكال). اختر بلاطتين في كل مرة — فإذا تطابقتا
تبقيان مكشوفتين، وإذا لم تتطابقا **تُعاد اللعبة من جديد بالكامل**. حاول
إنهاء اللعبة بأقل عدد من المحاولات وأسرع وقت ممكن، وتحدَّ رقمك القياسي
المحفوظ محليًا على جهازك.

## التشغيل محليًا

```bash
flutter pub get
flutter run
```

## تشغيل الاختبارات والتحليل

```bash
flutter analyze
flutter test
```

## بنية المشروع

```
lib/
  main.dart              نقطة الدخول وإعداد MaterialApp
  models/tile_model.dart      نموذج بيانات البلاطة
  screens/home_screen.dart    شاشة البداية
  screens/game_screen.dart    شاشة اللعب ومنطق اللعبة كاملًا
  widgets/memory_tile.dart    ودجت البلاطة مع أنيميشن القلب
  theme/app_colors.dart       لوحة الألوان الموحّدة
test/widget_test.dart    اختبارات الواجهة والمنطق الأساسي
```

## البناء والنشر على المتجرين

هذا المشروع مُجهَّز بالكامل لبناء نسختي أندرويد و iOS تلقائيًا عبر
GitHub Actions (`.github/workflows/build.yml`) — راجع الأدلة التالية
خطوة بخطوة:

- [`docs/DEV_ACCOUNTS.md`](docs/DEV_ACCOUNTS.md) — إنشاء حسابي Apple
  Developer و Google Play Console.
- [`docs/PUBLISHING_ANDROID.md`](docs/PUBLISHING_ANDROID.md) — توقيع
  وبناء ونشر نسخة أندرويد على Google Play.
- [`docs/PUBLISHING_IOS.md`](docs/PUBLISHING_IOS.md) — بناء وتوقيع ونشر
  نسخة iOS على App Store (عبر Codemagic أو جهاز Mac).

سياسة الخصوصية الجاهزة للاستخدام في المتجرين:
https://claude.ai/code/artifact/d0843028-1373-4a9e-a29a-a1147313d9b2
