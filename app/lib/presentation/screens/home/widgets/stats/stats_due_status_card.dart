import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../models/analytics.dart';

class StatsDueStatusCard extends StatelessWidget {
  final DueStatus due;

  const StatsDueStatusCard({
    super.key,
    required this.due,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = palette.taskCardBg;
    final cardBorder = palette.cardBorder;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Due Status',
          style: TextStyle(
            fontFamily: 'Sniglet',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              _DueStatusItem(
                label: 'Overdue',
                count: due.overdue,
                color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _DueStatusItem(
                label: 'Due Today',
                count: due.dueToday,
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _DueStatusItem(
                label: 'Upcoming',
                count: due.upcoming,
                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _DueStatusItem(
                label: 'No Due Date',
                count: due.noDueDate,
                color: textSecondary,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DueStatusItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color textPrimary;
  final Color textSecondary;

  const _DueStatusItem({
    required this.label,
    required this.count,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: count > 0 ? color : textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 11,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
