import 'package:flutter/material.dart';

/// Central theme palette representing all visual tokens across TodoCat.
/// - Light Mode: Warm cream (#FDF2DD) with soft ivory/peachy cards (#F7E9DD), deep title/primary text (#2B1D16),
///   amber accents (#FFC65C), taupe beige paw prints (#B49A83), and soft warm shadows.
/// - Dark Mode: Carbon (#0E0E0E) with dark cards (#1A1A1A / #222222), crisp whitish text (#F5F5F5),
///   amber accents (#FFC65C), muted grey paw prints (#777777), and deep shadows.
class AppPalette {
  // Screen & Structural
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color taskCardBg;
  final Color cardBorder;
  final Color divider;
  final Color inputBg;
  final Color searchBg;
  final Color chipBg;
  final Color activeChip;
  final Color activeChipText;
  final Color bottomNavBg;

  // Typography
  final Color appTitle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Outlined Icons & System Accents
  final Color iconPrimary;
  final Color iconSecondary;
  final Color iconMuted;
  final Color accent;

  // Progress Bar & Badges
  final Color progressTrack;
  final Color progressFill;
  final Color priorityBadge;

  // Status (Completed / Pending)
  final Color completed;
  final Color completedBg;
  final Color completedBorder;

  final Color pending;
  final Color pendingBg;
  final Color pendingBorder;

  // Priority Tokens (High / Medium / Low)
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

  // Illustrations & Decorative Trails
  final Color pawAndTrail;
  final Color catBody;
  final Color catBlush;

  // Floating Action Button
  final Color fabBg;
  final Color fabIcon;

  // Shadow
  final Color softShadow;

  // Subtle Sage Accents (Stats visibility, public stats badges, globe indicator)
  final Color subtleGreen;
  final Color subtleGreenBg;
  final Color subtleGreenBorder;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.taskCardBg,
    required this.cardBorder,
    required this.divider,
    required this.inputBg,
    required this.searchBg,
    required this.chipBg,
    required this.activeChip,
    required this.activeChipText,
    required this.bottomNavBg,
    required this.appTitle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.iconMuted,
    required this.accent,
    required this.progressTrack,
    required this.progressFill,
    required this.priorityBadge,
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
    required this.pawAndTrail,
    required this.catBody,
    required this.catBlush,
    required this.fabBg,
    required this.fabIcon,
    required this.softShadow,
    required this.subtleGreen,
    required this.subtleGreenBg,
    required this.subtleGreenBorder,
  });
}

/// Central registry of TodoCat color palettes.
class AppColors {
  AppColors._();

  /// Light (Warm Cream) Theme Palette
  static const AppPalette light = AppPalette(
    // 2) Home screen background: #fdf2dd
    background: Color(0xFFFDF2DD),
    // 3) Cards: #f7e9dd
    surface: Color(0xFFF7E9DD),
    surfaceElevated: Color(0xFFF7E9DD),
    // Task items on home tab: Pure white #FFFFFF
    taskCardBg: Color(0xFFFFFFFF),
    // Borders: Warm beige #E8D9C2
    cardBorder: Color(0xFFE8D9C2),
    divider: Color(0xFFE8D9C2),
    // Search bar: Pale cream #F8EEDF
    inputBg: Color(0xFFF8EEDF),
    searchBg: Color(0xFFF8EEDF),
    // Inactive chips: Pure white #FFFFFF
    chipBg: Color(0xFFFFFFFF),
    // Selected status - All, Active, Completed: #413025 (Text: #FFF8E8)
    activeChip: Color(0xFF413025),
    activeChipText: Color(0xFFFFF8E8),
    // Bottom navigation: Pale cream #FFF8E8
    bottomNavBg: Color(0xFFFFF8E8),

    // 1) App Title: #2b1d16
    appTitle: Color(0xFF2B1D16),
    // Primary text: #2b1d16
    textPrimary: Color(0xFF2B1D16),
    // Secondary text: Muted warm brown #8A7867
    textSecondary: Color(0xFF8A7867),
    textMuted: Color(0xFF8A7867),

    iconPrimary: Color(0xFF2B1D16),
    iconSecondary: Color(0xFF8A7867),
    iconMuted: Color(0xFF8A7867),

    // Interactive & progress
    accent: Color(0xFFFFC65C),
    // Progress bar track: Pale beige #EADCC6
    progressTrack: Color(0xFFEADCC6),
    // Progress fill: Soft amber #FFC65C
    progressFill: Color(0xFFFFC65C),
    // Priority badge: Warm amber #FFC65C
    priorityBadge: Color(0xFFFFC65C),

    // Completed: Dark brown outline in light beige pill
    completed: Color(0xFF2B1D16),
    completedBg: Color(0xFFF4E8D3),
    completedBorder: Color(0xFFE8D9C2),

    // Pending: Muted warm brown outline in pale cream pill
    pending: Color(0xFF8A7867),
    pendingBg: Color(0xFFF8EEDF),
    pendingBorder: Color(0xFFE8D9C2),

    // Priority Tokens
    priorityHigh: Color(0xFFFFC65C),
    priorityHighBg: Color(0xFFFFF3D6),
    priorityHighBorder: Color(0xFFFFE099),

    priorityMedium: Color(0xFFFFC65C),
    priorityMediumBg: Color(0xFFFFF7E6),
    priorityMediumBorder: Color(0xFFFFE8B3),

    priorityLow: Color(0xFF8A7867),
    priorityLowBg: Color(0xFFF4E8D3),
    priorityLowBorder: Color(0xFFE8D9C2),

    // Shared badge
    sharedBadgeText: Color(0xFF2B1D16),
    sharedBadgeBg: Color(0xFFF4E8D3),
    sharedBadgeBorder: Color(0xFFE8D9C2),

    // Checkbox outline: Brown #6F5A48
    checkboxBorder: Color(0xFF6F5A48),
    checkboxCheckedBg: Color(0xFF2B1D16),
    checkboxCheckedIcon: Color(0xFFFFFFFF),

    // Calendar & recurrence: Dark brown & muted warm brown
    calendarIcon: Color(0xFF2B1D16),
    calendarText: Color(0xFF2B1D16),
    recurrenceIcon: Color(0xFF8A7867),
    recurrenceText: Color(0xFF8A7867),

    // Paw prints and trail: Taupe beige #B49A83
    pawAndTrail: Color(0xFFB49A83),
    catBody: Color(0xFF2B1D16),
    // Kitten blush: Soft pink #F4A6A0
    catBlush: Color(0xFFF4A6A0),

    // 4) Add task button: #f7e9dd (Symbol: #2b1d16)
    fabBg: Color(0xFFF7E9DD),
    fabIcon: Color(0xFF2B1D16),

    // Soft shadow: Warm grey-brown #8C7860 at low opacity
    softShadow: Color(0x248C7860),

    // Subtle Sage / Muted Cream Green
    subtleGreen: Color(0xFF476251),
    subtleGreenBg: Color(0xFFEDF3EE),
    subtleGreenBorder: Color(0xFFD8E4DC),
  );

