import 'package:flutter/material.dart';
import '../../../../models/user.dart';
import '../../../../services/theme_service.dart';

Future<void> showSettingsModal(
  BuildContext context, {
  required User? user,
  required bool isFloatingOverlayRunning,
  required Future<bool> Function() onToggleFloatingCat,
  required VoidCallback onShowWidgetChoice,
  required VoidCallback onLogout,
  required VoidCallback onThemeChanged,
}) {
  bool localFloatingRunning = isFloatingOverlayRunning;
  bool isToggling = false;

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dialogBg = isDark ? const Color(0xFF181818) : Colors.white;
  final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
  final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
  final cardBg = isDark ? const Color(0xFF222222) : const Color(0xFFF4F4F5);
  final cardBorder = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE4E4E7);
  final activeBorder = isDark ? Colors.white : const Color(0xFF4B5563);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: dialogBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final currentMode = ThemeService.instance.themeMode.value;
          final currentCatVariant = ThemeService.instance.catColorVariant.value;
          final isEffectiveDark = currentMode == ThemeMode.dark ||
              (currentMode == ThemeMode.system &&
                  MediaQuery.of(context).platformBrightness == Brightness.dark);

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 22, right: 22, top: 4, bottom: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: Title + Circular Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontFamily: 'Sniglet',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(ctx),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4E4E7),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: isDark ? Colors.white70 : const Color(0xFF52525B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Section 1: Theme Mode
                  Text(
                    'Theme Mode',
                    style: TextStyle(
                      fontFamily: 'Sniglet',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // System
                      _buildSettingOptionCard(
                        label: 'System',
                        iconWidget: Icon(
                          Icons.brightness_auto_outlined,
                          size: 26,
                          color: currentMode == ThemeMode.system
                              ? textPrimary
                              : textSecondary,
                        ),
                        isSelected: currentMode == ThemeMode.system,
                        onTap: () async {
                          await ThemeService.instance.setThemeMode(ThemeMode.system);
                          setDialogState(() {});
                          onThemeChanged();
                        },
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        activeBorder: activeBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(width: 8),
                      // Light
                      _buildSettingOptionCard(
                        label: 'Light',
                        iconWidget: Icon(
                          Icons.wb_sunny_outlined,
                          size: 26,
                          color: currentMode == ThemeMode.light
                              ? textPrimary
                              : textSecondary,
                        ),
                        isSelected: currentMode == ThemeMode.light,
                        onTap: () async {
                          await ThemeService.instance.setThemeMode(ThemeMode.light);
                          setDialogState(() {});
                          onThemeChanged();
                        },
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        activeBorder: activeBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(width: 8),
                      // Dark
                      _buildSettingOptionCard(
                        label: 'Dark',
                        iconWidget: Icon(
                          Icons.nightlight_round,
                          size: 26,
                          color: currentMode == ThemeMode.dark
                              ? textPrimary
                              : textSecondary,
                        ),
                        isSelected: currentMode == ThemeMode.dark,
                        onTap: () async {
                          await ThemeService.instance.setThemeMode(ThemeMode.dark);
                          setDialogState(() {});
                          onThemeChanged();
                        },
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        activeBorder: activeBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Section 2: Cat Color
                  Text(
                    'Cat Color',
                    style: TextStyle(
                      fontFamily: 'Sniglet',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Auto
                      _buildSettingOptionCard(
                        label: 'Auto',
                        iconWidget: Image.asset(
                          isEffectiveDark
                              ? 'assets/runners/cat_white/cat_0.png'
                              : 'assets/runners/cat/cat_0.png',
                          width: 32,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 24),
                        ),
                        isSelected: currentCatVariant == 'auto',
                        onTap: () async {
                          await ThemeService.instance.setCatColorVariant('auto');
                          setDialogState(() {});
                          onThemeChanged();
                        },
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        activeBorder: activeBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(width: 8),
                      // Black
                      _buildSettingOptionCard(
                        label: 'Black',
                        iconWidget: Image.asset(
                          'assets/runners/cat/cat_0.png',
                          width: 32,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 24),
                        ),
                        isSelected: currentCatVariant == 'black',
                        onTap: () async {
                          await ThemeService.instance.setCatColorVariant('black');
                          setDialogState(() {});
                          onThemeChanged();
                        },
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        activeBorder: activeBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(width: 8),
                      // White
                      _buildSettingOptionCard(
                        label: 'White',
                        iconWidget: Image.asset(
                          'assets/runners/cat_white/cat_0.png',
                          width: 32,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 24),
                        ),
                        isSelected: currentCatVariant == 'white',
                        onTap: () async {
                          await ThemeService.instance.setCatColorVariant('white');
                          setDialogState(() {});
                          onThemeChanged();
                        },
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        activeBorder: activeBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section 3: Floating Cat Overlay Switch Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Floating Cat Overlay',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Show a running cat on top of other apps',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: localFloatingRunning,
                        activeTrackColor: isDark ? Colors.white : const Color(0xFF4B5563),
                        activeThumbColor: isDark ? Colors.black : Colors.white,
                        inactiveTrackColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE4E4E7),
                        onChanged: isToggling
                            ? null
                            : (targetVal) async {
                                setDialogState(() {
                                  localFloatingRunning = targetVal;
                                  isToggling = true;
                                });
                                final actual = await onToggleFloatingCat();
                                setDialogState(() {
                                  localFloatingRunning = actual;
                                  isToggling = false;
                                });
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Extra field: Home Screen Widgets
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      onShowWidgetChoice();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4E4E7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.widgets_outlined, size: 20, color: textPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Home Screen Widgets',
                                  style: TextStyle(
                                    fontFamily: 'Sniglet',
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Setup quick tasks and running cat widgets',
                                  style: TextStyle(color: textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: textSecondary, size: 20),
                        ],
                      ),
                    ),
                  ),

                  if (user != null) ...[
                    const SizedBox(height: 16),
                    Divider(color: cardBorder),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name ?? user.email.split('@').first,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                user.email,
                                style: TextStyle(color: textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onLogout();
                          },
                          icon: const Icon(Icons.logout, size: 16, color: Color(0xFFEF4444)),
                          label: const Text(
                            'Sign Out',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildSettingOptionCard({
  required String label,
  required Widget iconWidget,
  required bool isSelected,
  required VoidCallback onTap,
  required Color cardBg,
  required Color cardBorder,
  required Color activeBorder,
  required Color textPrimary,
  required Color textSecondary,
}) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? cardBg : cardBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeBorder : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Sniglet',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? textPrimary : textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
