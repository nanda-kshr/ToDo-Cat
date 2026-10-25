---
type: Feature
title: Theming & Visual Design
description: Playful Sniglet-based typography with full Light, Dark, and System theme modes.
tags: [theme, typography, dark-mode, styling]
status: active
last_updated: 2026-10-25
---

# Theming & Visual Design

## Overview
TodoCat features a cohesive, playful design aesthetic built around the `Sniglet` rounded font:
- **Theme Modes**: Supports Light, Dark, and System auto-detection.
- **Persistence**: Theme selection is saved in `SharedPreferences` and restored immediately upon app boot.

## Components & Architecture
- **Mobile (Flutter)**:
  - `app/lib/services/theme_service.dart` - `ValueNotifier<ThemeMode>` singleton managing theme persistence.
  - `app/assets/fonts/Sniglet-Regular.ttf` - Core brand font.
  - `app/lib/main.dart` - Theme definitions for light and dark modes.
