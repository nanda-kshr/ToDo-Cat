import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class StatsPeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String period) onPeriodChanged;

  const StatsPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = palette.taskCardBg;
    final cardBorder = palette.cardBorder;
    final textSecondary = palette.textSecondary;

    const periods = [
      ('today', 'Today'),
      ('7d', '7 Days'),
      ('30d', '30 Days'),
      ('this_month', 'Month'),
    ];

    return Row(
      children: periods.map((p) {
        final periodKey = p.$1;
        final label = p.$2;
        final isSelected = selectedPeriod == periodKey;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () {
                if (selectedPeriod != periodKey) {
                  onPeriodChanged(periodKey);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF4B5563))
                      : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : cardBorder,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
