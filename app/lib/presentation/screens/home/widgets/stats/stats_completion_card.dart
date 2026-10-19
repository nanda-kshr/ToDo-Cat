import 'package:flutter/material.dart';
import '../../../../../models/analytics.dart';

class StatsCompletionCard extends StatelessWidget {
  final AnalyticsSummary summary;

  const StatsCompletionCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171717) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA3A3A3) : const Color(0xFF9CA3AF);

    return Column(
      children: [
        // Hero Metric Card: Completion Rate
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Completion Rate',
                style: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.completionRate}%',
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (summary.total == 0 ? 0.0 : (summary.completed / summary.total)).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: isDark ? const Color(0xFF282828) : const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${summary.completed} completed',
                    style: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 12),
                  ),
                  Text(
                    '${summary.pending} pending',
                    style: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3 Metric Cards: Total, Done, Active
        Row(
          children: [
            _StatMetricCard(label: 'Total', value: '${summary.total}', cardBg: cardBg, cardBorder: cardBorder, textPrimary: textPrimary, textSecondary: textSecondary),
            const SizedBox(width: 8),
            _StatMetricCard(label: 'Done', value: '${summary.completed}', cardBg: cardBg, cardBorder: cardBorder, textPrimary: textPrimary, textSecondary: textSecondary),
            const SizedBox(width: 8),
            _StatMetricCard(label: 'Active', value: '${summary.pending}', cardBg: cardBg, cardBorder: cardBorder, textPrimary: textPrimary, textSecondary: textSecondary),
          ],
        ),
      ],
    );
  }
}

class _StatMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;

  const _StatMetricCard({
    required this.label,
    required this.value,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Sniglet',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Sniglet',
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
