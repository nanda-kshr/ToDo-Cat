import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/user.dart';
import '../../../../services/theme_service.dart';
import '../../about_screen.dart';
import '../../legal_screen.dart';

Future<void> showSettingsModal(
  BuildContext context, {
  required User? user,
  required bool isFloatingOverlayRunning,
  required Future<bool> Function() onToggleFloatingCat,
  required VoidCallback onShowWidgetChoice,
  required VoidCallback onLogout,
  required VoidCallback onThemeChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) {
      return _SettingsModalSheet(
        user: user,
        isFloatingOverlayRunning: isFloatingOverlayRunning,
        onToggleFloatingCat: onToggleFloatingCat,
        onShowWidgetChoice: onShowWidgetChoice,
        onLogout: onLogout,
        onThemeChanged: onThemeChanged,
      );
    },
  );
}

class _SettingsModalSheet extends StatefulWidget {
  final User? user;
  final bool isFloatingOverlayRunning;
  final Future<bool> Function() onToggleFloatingCat;
  final VoidCallback onShowWidgetChoice;
  final VoidCallback onLogout;
  final VoidCallback onThemeChanged;

  const _SettingsModalSheet({
    required this.user,
    required this.isFloatingOverlayRunning,
    required this.onToggleFloatingCat,
    required this.onShowWidgetChoice,
    required this.onLogout,
    required this.onThemeChanged,
  });

  @override
  State<_SettingsModalSheet> createState() => _SettingsModalSheetState();
}

class _SettingsModalSheetState extends State<_SettingsModalSheet> {
  late bool _localFloatingRunning;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _localFloatingRunning = widget.isFloatingOverlayRunning;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: ThemeService.instance.catColorVariant,
          builder: (context, currentCatVariant, _) {
            final isDark = ThemeService.instance.isDarkMode(context);
            final palette = isDark ? AppColors.dark : AppColors.light;
            final dialogBg = palette.surfaceElevated;
            final textPrimary = palette.textPrimary;
            final textSecondary = palette.textSecondary;
            final cardBg = palette.chipBg;
            final cardBorder = palette.cardBorder;
            final activeBorder = palette.textPrimary;

            return Container(
              decoration: BoxDecoration(
                color: dialogBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: cardBorder, width: 1),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 22, right: 22, top: 8, bottom: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF383838) : const Color(0xFFD4C8B8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

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
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardBg,
                                border: Border.all(color: cardBorder),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: textSecondary,
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
                              widget.onThemeChanged();
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
                              widget.onThemeChanged();
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
                              widget.onThemeChanged();
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
                              isDark
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
                              widget.onThemeChanged();
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
                              widget.onThemeChanged();
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
                              widget.onThemeChanged();
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
                            value: _localFloatingRunning,
                            activeTrackColor: palette.fabBg,
                            activeThumbColor: palette.fabIcon,
                            inactiveTrackColor: isDark ? const Color(0xFF2E2E2E) : palette.progressTrack,
                            onChanged: _isToggling
                                ? null
                                : (targetVal) async {
                                    setState(() {
                                      _localFloatingRunning = targetVal;
                                      _isToggling = true;
                                    });
                                    final actual = await widget.onToggleFloatingCat();
                                    if (mounted) {
                                      setState(() {
                                        _localFloatingRunning = actual;
                                        _isToggling = false;
                                      });
                                    }
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Extra field: Home Screen Widgets
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onShowWidgetChoice();
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
                      const SizedBox(height: 10),

                      // About TodoCat
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AboutScreen()),
                          );
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
                                child: Icon(Icons.info_outline, size: 20, color: textPrimary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'About TodoCat',
                                      style: TextStyle(
                                        fontFamily: 'Sniglet',
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Developer info & version',
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
                      const SizedBox(height: 10),

                      // Buy Me a Coffee
                      InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          final uri = Uri.parse('https://buymeacoffee.com/nanda_kshr');
                          try {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } catch (_) {}
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
                                  color: isDark ? const Color(0xFF261E0A) : const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.coffee_rounded, size: 20, color: Color(0xFFF59E0B)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Buy Me a Coffee',
                                      style: TextStyle(
                                        fontFamily: 'Sniglet',
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Support the developer',
                                      style: TextStyle(color: textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.favorite, color: Color(0xFFF59E0B), size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Privacy & Terms
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LegalScreen()),
                          );
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
                                child: Icon(Icons.policy_outlined, size: 20, color: textPrimary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Privacy & Terms',
                                      style: TextStyle(
                                        fontFamily: 'Sniglet',
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Privacy policy and terms of service',
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

                      if (widget.user != null) ...[
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
                                    widget.user!.name ?? widget.user!.email.split('@').first,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    widget.user!.email,
                                    style: TextStyle(color: textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onLogout();
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
            color: isSelected ? cardBg : cardBg.withValues(alpha: 0.5),
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
}
