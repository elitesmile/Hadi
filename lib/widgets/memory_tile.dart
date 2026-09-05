import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// بطاقة بلاطة واحدة مع أنيميشن قلب ثلاثي الأبعاد بين الوجه الخلفي
/// (مغلقة) والوجه الأمامي (الإيموجي).
class MemoryTile extends StatelessWidget {
  final String emoji;
  final bool faceUp;
  final bool matched;
  final bool wrong;
  final VoidCallback onTap;

  const MemoryTile({
    super.key,
    required this.emoji,
    required this.faceUp,
    required this.matched,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: faceUp || matched ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          final angle = value * math.pi;
          final showFront = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildFront(),
                  )
                : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildBack() {
    return _tileContainer(
      color: AppColors.tileBack,
      borderColor: AppColors.tileBackHighlight,
      child: const Icon(
        Icons.help_outline_rounded,
        color: AppColors.tileBackHighlight,
        size: 30,
      ),
    );
  }

  Widget _buildFront() {
    return _tileContainer(
      color: matched ? AppColors.matched.withValues(alpha: 0.25) : AppColors.tileFront,
      borderColor: wrong
          ? AppColors.wrong
          : matched
              ? AppColors.matched
              : AppColors.tileBackHighlight,
      child: Text(emoji, style: const TextStyle(fontSize: 34)),
    );
  }

  Widget _tileContainer({
    required Color color,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
