import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../models/analytics.dart';

class StatsTrendCard extends StatelessWidget {
  final List<CompletionTrendPoint> trends;

  const StatsTrendCard({
    super.key,
    required this.trends,
  });

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) return const SizedBox.shrink();

    final palette = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = palette.taskCardBg;
    final cardBorder = palette.cardBorder;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    final maxTrend = trends.map((t) => t.completed).reduce((a, b) => a > b ? a : b).clamp(1, 9999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Daily Completion Trend',
          style: TextStyle(
            fontFamily: 'Sniglet',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: trends
                .map((t) => _TrendBar(
                      point: t,
                      maxVal: maxTrend,
                      isDark: isDark,
                      textSecondary: textSecondary,
                      textPrimary: textPrimary,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _TrendBar extends StatelessWidget {
  final CompletionTrendPoint point;
  final int maxVal;
  final bool isDark;
  final Color textSecondary;
  final Color textPrimary;

  const _TrendBar({
    required this.point,
    required this.maxVal,
    required this.isDark,
    required this.textSecondary,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final parts = point.date.split('-');
    final label = parts.length >= 3 ? '${parts[1]}/${parts[2]}' : point.date;
    final compH = maxVal > 0 ? ((point.completed / maxVal) * 44).clamp(4.0, 44.0) : 4.0;
    final isDone = point.completed > 0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${point.completed}',
            style: TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 10,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
              color: isDone ? textPrimary : textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: compH,
            width: 14,
            decoration: BoxDecoration(
              color: isDone
                  ? (isDark ? Colors.white : const Color(0xFF4B5563))
                  : (isDark ? const Color(0xFF282828) : const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontFamily: 'Sniglet', fontSize: 10, color: textSecondary),
          ),
        ],
      ),
    );
  }
}
