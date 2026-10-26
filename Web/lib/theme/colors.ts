/**
 * Central theme palette for TodoCat Web application.
 * All element colors, SVGs, texts, and badges are configured here for both
 * light (white theme) and dark themes.
 */

export interface ThemeColors {
  // Surfaces & Backgrounds
  background: string;
  surface: string;
  surfaceElevated: string;
  cardBorder: string;
  divider: string;
  inputBg: string;

  // Typography
  textPrimary: string;
  textSecondary: string;
  textMuted: string;

  // Outlined Icons & System Accents
  iconPrimary: string;
  iconSecondary: string;
  iconMuted: string;

  // Status (Completed / Pending) - SVG icons & subtle badge backgrounds
  completed: string;
  completedBg: string;
  completedBorder: string;

  pending: string;
  pendingBg: string;
  pendingBorder: string;

  // Priority Tokens (High / Medium / Low) - Outlined SVG art & pill backgrounds
  priorityHigh: string;
  priorityHighBg: string;
  priorityHighBorder: string;

  priorityMedium: string;
  priorityMediumBg: string;
  priorityMediumBorder: string;

  priorityLow: string;
  priorityLowBg: string;
  priorityLowBorder: string;

  // Shared Task Indicators
  sharedBadgeText: string;
  sharedBadgeBg: string;
  sharedBadgeBorder: string;

  // Checkbox Controls
  checkboxBorder: string;
  checkboxCheckedBg: string;
  checkboxCheckedIcon: string;
}

export const lightColors: ThemeColors = {
  background: "#F9FAFB",
  surface: "#FFFFFF",
  surfaceElevated: "#FFFFFF",
  cardBorder: "#E5E7EB",
  divider: "#E5E7EB",
  inputBg: "#F3F4F6",

  textPrimary: "#18181B",
  textSecondary: "#71717A",
  textMuted: "#9CA3AF",

  iconPrimary: "#18181B",
  iconSecondary: "#71717A",
  iconMuted: "#A1A1AA",

  // Completed: Outlined clean emerald
  completed: "#059669",
  completedBg: "#ECFDF5",
  completedBorder: "#D1FAE5",

  // Pending: Outlined subtle slate-indigo
  pending: "#6366F1",
  pendingBg: "#EEF2FF",
  pendingBorder: "#E0E7FF",

  // High Priority: Outlined coral flame
  priorityHigh: "#E11D48",
  priorityHighBg: "#FFF1F2",
  priorityHighBorder: "#FFE4E6",

  // Medium Priority: Outlined warm amber balance
  priorityMedium: "#D97706",
  priorityMediumBg: "#FFFBEB",
  priorityMediumBorder: "#FEF3C7",

  // Low Priority: Outlined calm teal / slate
  priorityLow: "#0D9488",
  priorityLowBg: "#F0FDFA",
  priorityLowBorder: "#CCFBF1",

  // Shared badge
  sharedBadgeText: "#4B5563",
  sharedBadgeBg: "#F3F4F6",
  sharedBadgeBorder: "#E5E7EB",

  // Checkbox
  checkboxBorder: "#D4D4D8",
  checkboxCheckedBg: "#18181B",
  checkboxCheckedIcon: "#FFFFFF",
};

export const darkColors: ThemeColors = {
  background: "#0A0A0A",
  surface: "#161616",
  surfaceElevated: "#1C1C1C",
  cardBorder: "#262626",
  divider: "#262626",
  inputBg: "#202020",

  textPrimary: "#F4F4F5",
  textSecondary: "#A1A1AA",
  textMuted: "#71717A",

  iconPrimary: "#F4F4F5",
  iconSecondary: "#A1A1AA",
  iconMuted: "#52525B",

  // Completed: Outlined luminous emerald
  completed: "#34D399",
  completedBg: "#0A2216",
  completedBorder: "#144D32",

  // Pending: Outlined soft indigo
  pending: "#818CF8",
  pendingBg: "#14162B",
  pendingBorder: "#242750",

  // High Priority: Outlined luminous rose flame
  priorityHigh: "#FB7185",
  priorityHighBg: "#2E1216",
  priorityHighBorder: "#4E1D25",

  // Medium Priority: Outlined warm amber balance
  priorityMedium: "#FBBF24",
  priorityMediumBg: "#271C08",
  priorityMediumBorder: "#4B340B",

  // Low Priority: Outlined soft teal
  priorityLow: "#2DD4BF",
  priorityLowBg: "#0B2423",
  priorityLowBorder: "#154844",

  // Shared badge
  sharedBadgeText: "#D4D4D8",
  sharedBadgeBg: "#27272A",
  sharedBadgeBorder: "#3F3F46",

  // Checkbox
  checkboxBorder: "#3F3F46",
  checkboxCheckedBg: "#FFFFFF",
  checkboxCheckedIcon: "#0A0A0A",
};

export const AppColors = {
  light: lightColors,
  dark: darkColors,
};
