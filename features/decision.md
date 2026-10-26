---
type: DecisionLog
title: Architectural & Design Decisions
description: Authoritative log of architectural decisions, project constraints, and coding styles established for TodoCat across mobile and web.
tags: [decisions, architecture, coding-style, theme-rules, constraints]
status: active
last_updated: 2026-10-26
---

# Architectural & Design Decisions

## 1. Typography & Branding
- **Sniglet Font**: Universal rounded font for TodoCat across mobile and web platforms.

## 2. Color System & Theming
- **No Glowing/Neon Colors**: Avoid bright neon yellow, neon green (`#10B981`, `#22C55E`), or glowing red accents.
- **Theme Modes**:
  - **Dark Mode**: Crisp whitish monochrome tones (`#FFFFFF`, `#F4F4F5`, `#A1A1AA`) on deep carbon backgrounds (`#0A0A0A`, `#141414`, `#1F1F1F`).
  - **Light/White Mode**: Warm, soothing cream tones (`#FAF8F5`, `#FFFDFB`, `#EFEBE2`, `#E8E2D8`) with warm espresso/charcoal accents (`#292524`, `#78716C`).
- **Subtle Green / Sage Accents**:
  - For public productivity indicators, stats visibility switch, friend public stats badges, and public globe icons, use a muted whitish shade of green rather than bright/light green:
    - Dark mode: `Color(0xFFD4E7DC)` (subtle whitish sage green) with soft dark sage background `Color(0xFF1B241F)` and border `Color(0xFF2C3B32)`.
    - Light mode: `Color(0xFF476251)` (warm muted sage) with pale cream-sage background `Color(0xFFEDF3EE)` and border `Color(0xFFD8E4DC)`.
- **Centralized Palettes**:
  - All element colors must be defined in central palette registries: `app/lib/core/theme/app_colors.dart` (`AppPalette`, `AppColors`) on Mobile and `Web/lib/theme/colors.ts` on Web.
  - Adding a new color token requires defining paired values for both Light and Dark themes simultaneously.

## 3. Icons & Visual Assets
- **Outlined SVG Art**: All status indicators, priority icons, and common controls must use hand-drawn/rounded 2.2px outlined SVGs rather than solid fills or generic AI graphics.
- **Pure Outlined Status Badges**: Completed and Pending indicators render as outlined SVG icons without extraneous text labels.
- **Priority Indicators**: Pure outlined SVG art (flame for high, dual bars for medium, chevron for low) without text labels.
- **Handwritten Friend Request Actions**: Friend request accept (tick) and decline (cross) icons match handwritten Sniglet stroke aesthetics.

## 4. Multi-Platform Consistency
- Web (Next.js 16 + React 19 + Tailwind) and Mobile (Flutter 3.27+) must maintain full feature and visual token parity.
- Functions must not be duplicated within files or services; maintain modular reusable helpers.
