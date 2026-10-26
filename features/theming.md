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
  - Adding any new color token requires defining both light and dark palette values simultaneously, ensuring complete theme parity.
  - Mobile: `app/lib/core/theme/app_colors.dart` (`AppPalette`, `AppColors.light`, `AppColors.dark`).
  - Web: `Web/lib/theme/colors.ts` (`ThemeColors`, `AppColors.light`, `AppColors.dark`).
- **Hand-Crafted Outlined SVG Icons**:
  - All icons are styled with consistent 2.2px rounded outline strokes (no generic AI icons or harsh solid fills).
  - Status Indicators (Completed, Pending): Rendered as pure outlined SVG icons without text.
  - Priority Badges (High, Medium, Low): Rendered as pure outlined SVG art (High: stylized flame; Medium: balanced dual bars; Low: calm chevron) without text.
  - Shared Collaboration Badge: Outlined people icon with concise `x/y done` text.
- **Dynamic Procedural Background**: A stylish thick dashed Bezier ribbon (`strokeWidth: 5.5`) in the home screen background responsive to scroll gestures.

## Components & Architecture
- **Mobile (Flutter)**:
  - `app/lib/core/theme/app_colors.dart` - Central paired palette definition (`AppPalette`, `AppColors.of(context)`).
  - `app/lib/presentation/widgets/app_outlined_icons.dart` - Custom 2.2px rounded outlined SVGs, `TaskStatusBadge` (no text), `TaskPriorityBadge` (no text), and `PriorityChoicePill`.
  - `app/lib/presentation/screens/home/widgets/curvy_dashed_background.dart` - Procedural dashed background painter.
  - `app/lib/presentation/screens/home/widgets/home_tasks_view.dart` - Home tasks scroll layout hosting background stack.
  - `app/lib/services/theme_service.dart` - `ValueNotifier<ThemeMode>` singleton managing theme persistence.
  - `app/assets/fonts/Sniglet-Regular.ttf` - Core brand font.
  - `app/lib/main.dart` - Material theme definitions.
- **Web (Next.js)**:
  - `Web/lib/theme/colors.ts` - Paired theme colors for light and dark modes.
  - `Web/components/icons/AppIcons.tsx` - Outlined SVGs, `TaskStatusBadge`, `TaskPriorityBadge`.
  - `Web/app/dashboard/page.tsx` - Dashboard consuming centralized outlined SVGs and badges.
