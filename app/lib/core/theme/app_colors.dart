import 'package:flutter/material.dart';

/// Central theme palette representing all visual tokens across TodoCat.
/// When adding a new color token, add it here and specify values for both
/// [AppColors.light] (white theme) and [AppColors.dark] (dark theme).
class AppPalette {
  // Screen & Structural
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color cardBorder;
  final Color divider;
  final Color inputBg;

  // Typography
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Outlined Icons & System Accents
  final Color iconPrimary;
  final Color iconSecondary;
  final Color iconMuted;

  // Status (Completed / Pending) - Used for SVG icons and indicator pills
  final Color completed;
  final Color completedBg;
  final Color completedBorder;

  final Color pending;
  final Color pendingBg;
  final Color pendingBorder;

  // Priority Tokens (High / Medium / Low) - Used for SVG outlined art & pill backgrounds
  final Color priorityHigh;
  final Color priorityHighBg;
  final Color priorityHighBorder;

  final Color priorityMedium;
  final Color priorityMediumBg;
  final Color priorityMediumBorder;

  final Color priorityLow;
  final Color priorityLowBg;
  final Color priorityLowBorder;

  // Shared Task Indicators
  final Color sharedBadgeText;
  final Color sharedBadgeBg;
  final Color sharedBadgeBorder;

  // Checkbox Controls
  final Color checkboxBorder;
  final Color checkboxCheckedBg;
  final Color checkboxCheckedIcon;

  // Calendar / Due Date / Recurrence
  final Color calendarIcon;
  final Color calendarText;
  final Color recurrenceIcon;
  final Color recurrenceText;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.cardBorder,
    required this.divider,
    required this.inputBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.iconMuted,
    required this.completed,
    required this.completedBg,
    required this.completedBorder,
    required this.pending,
    required this.pendingBg,
    required this.pendingBorder,
    required this.priorityHigh,
    required this.priorityHighBg,
    required this.priorityHighBorder,
    required this.priorityMedium,
    required this.priorityMediumBg,
    required this.priorityMediumBorder,
    required this.priorityLow,
    required this.priorityLowBg,
    required this.priorityLowBorder,
    required this.sharedBadgeText,
    required this.sharedBadgeBg,
    required this.sharedBadgeBorder,
    required this.checkboxBorder,
    required this.checkboxCheckedBg,
    required this.checkboxCheckedIcon,
    required this.calendarIcon,
    required this.calendarText,
    required this.recurrenceIcon,
    required this.recurrenceText,
  });
}

/// Central registry of TodoCat color palettes.
class AppColors {
  AppColors._();

  /// Light (White) Theme Palette
  static const AppPalette light = AppPalette(
    background: Color(0xFFF9FAFB),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE5E7EB),
    divider: Color(0xFFE5E7EB),
    inputBg: Color(0xFFF3F4F6),

    textPrimary: Color(0xFF18181B),
    textSecondary: Color(0xFF71717A),
    textMuted: Color(0xFF9CA3AF),

    iconPrimary: Color(0xFF18181B),
    iconSecondary: Color(0xFF71717A),
    iconMuted: Color(0xFFA1A1AA),

    // Completed: Outlined clean emerald
    completed: Color(0xFF059669),
    completedBg: Color(0xFFECFDF5),
    completedBorder: Color(0xFFD1FAE5),

    // Pending: Outlined subtle slate-indigo
    pending: Color(0xFF6366F1),
    pendingBg: Color(0xFFEEF2FF),
    pendingBorder: Color(0xFFE0E7FF),

    // High Priority: Outlined coral flame
    priorityHigh: Color(0xFFE11D48),
    priorityHighBg: Color(0xFFFFF1F2),
    priorityHighBorder: Color(0xFFFFE4E6),

    // Medium Priority: Outlined warm amber balance
    priorityMedium: Color(0xFFD97706),
    priorityMediumBg: Color(0xFFFFFBEB),
    priorityMediumBorder: Color(0xFFFEF3C7),

    // Low Priority: Outlined calm teal / slate
    priorityLow: Color(0xFF0D9488),
    priorityLowBg: Color(0xFFF0FDFA),
    priorityLowBorder: Color(0xFFCCFBF1),

    // Shared badge
    sharedBadgeText: Color(0xFF4B5563),
    sharedBadgeBg: Color(0xFFF3F4F6),
    sharedBadgeBorder: Color(0xFFE5E7EB),

    // Checkbox
    checkboxBorder: Color(0xFFD4D4D8),
    checkboxCheckedBg: Color(0xFF18181B),
    checkboxCheckedIcon: Color(0xFFFFFFFF),

    // Calendar & recurrence
    calendarIcon: Color(0xFFE11D48),
    calendarText: Color(0xFFE11D48),
    recurrenceIcon: Color(0xFF71717A),
    recurrenceText: Color(0xFF71717A),
  );

  /// Dark Theme Palette
  static const AppPalette dark = AppPalette(
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF161616),
    surfaceElevated: Color(0xFF1C1C1C),
    cardBorder: Color(0xFF262626),
    divider: Color(0xFF262626),
    inputBg: Color(0xFF202020),

    textPrimary: Color(0xFFF4F4F5),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF71717A),

    iconPrimary: Color(0xFFF4F4F5),
    iconSecondary: Color(0xFFA1A1AA),
    iconMuted: Color(0xFF52525B),

    // Completed: Outlined luminous emerald
    completed: Color(0xFF34D399),
    completedBg: Color(0xFF0A2216),
    completedBorder: Color(0xFF144D32),

    // Pending: Outlined soft indigo
    pending: Color(0xFF818CF8),
    pendingBg: Color(0xFF14162B),
    pendingBorder: Color(0xFF242750),

    // High Priority: Outlined luminous rose flame
    priorityHigh: Color(0xFFFB7185),
    priorityHighBg: Color(0xFF2E1216),
    priorityHighBorder: Color(0xFF4E1D25),

    // Medium Priority: Outlined warm amber balance
    priorityMedium: Color(0xFFFBBF24),
    priorityMediumBg: Color(0xFF271C08),
    priorityMediumBorder: Color(0xFF4B340B),

    // Low Priority: Outlined soft teal
    priorityLow: Color(0xFF2DD4BF),
    priorityLowBg: Color(0xFF0B2423),
    priorityLowBorder: Color(0xFF154844),

    // Shared badge
    sharedBadgeText: Color(0xFFD4D4D8),
    sharedBadgeBg: Color(0xFF27272A),
    sharedBadgeBorder: Color(0xFF3F3F46),

    // Checkbox
    checkboxBorder: Color(0xFF3F3F46),
    checkboxCheckedBg: Color(0xFFFFFFFF),
    checkboxCheckedIcon: Color(0xFF0A0A0A),

    // Calendar & recurrence
    calendarIcon: Color(0xFFFB7185),
    calendarText: Color(0xFFFB7185),
    recurrenceIcon: Color(0xFFA1A1AA),
    recurrenceText: Color(0xFFA1A1AA),
  );

  /// Access the active palette based on the given context's brightness.
  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
