---
type: Feature
title: Theming & Visual Design
description: Playful Sniglet-based typography, centralized paired theme palettes for light/dark modes, custom outlined SVG art, and procedural background trails.
tags: [theme, typography, dark-mode, styling, procedural-background, outlined-svg, color-system]
status: active
last_updated: 2026-10-26
---

# Theming & Visual Design

## Overview
TodoCat features a cohesive, playful design aesthetic built around the `Sniglet` rounded font and a centralized color system:
- **Theme Modes**: Supports Light (white theme), Dark, and System auto-detection.
- **Centralized Paired Color Palette**:
  - All element colors (surfaces, backgrounds, texts, borders, icons, status badges, priority levels) are maintained in a single common place.
  - **Light Mode Palette**:
    - App Title: Deep warm charcoal-brown `#2B1D16`
    - Main screen background: Pale warm cream `#FDF2DD`
    - Cards: Soft ivory/peachy cream `#F7E9DD`
    - Task items (Home tab): Pure white `#FFFFFF`
    - Selected status (All, Active, Completed): `#413025` (Text: `#FFF8E8`)
    - Home status banner (Active tasks, %, progress): `#F7E9DD`
    - Add task button / FAB: `#F7E9DD` (Symbol: `#2B1D16`)
    - Primary text: Deep warm charcoal-brown `#2B1D16`
    - Secondary text: Muted warm brown `#8A7867`
    - Borders: Warm beige `#E8D9C2`
    - Search bar: Pale cream `#F8EEDF`
    - Inactive chips: Pure white `#FFFFFF`
    - Progress bar track: Pale beige `#EADCC6` (Fill: Soft amber `#FFC65C`)
    - Priority badge / Accent: Warm amber `#FFC65C`
    - Checkbox outline: Brown `#6F5A48`
    - Paw prints & trail: Taupe beige `#B49A83`
    - Kitten blush: Soft pink `#F4A6A0`
    - Bottom navigation: Pale cream `#FFF8E8`
    - Soft shadow: Warm grey-brown `#8C7860` at low opacity
  - **Dark Mode Palette**:
    - Main screen background (`--bg`): `#0E0E0E`
    - Cards (`--card`): `#1A1A1A` (`--card-elevated`: `#222222`)
    - Search bar (`--search-bg`): `#1C1C1C`
    - Inactive chips (`--chip-bg`): `#242424`
    - Bottom navigation (`--nav-bg`): `#181818`
    - Primary text (`--text-primary`): `#F5F5F5`
    - Secondary text (`--text-secondary`): `#A6A6A6`
    - Borders (`--border`): `#353535`
    - Soft shadow (`--shadow`): `0 4px 16px rgba(0, 0, 0, 0.25)`
    - Accent / Priority badge / Progress fill (`--accent`): `#FFC65C`
    - Progress bar track (`--progress-track`): `#3A3A3A`
    - Active chip (`--active-chip`): `#F5F5F5` (`--active-chip-text`: `#0E0E0E`)
    - Paw prints & trail (`--paw`): `#777777`
    - Cat body (`--cat-body`): `#F5F5F5`, Kitten blush (`--cat-blush`): `#F4A6A0`
    - Floating action button (`--fab-bg`): `#F5F5F5` (`--fab-icon`: `#0E0E0E`)
  - **Subtle Whitish Green / Sage Tokens**: `subtleGreen`, `subtleGreenBg`, and `subtleGreenBorder` for public stats indicators, stats visibility switch, friend public badges, and globe icons (Dark: whitish sage `#D4E7DC` on deep dark sage `#1B241F`; Light: muted earthy sage `#476251` on cream sage `#EDF3EE`), completely replacing bright/light emerald greens.
  - Adding any new color token requires defining both light and dark palette values simultaneously, ensuring complete theme parity.
  - Mobile: `app/lib/core/theme/app_colors.dart` (`AppPalette`, `AppColors.light`, `AppColors.dark`).
  - Web: `Web/lib/theme/colors.ts` (`ThemeColors`, `AppColors.light`, `AppColors.dark`).
