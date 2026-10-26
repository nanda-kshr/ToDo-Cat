import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../models/analytics.dart';
import '../../../../widgets/app_outlined_icons.dart';

class StatsPriorityCard extends StatelessWidget {
  final Map<String, PriorityStats> byPriority;

  const StatsPriorityCard({
    super.key,
    required this.byPriority,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

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
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Column(
            children: [
              _PriorityStatRow(
                label: 'High Priority',
                count: '${high.total}',
                subtext: '${high.completed} done · ${high.pending} pending',
                svgString: AppOutlinedSvgStrings.priorityHigh,
                iconColor: palette.priorityHigh,
                bgColor: palette.priorityHighBg,
                borderColor: palette.priorityHighBorder,
                textPrimary: palette.textPrimary,
                textSecondary: palette.textSecondary,
              ),
              Divider(color: palette.cardBorder, height: 20),
              _PriorityStatRow(
                label: 'Medium Priority',
                count: '${med.total}',
                subtext: '${med.completed} done · ${med.pending} pending',
                svgString: AppOutlinedSvgStrings.priorityMedium,
                iconColor: palette.priorityMedium,
                bgColor: palette.priorityMediumBg,
                borderColor: palette.priorityMediumBorder,
                textPrimary: palette.textPrimary,
                textSecondary: palette.textSecondary,
              ),
              Divider(color: palette.cardBorder, height: 20),
              _PriorityStatRow(
                label: 'Low Priority',
                count: '${low.total}',
                subtext: '${low.completed} done · ${low.pending} pending',
                svgString: AppOutlinedSvgStrings.priorityLow,
                iconColor: palette.priorityLow,
                bgColor: palette.priorityLowBg,
                borderColor: palette.priorityLowBorder,
                textPrimary: palette.textPrimary,
                textSecondary: palette.textSecondary,
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
  final String svgString;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const _PriorityStatRow({
    required this.label,
    required this.count,
    required this.subtext,
    required this.svgString,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
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
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: AppOutlinedIcon(
                svgString: svgString,
                size: 13,
                color: iconColor,
              ),
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
