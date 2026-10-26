/**
 * Central theme palette for TodoCat Web application.
 * - In Dark mode: Crisp whitish tones on carbon background (no glowing yellow/green/red).
 * - In White mode: Warm, soothing cream tones with rich espresso/charcoal accents (no glowing yellow/green/red).
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

  // Subtle Whitish Green / Sage Accents (Stats visibility, public stats badges, globe indicator)
  subtleGreen: string;
  subtleGreenBg: string;
  subtleGreenBorder: string;
}

export const lightColors: ThemeColors = {
  background: "#FAF8F5",
  surface: "#FFFDFB",
  surfaceElevated: "#FFFDFB",
  cardBorder: "#E8E2D8",
  divider: "#E8E2D8",
  inputBg: "#F3EFE8",

  textPrimary: "#292524",
  textSecondary: "#78716C",
  textMuted: "#A8A29E",

  iconPrimary: "#292524",
  iconSecondary: "#78716C",
  iconMuted: "#A8A29E",

  // Completed: Warm charcoal outline in soft cream pill
  completed: "#292524",
  completedBg: "#EFEBE2",
  completedBorder: "#DDD7CB",

  // Pending: Warm stone outline in pale cream pill
  pending: "#78716C",
  pendingBg: "#F7F4EE",
  pendingBorder: "#EAE5DC",

  // High Priority: Deep charcoal outline in warm cream pill
  priorityHigh: "#1C1917",
  priorityHighBg: "#EAE4D8",
  priorityHighBorder: "#DCD4C5",

  // Medium Priority: Warm stone outline in soft cream pill
  priorityMedium: "#57534E",
  priorityMediumBg: "#F4F0E6",
  priorityMediumBorder: "#E6E0D4",

  // Low Priority: Soft stone outline in pale cream pill
  priorityLow: "#78716C",
  priorityLowBg: "#FAF7F2",
  priorityLowBorder: "#EBE6DC",

  // Shared badge
  sharedBadgeText: "#44403C",
  sharedBadgeBg: "#F4F0E8",
  sharedBadgeBorder: "#E6DFD4",

  // Checkbox
  checkboxBorder: "#D6CEC2",
  checkboxCheckedBg: "#292524",
  checkboxCheckedIcon: "#FAF8F5",

  // Subtle Sage / Muted Cream Green (Public stats, globe indicator, visibility switch)
  subtleGreen: "#476251",
  subtleGreenBg: "#EDF3EE",
  subtleGreenBorder: "#D8E4DC",
};

export const darkColors: ThemeColors = {
  background: "#0A0A0A",
  surface: "#141414",
  surfaceElevated: "#1A1A1A",
  cardBorder: "#262626",
  divider: "#262626",
  inputBg: "#1F1F1F",

  textPrimary: "#F4F4F5",
  textSecondary: "#A1A1AA",
  textMuted: "#71717A",

  iconPrimary: "#FFFFFF",
  iconSecondary: "#A1A1AA",
  iconMuted: "#52525B",

  // Completed: Crisp pure white outline in dark whitish pill
  completed: "#FFFFFF",
  completedBg: "#242424",
  completedBorder: "#404040",

  // Pending: Soft whitish silver outline in subtle dark pill
  pending: "#A1A1AA",
  pendingBg: "#1C1C1C",
  pendingBorder: "#333333",

  // High Priority: Crisp white outline in stylish whitish pill
  priorityHigh: "#FFFFFF",
  priorityHighBg: "#282828",
  priorityHighBorder: "#525252",

  // Medium Priority: Soft off-white outline in subtle pill
  priorityMedium: "#E4E4E7",
  priorityMediumBg: "#202020",
  priorityMediumBorder: "#3F3F46",

  // Low Priority: Muted whitish outline in dark pill
  priorityLow: "#A1A1AA",
  priorityLowBg: "#181818",
  priorityLowBorder: "#2E2E2E",

  // Shared badge
  sharedBadgeText: "#E4E4E7",
  sharedBadgeBg: "#202020",
  sharedBadgeBorder: "#383838",

  // Checkbox
  checkboxBorder: "#3F3F46",
  checkboxCheckedBg: "#FFFFFF",
  checkboxCheckedIcon: "#0A0A0A",

  // Subtle Whitish Green / Soft Sage (Public stats, globe indicator, visibility switch)
  subtleGreen: "#D4E7DC",
  subtleGreenBg: "#1B241F",
  subtleGreenBorder: "#2C3B32",
};

export const AppColors = {
  light: lightColors,
  dark: darkColors,
};
