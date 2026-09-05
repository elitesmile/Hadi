import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tile_model.dart';
import '../theme/app_colors.dart';
import '../widgets/memory_tile.dart';

/// مجموعة الرموز المتاحة (فواكه، حيوانات، أشكال). تُختار 3 منها عشوائيًا
/// في كل جولة لتكوين 3 أزواج = 6 بلاطات.
const List<String> _emojiPool = [
  // فواكه
  '🍎', '🍌', '🍇', '🍉', '🍓', '🍍', '🥝', '🍑',
  // حيوانات
  '🐶', '🐱', '🐵', '🦁', '🐸', '🐼', '🐰', '🦊',
  // أشكال وأخرى
  '⭐', '❤️', '🔵', '🟩', '🔶', '🍀',
];

const int kPairsCount = 3;
const _mismatchPauseMs = 700;
const _matchPauseMs = 350;
const _prefsBestTimeKey = 'best_time_ms';
const _prefsBestAttemptsKey = 'best_attempts';

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
  bool _won = false;

  /// عدد مرات إعادة اللعبة بسبب اختيار خاطئ خلال الجولة الحالية.
  int _attempts = 0;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  Duration? _bestTime;
  int? _bestAttempts;

  @override
  void initState() {
    super.initState();
    _loadBestScores();
    _startNewRound(resetAttempts: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _loadBestScores() async {
    final prefs = await SharedPreferences.getInstance();
    final bestMs = prefs.getInt(_prefsBestTimeKey);
    final bestAttempts = prefs.getInt(_prefsBestAttemptsKey);
    if (!mounted) return;
    setState(() {
      _bestTime = bestMs != null ? Duration(milliseconds: bestMs) : null;
      _bestAttempts = bestAttempts;
    });
  }

  List<TileModel> _buildShuffledTiles() {
    final chosenEmojis = (_emojiPool.toList()..shuffle(_random)).take(kPairsCount).toList();
    final tiles = <TileModel>[];
    for (var pairId = 0; pairId < chosenEmojis.length; pairId++) {
      for (var copy = 0; copy < 2; copy++) {
        tiles.add(TileModel(id: pairId * 2 + copy, pairId: pairId, emoji: chosenEmojis[pairId]));
      }
    }
    tiles.shuffle(_random);
    return tiles;
  }

  void _startNewRound({bool resetAttempts = false}) {
    _ticker?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = _stopwatch.elapsed);
    });
    setState(() {
      _tiles = _buildShuffledTiles();
      _firstIndex = null;
      _wrongIndices.clear();
      _busy = false;
      _won = false;
      _elapsed = Duration.zero;
      if (resetAttempts) _attempts = 0;
    });
  }

  Future<void> _onTileTap(int index) async {
    if (_busy || _won) return;
    final tile = _tiles[index];
    if (tile.revealed || tile.matched) return;

    setState(() => tile.revealed = true);

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    final firstIndex = _firstIndex!;
    final secondIndex = index;
    setState(() => _busy = true);

    final isMatch = _tiles[firstIndex].pairId == _tiles[secondIndex].pairId;

    if (isMatch) {
      await Future.delayed(const Duration(milliseconds: _matchPauseMs));
      if (!mounted) return;
      setState(() {
        _tiles[firstIndex].matched = true;
        _tiles[secondIndex].matched = true;
        _firstIndex = null;
        _busy = false;
      });
      if (_tiles.every((t) => t.matched)) {
        _onWin();
      }
    } else {
      setState(() => _wrongIndices.addAll([firstIndex, secondIndex]));
      await Future.delayed(const Duration(milliseconds: _mismatchPauseMs));
      if (!mounted) return;
      _attempts++;
      _showRestartSnackBar();
      _startNewRound();
    }
  }

  void _showRestartSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ البلاطتان غير متطابقتين! تُعاد اللعبة من جديد.'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.wrong,
      ),
    );
  }

  Future<void> _onWin() async {
    _ticker?.cancel();
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsed;
    setState(() => _won = true);

    final prefs = await SharedPreferences.getInstance();
    var newBestTime = false;
    var newBestAttempts = false;
    if (_bestTime == null || elapsed < _bestTime!) {
      newBestTime = true;
      await prefs.setInt(_prefsBestTimeKey, elapsed.inMilliseconds);
    }
    if (_bestAttempts == null || _attempts < _bestAttempts!) {
      newBestAttempts = true;
      await prefs.setInt(_prefsBestAttemptsKey, _attempts);
    }
    if (!mounted) return;
    setState(() {
      if (newBestTime) _bestTime = elapsed;
      if (newBestAttempts) _bestAttempts = _attempts;
    });
    _showWinDialog(elapsed, newBestTime, newBestAttempts);
  }

  void _showWinDialog(Duration elapsed, bool newBestTime, bool newBestAttempts) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 أحسنت! لقد فزت', style: TextStyle(color: AppColors.textOnDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⏱️ الوقت: ${_formatDuration(elapsed)}${newBestTime ? '  🏆 رقم قياسي جديد!' : ''}',
                style: const TextStyle(color: AppColors.textOnDark)),
            const SizedBox(height: 6),
            Text(
              '🔁 عدد الإعادات بسبب الأخطاء: $_attempts${newBestAttempts ? '  🏆 رقم قياسي جديد!' : ''}',
              style: const TextStyle(color: AppColors.textOnDark),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewRound(resetAttempts: true);
            },
            child: const Text('العب مرة أخرى'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('ذاكرة البلاطات'),
        actions: [
          IconButton(
            tooltip: 'إعادة البدء',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _startNewRound(resetAttempts: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatsBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statChip(Icons.timer_outlined, _formatDuration(_elapsed)),
          _statChip(Icons.replay_rounded, '$_attempts'),
          if (_bestTime != null) _statChip(Icons.emoji_events_outlined, _formatDuration(_bestTime!)),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.tileBack.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold)),
        ],
      ),
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
