import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

void showWidgetChoiceDialog(
  BuildContext context, {
  required ValueChanged<bool> onSelectWidget,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final palette = AppColors.of(context);
  final cardBg = palette.surfaceElevated;
  final textPrimary = palette.textPrimary;
  final textSecondary = palette.textSecondary;

  showModalBottomSheet(
    context: context,
    backgroundColor: cardBg,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Widget',
              style: TextStyle(
                fontFamily: 'Sniglet',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262626) : palette.chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.checklist, color: textPrimary, size: 22),
              ),
              title: Text(
                'TodoCat Tasks',
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Scrollable tasks list with quick add button',
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onSelectWidget(false);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262626) : palette.chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.pets, color: textPrimary, size: 22),
              ),
              title: Text(
                'TodoCat Running Cat',
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Square animated companion with velocity and counts',
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onSelectWidget(true);
              },
            ),
          ],
        ),
      );
    },
  );
}
