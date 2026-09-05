import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'services/ads_service.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // لا ننتظر التهيئة قبل عرض الواجهة حتى لا تتأخر شاشة البداية بسبب
  // الشبكة أو موافقة الخصوصية (UMP) — الإعلانات تُحمَّل في الخلفية.
  AdsService.init();
  runApp(const ThakiratAlbilatApp());
}

/// التطبيق الرئيسي للعبة "ذاكرة البلاطات".
class ThakiratAlbilatApp extends StatelessWidget {
  const ThakiratAlbilatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ذاكرة البلاطات',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.tileBack,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const HomeScreen(),
    );
  }
}
