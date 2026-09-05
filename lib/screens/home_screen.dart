import 'package:flutter/material.dart';

import '../services/coin_wallet.dart';
import '../theme/app_colors.dart';
import 'game_screen.dart';

/// شاشة البداية: عنوان اللعبة، شرح مختصر لقواعدها، رصيد الكوينز، وزر بدء
/// اللعب الذي يخصم تكلفة الجلسة قبل الدخول.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _balance;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final balance = await CoinWallet.getBalance();
    if (!mounted) return;
    setState(() => _balance = balance);
  }

  Future<void> _onPlayPressed() async {
    final newBalance = await CoinWallet.trySpendSessionCost();
    if (!mounted) return;
    if (newBalance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🪙 رصيدك غير كافٍ! تحتاج 50 كوين على الأقل لبدء التحدي.'),
          backgroundColor: AppColors.wrong,
        ),
      );
      return;
    }
    setState(() => _balance = newBalance);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
    _loadBalance(); // تحديث الرصيد المعروض بعد العودة (قد تغيّر أثناء اللعب)
  }

  @override
  Widget build(BuildContext context) {
    final balance = _balance;
    final canAfford = balance == null || balance >= CoinWallet.costPerSession;

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
                const SizedBox(height: 12),
                _coinBadge(balance),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tileBack.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '6 بلاطات مقلوبة تخفي 3 أزواج متشابهة (طائرة، سيارة، باخرة).\n'
                    'أمامك 5 محاولات، ويجب أن تفوز في 3 منها على الأقل لتجتاز التحدي.\n'
                    'كل مرة تريد اللعب فيها تُخصم 50 كوين من رصيدك.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textOnDark, height: 1.6),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: canAfford ? AppColors.accent : AppColors.tileBack,
                      foregroundColor: canAfford ? AppColors.background : AppColors.textOnDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: canAfford ? _onPlayPressed : null,
                    child: Text(
                      'ابدأ اللعب (${CoinWallet.costPerSession} 🪙)',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (!canAfford) ...[
                  const SizedBox(height: 10),
                  const Text(
                    '🪙 رصيدك غير كافٍ لبدء تحدٍّ جديد.',
                    style: TextStyle(color: AppColors.wrong, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coinBadge(int? balance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            balance == null ? '...' : '$balance كوين',
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
