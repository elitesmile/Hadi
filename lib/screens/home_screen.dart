import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'game_screen.dart';

/// شاشة البداية: عنوان اللعبة، شرح مختصر لقواعدها، وزر بدء اللعب.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🧠', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 16),
                const Text(
                  'ذاكرة البلاطات',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tileBack.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '6 بلاطات مقلوبة تخفي 3 أزواج متشابهة.\n'
                    'اختر بلاطتين في كل مرة، وإذا لم تتطابقا فستُعاد اللعبة من جديد!\n'
                    'حاول إنهاء اللعبة بأقل عدد من المحاولات وأسرع وقت ممكن.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textOnDark, height: 1.6),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GameScreen()),
                      );
                    },
                    child: const Text('ابدأ اللعب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
