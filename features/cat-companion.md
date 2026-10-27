---
type: Feature
title: Cat Companion & Floating Overlay
description: Gamified animated cat mascot reflecting user velocity and optional system-wide floating overlay on Android with light/dark theme adaptation.
tags: [gamification, cat, animation, overlay, android, theming]
status: active
last_updated: 2026-10-27
---

# Cat Companion & Floating Overlay

## Overview
A dynamic cat companion that animates across the header of the app and can float over other Android applications:
- **Velocity Reactivity**: Cat's walking/running speed scales dynamically with the user's task completion pace.
- **Daily Cat Briefing**: Client-side time-of-day greeting and task debrief (Morning, Afternoon, Evening, Night) without background crons or emojis.
- **Floating Overlay Service**: Android native Foreground Service displaying a mini cat over any app with touch interactions.
- **Expanded Overlay View**: Tapping the floating cat reveals a full task management card supporting task creation, check-off, and priority indicators.
- **Theme Parity**: Automatically mirrors the central theme palette across light (`#F7E9DD` card, `#F8EEDF` input, `#2B1D16` text) and dark (`#1A1A1A` card, `#1C1C1C` input, `#F5F5F5` text) modes.

## Daily Cat Briefing
- **Client-Side Trigger**: Evaluated on app open and foreground resume (`didChangeAppLifecycleState`). Deduplicated by period key (`YYYY-MM-DD-period`) so users only receive one in-app toast per time bracket.
- **Periods & Messages (Zero-Emoji Policy)**:
  - *Morning (05:00 - 11:59)*:
    - Active tasks: `"Good morning! X tasks waiting today."`
    - All caught up: `"Good morning! All caught up for today."`
    - No tasks: `"Good morning! Ready for today?"`
  - *Afternoon (12:00 - 16:59)*:
    - Active tasks: `"Good afternoon! X tasks remaining."`
    - All caught up: `"Good afternoon! All caught up for today."`
    - No tasks: `"Good afternoon! Ready for today?"`
  - *Evening (17:00 - 21:59)*:
    - All completed & 0 pending: `"Good evening! You crushed X tasks today! Cat is happy and asleep."`
    - Pending tasks: `"Good evening! X tasks remaining today."`
    - No tasks / caught up: `"Good evening! Have a peaceful rest."`
  - *Night (22:00 - 04:59)*:
    - Completed tasks: `"You crushed X tasks today! Cat is asleep."`
    - Default: `"Cat is asleep. Rest well for tomorrow."`
- **Surfaces**:
  - Flutter Mobile: Live speech bubble in `HomeStatusBanner` + periodic `AppToast` banner on resume.
  - Web Dashboard: Live Cat companion banner message in `Web/app/dashboard/page.tsx`.

## Components & Architecture
- **Mobile (Flutter & Android)**:
  - `app/lib/presentation/screens/home/widgets/home_status_banner.dart` - Home screen big status card with a 50/50 horizontal split: half width for the enlarged animated cat (`size: ~135px`, responsive clamp `120-155px`) with clean speech bubble, and half width for active tasks count, prominent `48px` percentage counter, `16px` pill progress bar, and completion summary.
  - `app/lib/services/floating_cat_service.dart` - MethodChannel bridge for controlling the floating cat overlay.
  - `app/android/app/src/main/kotlin/com/todocat/app/FloatingCatService.kt` - Android overlay implementation using WindowManager and theme-aware UI views.
  - `app/assets/runners/cat/` & `cat_white/` - Sprite sheets for running animations.
