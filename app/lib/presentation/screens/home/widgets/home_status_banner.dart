import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/cat_animation.dart';

class HomeStatusBanner extends StatelessWidget {
  final int catSpeed;
  final int activeCount;
  final int completedTodayCount;
  final int todayTotalCount;
  final int completionPercent;

  const HomeStatusBanner({
    super.key,
    required this.catSpeed,
    required this.activeCount,
    required this.completedTodayCount,
    required this.todayTotalCount,
    required this.completionPercent,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final cardBg = palette.surface;
    final cardBorder = palette.cardBorder;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    final progress = (todayTotalCount == 0
            ? 0.0
            : (completedTodayCount / todayTotalCount))
        .clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          RepaintBoundary(
            child: CatAnimation(
              speedPercent: catSpeed,
              size: 88,
              showContainer: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$activeCount Active Tasks',
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$completionPercent%',
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: palette.progressTrack,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.progressFill),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedTodayCount done today · $activeCount remaining',
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
