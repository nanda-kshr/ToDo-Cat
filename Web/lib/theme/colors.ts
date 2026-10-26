/**
 * Central theme palette for TodoCat Web application.
 * - Light Mode: Warm cream (#FDF2DD) with soft ivory/peachy cards (#F7E9DD), deep title/primary text (#2B1D16),
 *   amber accents (#FFC65C), taupe beige paw prints (#B49A83), and soft warm shadows.
 * - Dark Mode: Carbon (#0E0E0E) with dark cards (#1A1A1A / #222222), crisp whitish text (#F5F5F5),
 *   amber accents (#FFC65C), muted grey paw prints (#777777), and deep shadows.
 */

export interface ThemeColors {
  // Surfaces & Backgrounds
  background: string;
  surface: string;
  surfaceElevated: string;
  taskCardBg: string;
  cardBorder: string;
  divider: string;
  inputBg: string;
  searchBg: string;
  chipBg: string;
  activeChip: string;
  activeChipText: string;
  navBg: string;

  // Typography
  appTitle: string;
  textPrimary: string;
  textSecondary: string;
  textMuted: string;

  // Outlined Icons & System Accents
  iconPrimary: string;
  iconSecondary: string;
  iconMuted: string;
  accent: string;

  // Progress Bar & Badges
  progressTrack: string;
  progressFill: string;
  priorityBadge: string;

  // Status (Completed / Pending)
  completed: string;
  completedBg: string;
  completedBorder: string;

  pending: string;
  pendingBg: string;
  pendingBorder: string;

  // Priority Tokens (High / Medium / Low)
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

  // Illustrations & Decorative Trails
  pawAndTrail: string;
  catBody: string;
  catBlush: string;

  // Floating Action Button
  fabBg: string;
  fabIcon: string;

  // Shadow
  softShadow: string;

  // Subtle Sage Accents (Stats visibility, public stats badges, globe indicator)
  subtleGreen: string;
  subtleGreenBg: string;
  subtleGreenBorder: string;
}

export const lightColors: ThemeColors = {
  // 2) Home screen background: #fdf2dd
  background: "#FDF2DD",
  // 3) Cards: #f7e9dd
  surface: "#F7E9DD",
  surfaceElevated: "#F7E9DD",
  // Task items on home tab: Pure white #FFFFFF
  taskCardBg: "#FFFFFF",
  // Borders: Warm beige #E8D9C2
  cardBorder: "#E8D9C2",
  divider: "#E8D9C2",
  // Search bar: Pale cream #F8EEDF
  inputBg: "#F8EEDF",
  searchBg: "#F8EEDF",
  // Inactive chips: Pure white #FFFFFF
  chipBg: "#FFFFFF",
  // Selected status - All, Active, Completed: #413025 (Text: #FFF8E8)
  activeChip: "#413025",
  activeChipText: "#FFF8E8",
  // Bottom navigation: Pale cream #FFF8E8
  navBg: "#FFF8E8",

  // 1) App Title: #2b1d16
  appTitle: "#2B1D16",
  // Primary text: #2b1d16
  textPrimary: "#2B1D16",
  // Secondary text: Muted warm brown #8A7867
  textSecondary: "#8A7867",
  textMuted: "#8A7867",

  iconPrimary: "#2B1D16",
  iconSecondary: "#8A7867",
  iconMuted: "#8A7867",

  // Interactive & progress
  accent: "#FFC65C",
  progressTrack: "#EADCC6",
  progressFill: "#FFC65C",
  priorityBadge: "#FFC65C",

  // Completed: Dark brown outline in light beige pill
  completed: "#2B1D16",
  completedBg: "#F4E8D3",
  completedBorder: "#E8D9C2",

  // Pending: Muted warm brown outline in pale cream pill
  pending: "#8A7867",
  pendingBg: "#F8EEDF",
  pendingBorder: "#E8D9C2",

  // Priority Tokens
  priorityHigh: "#FFC65C",
  priorityHighBg: "#FFF3D6",
  priorityHighBorder: "#FFE099",

  priorityMedium: "#FFC65C",
  priorityMediumBg: "#FFF7E6",
  priorityMediumBorder: "#FFE8B3",

  priorityLow: "#8A7867",
  priorityLowBg: "#F4E8D3",
  priorityLowBorder: "#E8D9C2",

  // Shared badge
  sharedBadgeText: "#2B1D16",
  sharedBadgeBg: "#F4E8D3",
  sharedBadgeBorder: "#E8D9C2",

  // Checkbox outline: Brown #6F5A48
  checkboxBorder: "#6F5A48",
  checkboxCheckedBg: "#2B1D16",
  checkboxCheckedIcon: "#F7E9DD",

  // Paw prints and trail: Taupe beige #B49A83
  pawAndTrail: "#B49A83",
  catBody: "#2B1D16",
  catBlush: "#F4A6A0",

  // 4) Add task button: #f7e9dd (Symbol: #2b1d16)
  fabBg: "#F7E9DD",
  fabIcon: "#2B1D16",

  // Soft shadow: Warm grey-brown #8C7860 at low opacity
  softShadow: "0 4px 16px rgba(140, 120, 96, 0.15)",

  // Subtle Sage / Muted Cream Green
  subtleGreen: "#476251",
  subtleGreenBg: "#EDF3EE",
  subtleGreenBorder: "#D8E4DC",
};

