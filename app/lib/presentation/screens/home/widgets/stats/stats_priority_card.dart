import 'package:flutter/material.dart';
import '../../../../../models/analytics.dart';

class StatsPriorityCard extends StatelessWidget {
  final Map<String, PriorityStats> byPriority;

  const StatsPriorityCard({
    super.key,
    required this.byPriority,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171717) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA3A3A3) : const Color(0xFF9CA3AF);

    final high = byPriority['high'] ?? PriorityStats(total: 0, completed: 0, pending: 0);
    final med = byPriority['medium'] ?? PriorityStats(total: 0, completed: 0, pending: 0);
    final low = byPriority['low'] ?? PriorityStats(total: 0, completed: 0, pending: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tasks by Priority',
          style: TextStyle(
            fontFamily: 'Sniglet',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              _PriorityStatRow(
                label: 'High Priority',
                count: '${high.total}',
                subtext: '${high.completed} done · ${high.pending} pending',
                dotColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              Divider(color: cardBorder, height: 20),
              _PriorityStatRow(
                label: 'Medium Priority',
                count: '${med.total}',
                subtext: '${med.completed} done · ${med.pending} pending',
                dotColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              Divider(color: cardBorder, height: 20),
              _PriorityStatRow(
                label: 'Low Priority',
                count: '${low.total}',
                subtext: '${low.completed} done · ${low.pending} pending',
                dotColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
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

class _PriorityStatRow extends StatelessWidget {
  final String label;
  final String count;
  final String subtext;
  final Color dotColor;
  final Color textPrimary;
  final Color textSecondary;

  const _PriorityStatRow({
    required this.label,
    required this.count,
    required this.subtext,
    required this.dotColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 14,
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtext,
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Text(
          count,
          style: TextStyle(
            fontFamily: 'Sniglet',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