- **Dedicated SVG Asset Directory**:
  - All SVG graphics and icons are organized as standalone `.svg` files under `app/assets/svg/` rather than embedded inline in code files.
  - Assets include navigation icons (`home_*.svg`, `friends_*.svg`, `profile_*.svg`), status/action indicators (`completed.svg`, `pending.svg`, `priority_*.svg`, `calendar.svg`, `recurrence.svg`, `tick.svg`, `cross.svg`), and decorative assets (`paw.svg`).
  - `paw.svg` can be swapped or customized directly in the asset folder without touching code.
- **Hand-Crafted Outlined SVG Icons**:
  - All icons are styled with consistent 2.2px rounded outline strokes (no generic AI icons or harsh solid fills).
  - Status Indicators (Completed, Pending): Rendered as pure outlined SVG icons without text.
  - Priority Badges (High, Medium, Low): Rendered as pure outlined SVG art (High: stylized flame; Medium: balanced dual bars; Low: calm chevron) without text.
  - Shared Collaboration Badge: Outlined people icon with concise `x/y done` text.
- **Floating Pill Dock Navbar**: Recreated from visual reference as a floating rounded capsule dock (`borderRadius: 30`) with a frosted glassmorphism background (`BackdropFilter` with `sigma: 20`, translucent tint, and subtle rim border), hosting primary navigation in order (**Friends**, **Home**, **Profile**). Content and cat trail scroll continuously beneath the blurred glass dock without clipping.
  - Selected tab animates into a distinct rounded pill background (`borderRadius: 22`) in warm beige (`0xFFEFE4D2` light) or carbon (`0xFF2B2B2B` dark) enclosing the icon and label.
  - Active home icon renders as a cute pentagonal house with circular doorway cutout; inactive icons render with crisp outlined geometry.
- **Top-Floating Toast Notifications (`AppToast`)**:
  - Replaced standard bottom snackbars with a top-aligned, floating pill overlay toast (`AppToast.show`).
  - Positioned safely under the top status bar / `SafeArea` with slide-down and fade animation.
  - Toast messages are strictly concise, punchy action phrases without emoji/paw clutter (`Created task`, `Added friend`, `Friend removed`, `Friend request sent`, `Task updated`, etc.).
  - Auto-dismisses in 2.2 seconds, or dismisses instantly upon tap or swipe-up.
- **Cat Trail & Paw Prints Background**: Recreated from visual reference as a bold, stylized dashed trail (`strokeWidth: 7.0`, `dashLength: 16.0`, `dashGap: 15.0`) curving down the screen, looping wide around two large stepping cat paw prints (`pawSize: 68.0`), and looping across the bottom. Rendered at the `HomeScreen` level behind all primary tabs (**Home Tasks**, **Profile & Stats**, **Friends**).
  - Dark Theme: Soft whitish line & filled paws (`withValues(alpha: 0.28)`).
  - Light/White Theme: Soft dark-charcoal line & filled paws (`withValues(alpha: 0.20)`).

## Components & Architecture
- **Mobile (Flutter)**:
  - `app/lib/core/theme/app_colors.dart` - Central paired palette definition (`AppPalette`, `AppColors.of(context)`).
  - `app/lib/presentation/widgets/app_toast.dart` - Global top-floating animated pill notification system.
  - `app/lib/presentation/widgets/app_outlined_icons.dart` - Custom 2.2px rounded outlined SVGs, `TaskStatusBadge` (no text), `TaskPriorityBadge` (no text), and `PriorityChoicePill`.
  - `app/lib/presentation/screens/home/widgets/cat_trail_background.dart` - Cat trail and paw prints background painter rendered behind all tabs on `HomeScreen`.
  - `app/lib/presentation/screens/home/widgets/home_tasks_view.dart` - Home tasks scroll layout hosting background stack.
  - `app/lib/services/theme_service.dart` - `ValueNotifier<ThemeMode>` singleton managing theme persistence.
  - `app/assets/fonts/Sniglet-Regular.ttf` - Core brand font.
  - `app/lib/main.dart` - Material theme definitions.
- **Web (Next.js)**:
  - `Web/lib/theme/colors.ts` - Paired theme colors for light and dark modes.
  - `Web/components/icons/AppIcons.tsx` - Outlined SVGs, `TaskStatusBadge`, `TaskPriorityBadge`.
  - `Web/app/dashboard/page.tsx` - Dashboard consuming centralized outlined SVGs and badges.