export const darkColors: ThemeColors = {
  // Background: #0E0E0E
  background: "#0E0E0E",
  // Card: #1A1A1A, Card-elevated: #222222
  surface: "#1A1A1A",
  surfaceElevated: "#222222",
  taskCardBg: "#1A1A1A",
  // Border: #353535
  cardBorder: "#353535",
  divider: "#353535",
  // Search-bg: #1C1C1C
  inputBg: "#1C1C1C",
  searchBg: "#1C1C1C",
  // Chip-bg: #242424
  chipBg: "#242424",
  // Active-chip: #F5F5F5, Active-chip-text: #0E0E0E
  activeChip: "#F5F5F5",
  activeChipText: "#0E0E0E",
  // Nav-bg: #181818
  navBg: "#181818",

  // App title
  appTitle: "#F5F5F5",
  // Text-primary: #F5F5F5
  textPrimary: "#F5F5F5",
  // Text-secondary: #A6A6A6
  textSecondary: "#A6A6A6",
  textMuted: "#777777",

  iconPrimary: "#F5F5F5",
  iconSecondary: "#A6A6A6",
  iconMuted: "#777777",

  // Interactive & progress
  accent: "#FFC65C",
  progressTrack: "#3A3A3A",
  progressFill: "#FFC65C",
  priorityBadge: "#FFC65C",

  // Completed: Crisp pure white outline in dark chip pill
  completed: "#F5F5F5",
  completedBg: "#242424",
  completedBorder: "#353535",

  // Pending: Soft silver outline in subtle dark pill
  pending: "#A6A6A6",
  pendingBg: "#1C1C1C",
  pendingBorder: "#353535",

  // Priority Tokens
  priorityHigh: "#FFC65C",
  priorityHighBg: "#262013",
  priorityHighBorder: "#4A3B18",

  priorityMedium: "#FFC65C",
  priorityMediumBg: "#201B10",
  priorityMediumBorder: "#3B2F14",

  priorityLow: "#A6A6A6",
  priorityLowBg: "#1C1C1C",
  priorityLowBorder: "#353535",

  // Shared badge
  sharedBadgeText: "#F5F5F5",
  sharedBadgeBg: "#242424",
  sharedBadgeBorder: "#353535",

  // Checkbox
  checkboxBorder: "#353535",
  checkboxCheckedBg: "#F5F5F5",
  checkboxCheckedIcon: "#0E0E0E",

  // Illustrations: Paw #777777, Cat-body #F5F5F5, Cat-blush #F4A6A0
  pawAndTrail: "#777777",
  catBody: "#F5F5F5",
  catBlush: "#F4A6A0",

  // Floating action button: Fab-bg #F5F5F5, Fab-icon #0E0E0E
  fabBg: "#F5F5F5",
  fabIcon: "#0E0E0E",

  // Shadow: 0 4px 16px rgba(0, 0, 0, 0.25)
  softShadow: "0 4px 16px rgba(0, 0, 0, 0.25)",

  // Subtle Whitish Green / Soft Sage
  subtleGreen: "#D4E7DC",
  subtleGreenBg: "#1B241F",
  subtleGreenBorder: "#2C3B32",
};

export const AppColors = {
  light: lightColors,
  dark: darkColors,
};
