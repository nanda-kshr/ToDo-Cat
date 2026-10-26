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
  - **Dark Mode**: Crisp whitish monochrome tones (`#FFFFFF`, `#F4F4F5`, `#A1A1AA`) on deep carbon (`#0A0A0A`), avoiding glowing red/yellow/green tints.
  - **White/Light Mode**: Warm, soothing cream tones (`#FAF8F5`, `#FFFDFB`, `#EFEBE2`, `#E8E2D8`) with warm espresso/charcoal accents (`#292524`, `#78716C`), avoiding glowing red/yellow/green tints.
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
- **Cat Trail & Paw Prints Background**: Recreated from visual reference as a bold, stylized dashed trail (`strokeWidth: 7.0`, `dashLength: 16.0`, `dashGap: 15.0`) curving down the screen, looping wide around two large stepping cat paw prints (`pawSize: 68.0`), and looping across the bottom. Rendered at the `HomeScreen` level behind all primary tabs (**Home Tasks**, **Profile & Stats**, **Friends**).
  - Dark Theme: Soft whitish line & filled paws (`withValues(alpha: 0.28)`).
  - Light/White Theme: Soft dark-charcoal line & filled paws (`withValues(alpha: 0.20)`).

## Components & Architecture
- **Mobile (Flutter)**:
  - `app/lib/core/theme/app_colors.dart` - Central paired palette definition (`AppPalette`, `AppColors.of(context)`).
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
