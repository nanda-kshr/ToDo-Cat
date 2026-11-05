import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_version_info.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppVersionInfo versionInfo;
  final VoidCallback onUpdate;
  final VoidCallback onRemindLater;

  const AppUpdateDialog({
    super.key,
    required this.versionInfo,
    required this.onUpdate,
    required this.onRemindLater,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogBg = palette.taskCardBg;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;
    final cardBorder = palette.cardBorder;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cardBorder, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFF4F4F5),
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBorder),
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    size: 20,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Update Available',
                        style: TextStyle(
                          fontFamily: 'Sniglet',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Version ${versionInfo.latestVersion}',
                        style: TextStyle(
                          fontFamily: 'Sniglet',
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'A new version of TodoCat is ready for you. Update now to get the latest features and fixes.',
              style: TextStyle(
                fontFamily: 'Sniglet',
                fontSize: 13,
                height: 1.4,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRemindLater,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Text(
                      'Remind Me Later',
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onUpdate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF18181B),
                      foregroundColor: isDark
                          ? const Color(0xFF18181B)
                          : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Update',
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF18181B) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