  /// Dark Theme Palette
  static const AppPalette dark = AppPalette(
    // Background: #0E0E0E
    background: Color(0xFF0E0E0E),
    // Card: #1A1A1A, Card-elevated: #222222
    surface: Color(0xFF1A1A1A),
    surfaceElevated: Color(0xFF222222),
    taskCardBg: Color(0xFF1A1A1A),
    // Border: #353535
    cardBorder: Color(0xFF353535),
    divider: Color(0xFF353535),
    // Search-bg: #1C1C1C
    inputBg: Color(0xFF1C1C1C),
    searchBg: Color(0xFF1C1C1C),
    // Chip-bg: #242424
    chipBg: Color(0xFF242424),
    // Active-chip: #F5F5F5, Active-chip-text: #0E0E0E
    activeChip: Color(0xFFF5F5F5),
    activeChipText: Color(0xFF0E0E0E),
    // Nav-bg: #181818
    bottomNavBg: Color(0xFF181818),

    // App title
    appTitle: Color(0xFFF5F5F5),
    // Text-primary: #F5F5F5
    textPrimary: Color(0xFFF5F5F5),
    // Text-secondary: #A6A6A6
    textSecondary: Color(0xFFA6A6A6),
    textMuted: Color(0xFF777777),

    iconPrimary: Color(0xFFF5F5F5),
    iconSecondary: Color(0xFFA6A6A6),
    iconMuted: Color(0xFF777777),

    // Interactive & progress
    accent: Color(0xFFFFC65C),
    // Progress-track: #3A3A3A
    progressTrack: Color(0xFF3A3A3A),
    // Progress fill / accent: #FFC65C
    progressFill: Color(0xFFFFC65C),
    priorityBadge: Color(0xFFFFC65C),

    // Completed: Crisp pure white outline in dark chip pill
    completed: Color(0xFFF5F5F5),
    completedBg: Color(0xFF242424),
    completedBorder: Color(0xFF353535),

    // Pending: Soft silver outline in subtle dark pill
    pending: Color(0xFFA6A6A6),
    pendingBg: Color(0xFF1C1C1C),
    pendingBorder: Color(0xFF353535),

    // Priority Tokens
    priorityHigh: Color(0xFFFFC65C),
    priorityHighBg: Color(0xFF262013),
    priorityHighBorder: Color(0xFF4A3B18),

    priorityMedium: Color(0xFFFFC65C),
    priorityMediumBg: Color(0xFF201B10),
    priorityMediumBorder: Color(0xFF3B2F14),

    priorityLow: Color(0xFFA6A6A6),
    priorityLowBg: Color(0xFF1C1C1C),
    priorityLowBorder: Color(0xFF353535),

    // Shared badge
    sharedBadgeText: Color(0xFFF5F5F5),
    sharedBadgeBg: Color(0xFF242424),
    sharedBadgeBorder: Color(0xFF353535),

    // Checkbox
    checkboxBorder: Color(0xFF353535),
    checkboxCheckedBg: Color(0xFFF5F5F5),
    checkboxCheckedIcon: Color(0xFF0E0E0E),

    // Calendar & recurrence
    calendarIcon: Color(0xFFF5F5F5),
    calendarText: Color(0xFFF5F5F5),
    recurrenceIcon: Color(0xFFA6A6A6),
    recurrenceText: Color(0xFFA6A6A6),

    // Illustrations: Paw #777777, Cat-body #F5F5F5, Cat-blush #F4A6A0
    pawAndTrail: Color(0xFF777777),
    catBody: Color(0xFFF5F5F5),
    catBlush: Color(0xFFF4A6A0),

    // Floating action button: Fab-bg #F5F5F5, Fab-icon #0E0E0E
    fabBg: Color(0xFFF5F5F5),
    fabIcon: Color(0xFF0E0E0E),

    // Shadow: 0 4px 16px rgba(0, 0, 0, 0.25)
    softShadow: Color(0x40000000),

    // Subtle Whitish Green / Soft Sage
    subtleGreen: Color(0xFFD4E7DC),
    subtleGreenBg: Color(0xFF1B241F),
    subtleGreenBorder: Color(0xFF2C3B32),
  );

  /// Access the active palette based on the given context's brightness.
  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
