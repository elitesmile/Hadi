import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// بطاقة بلاطة واحدة مع أنيميشن قلب ثلاثي الأبعاد بين الوجه الخلفي
/// (مغلقة) والوجه الأمامي (شارة دائرية ملوّنة تحتضن الرمز لتكون
/// واضحة وبارزة وكبيرة).
class MemoryTile extends StatelessWidget {
  final String emoji;
  final Color accentColor;
  final bool faceUp;
  final bool matched;
  final bool wrong;
  final VoidCallback onTap;

  const MemoryTile({
    super.key,
    required this.emoji,
    required this.accentColor,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortSide = math.min(constraints.maxWidth, constraints.maxHeight);
          return Icon(
            Icons.help_outline_rounded,
            color: AppColors.tileBackHighlight,
            size: shortSide * 0.42,
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return _tileContainer(
      color: matched ? AppColors.matched.withValues(alpha: 0.18) : AppColors.tileFront,
      borderColor: wrong
          ? AppColors.wrong
          : matched
              ? AppColors.matched
              : AppColors.tileBackHighlight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortSide = math.min(constraints.maxWidth, constraints.maxHeight);
          // شارة دائرية ملوّنة خلف الرمز تجعله بارزًا وواضحًا وكبيرًا.
          final badgeSize = shortSide * 0.84;
          return Container(
            width: badgeSize,
            height: badgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: matched ? 0.35 : 0.22),
              border: Border.all(color: accentColor, width: 2.5),
            ),
            child: Text(emoji, style: TextStyle(fontSize: badgeSize * 0.55)),
          );
        },
      ),
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
