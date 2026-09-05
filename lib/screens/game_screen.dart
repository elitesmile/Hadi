import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/tile_model.dart';
import '../services/coin_wallet.dart';
import '../theme/app_colors.dart';
import '../widgets/memory_tile.dart';

/// الرموز الثابتة الثلاثة للعبة: طائرة، سيارة، وباخرة — كل رمز بخلفية
/// دائرية بلون مميّز يجعله واضحًا وبارزًا عند القلب.
const List<(String emoji, Color color)> _fixedSymbols = [
  ('✈️', Color(0xFF60A5FA)), // طائرة - أزرق سماوي
  ('🚗', Color(0xFFFB923C)), // سيارة - برتقالي
  ('🚢', Color(0xFF2DD4BF)), // باخرة - فيروزي
];

const int kPairsCount = 3; // يجب أن يطابق طول _fixedSymbols أعلاه

/// عدد المحاولات في الجلسة الواحدة، وعدد الفوز المطلوب لاجتيازها.
const int kSessionAttempts = 5;
const int kRequiredWins = 3;

const _mismatchPauseMs = 900;
const _matchPauseMs = 350;
const _nextAttemptDelayMs = 1100;

enum _AttemptResult { pending, win, loss }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _random = Random();

  late List<TileModel> _tiles;
  int? _firstIndex;
  final Set<int> _wrongIndices = {};
  bool _busy = false;

  /// نتيجة كل محاولة من محاولات الجلسة الخمس.
  final List<_AttemptResult> _attemptResults =
      List.filled(kSessionAttempts, _AttemptResult.pending);
  int _attemptIndex = 0; // 0-based، المحاولة الحالية
  int get _winsCount => _attemptResults.where((r) => r == _AttemptResult.win).length;

  @override
  void initState() {
    super.initState();
    _startAttempt();
  }

  List<TileModel> _buildShuffledTiles() {
    final tiles = <TileModel>[];
    for (var pairId = 0; pairId < _fixedSymbols.length; pairId++) {
      final (emoji, color) = _fixedSymbols[pairId];
      for (var copy = 0; copy < 2; copy++) {
        tiles.add(TileModel(id: pairId * 2 + copy, pairId: pairId, emoji: emoji, accentColor: color));
      }
    }
    tiles.shuffle(_random);
    return tiles;
  }

  void _startAttempt() {
    setState(() {
      _tiles = _buildShuffledTiles();
      _firstIndex = null;
      _wrongIndices.clear();
      _busy = false;
    });
  }

  Future<void> _onTileTap(int index) async {
    if (_busy) return;
    final tile = _tiles[index];
    if (tile.revealed || tile.matched) return;

    setState(() => tile.revealed = true);

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    final firstIndex = _firstIndex!;
    final secondIndex = index;
    _firstIndex = null;
    setState(() => _busy = true);

    final isMatch = _tiles[firstIndex].pairId == _tiles[secondIndex].pairId;

    if (isMatch) {
      await Future.delayed(const Duration(milliseconds: _matchPauseMs));
      if (!mounted) return;
      setState(() {
        _tiles[firstIndex].matched = true;
        _tiles[secondIndex].matched = true;
        _busy = false;
      });
      if (_tiles.every((t) => t.matched)) {
        _finishAttempt(won: true);
      }
    } else {
      setState(() => _wrongIndices.addAll([firstIndex, secondIndex]));
      await Future.delayed(const Duration(milliseconds: _mismatchPauseMs));
      if (!mounted) return;
      _finishAttempt(won: false);
    }
  }

  void _finishAttempt({required bool won}) {
    setState(() {
      _attemptResults[_attemptIndex] = won ? _AttemptResult.win : _AttemptResult.loss;
    });

    _showAttemptResultSnackBar(won);

    final isLastAttempt = _attemptIndex == kSessionAttempts - 1;
    if (isLastAttempt) {
      Future.delayed(const Duration(milliseconds: _nextAttemptDelayMs), () {
        if (!mounted) return;
        _showSessionResultDialog();
      });
    } else {
      Future.delayed(const Duration(milliseconds: _nextAttemptDelayMs), () {
        if (!mounted) return;
        setState(() => _attemptIndex++);
        _startAttempt();
      });
    }
  }

  void _showAttemptResultSnackBar(bool won) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          won
              ? '✅ فزت بالمحاولة ${_attemptIndex + 1}!'
              : '❌ خسرت المحاولة ${_attemptIndex + 1} — البلاطتان غير متطابقتين.',
        ),
        duration: const Duration(milliseconds: _nextAttemptDelayMs),
        backgroundColor: won ? AppColors.matched : AppColors.wrong,
      ),
    );
  }

  Future<void> _showSessionResultDialog() async {
    final passed = _winsCount >= kRequiredWins;
    int? rewardedBalance;
    if (passed) {
      rewardedBalance = await CoinWallet.addCoins(CoinWallet.challengeRewardCoins);
    }
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          passed ? '🎉 اجتزت التحدي!' : '😢 لم تجتز التحدي',
          style: const TextStyle(color: AppColors.textOnDark),
        ),
        content: Text(
          'فزت في $_winsCount من $kSessionAttempts محاولات.\n'
          '${passed ? 'أحسنت! حققت الحد الأدنى المطلوب ($kRequiredWins فوز).' : 'كنت بحاجة إلى $kRequiredWins فوز على الأقل.'}'
          '${passed ? '\n\n🏆 جائزة افتراضية: +${CoinWallet.challengeRewardCoins} كوين!\nرصيدك الآن: $rewardedBalance كوين.' : ''}',
          style: const TextStyle(color: AppColors.textOnDark, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق النافذة
              Navigator.of(context).pop(); // العودة للشاشة الرئيسية
            },
            child: const Text('العودة للرئيسية'),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final newBalance = await CoinWallet.trySpendSessionCost();
              if (!mounted) return;
              navigator.pop(); // إغلاق النافذة
              if (newBalance == null) {
                navigator.pop(); // لا يوجد رصيد كافٍ، العودة للرئيسية
                return;
              }
              setState(() {
                _attemptIndex = 0;
                for (var i = 0; i < kSessionAttempts; i++) {
                  _attemptResults[i] = _AttemptResult.pending;
                }
              });
              _startAttempt();
            },
            child: Text('العب مرة أخرى (${CoinWallet.costPerSession} 🪙)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('ذاكرة البلاطات'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'المحاولة ${_attemptIndex + 1} من $kSessionAttempts — يلزم $kRequiredWins فوز',
            style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < kSessionAttempts; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _attemptPip(_attemptResults[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _attemptPip(_AttemptResult result) {
    late final Color color;
    late final Widget child;
    switch (result) {
      case _AttemptResult.win:
        color = AppColors.matched;
        child = const Icon(Icons.check, size: 16, color: Colors.white);
      case _AttemptResult.loss:
        color = AppColors.wrong;
        child = const Icon(Icons.close, size: 16, color: Colors.white);
      case _AttemptResult.pending:
        color = AppColors.tileBack;
        child = const SizedBox.shrink();
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.tileBackHighlight, width: 1.5),
      ),
      child: child,
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        itemCount: _tiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final tile = _tiles[index];
          return MemoryTile(
            emoji: tile.emoji,
            accentColor: tile.accentColor,
            faceUp: tile.revealed,
            matched: tile.matched,
            wrong: _wrongIndices.contains(index),
            onTap: () => _onTileTap(index),
          );
        },
      ),
    );
  }
}
