# 🧠 ذاكرة البلاطات (Thakirat Albilat)

لعبة ذاكرة بسيطة مبنية بـ Flutter: 6 بلاطات مقلوبة تخفي 3 أزواج من رموز
ثابتة وواضحة (✈️ طائرة، 🚗 سيارة، 🚢 باخرة) بشارات ملوّنة كبيرة. كل تحدٍّ
يتكوّن من **5 محاولات**، ويجب الفوز في **3 منها على الأقل** لاجتياز
التحدي — وكل مرة تريد اللعب فيها تُخصم **50 كوين** من رصيدك (يبدأ الرصيد
بـ 200 كوين محفوظة محليًا على الجهاز). اجتياز التحدي يمنحك **جائزة
افتراضية داخل اللعبة** (5000 كوين إضافية — ليست مالًا حقيقيًا)، ويمكن
أيضًا شحن الرصيد عبر حزم شراء داخل التطبيق (In-App Purchase).

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
  main.dart                     نقطة الدخول وإعداد MaterialApp
  models/tile_model.dart        نموذج بيانات البلاطة
  models/coin_package.dart      حزم شراء الكوينز داخل التطبيق
  screens/home_screen.dart      شاشة البداية
  screens/game_screen.dart      شاشة اللعب ومنطق اللعبة كاملًا
  screens/coin_store_screen.dart  شاشة شحن الكوينز (IAP)
  services/coin_wallet.dart     رصيد الكوينز المحفوظ محليًا
  services/store_service.dart   طبقة الشراء داخل التطبيق
  widgets/memory_tile.dart      ودجت البلاطة مع أنيميشن القلب
  theme/app_colors.dart         لوحة الألوان الموحّدة
test/widget_test.dart       اختبارات الواجهة والمنطق الأساسي
test/coin_wallet_test.dart  اختبارات وحدة لمحفظة الكوينز
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
- [`docs/PUBLISHING_IAP.md`](docs/PUBLISHING_IAP.md) — إنشاء منتجات شحن
  الكوينز في المتجرين قبل أن يعمل الشراء الحقيقي.

سياسة الخصوصية الجاهزة للاستخدام في المتجرين:
https://claude.ai/code/artifact/d0843028-1373-4a9e-a29a-a1147313d9b2
