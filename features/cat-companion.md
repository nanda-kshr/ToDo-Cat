---
type: Feature
title: Cat Companion & Floating Overlay
description: Gamified animated cat mascot reflecting user velocity and optional system-wide floating overlay on Android with light/dark theme adaptation.
tags: [gamification, cat, animation, overlay, android, theming]
status: active
last_updated: 2026-10-26
---

# Cat Companion & Floating Overlay

## Overview
A dynamic cat companion that animates across the header of the app and can float over other Android applications:
- **Velocity Reactivity**: Cat's walking/running speed scales dynamically with the user's task completion pace.
- **Floating Overlay Service**: Android native Foreground Service displaying a mini cat over any app with touch interactions.
- **Expanded Overlay View**: Tapping the floating cat reveals a full task management card supporting task creation, check-off, and priority indicators.
- **Theme Parity**: Automatically mirrors the central theme palette across light (`#F7E9DD` card, `#F8EEDF` input, `#2B1D16` text) and dark (`#1A1A1A` card, `#1C1C1C` input, `#F5F5F5` text) modes.

## Components & Architecture
- **Mobile (Flutter & Android)**:
  - `app/lib/presentation/screens/home/widgets/home_status_banner.dart` - Home screen big status card with a 50/50 horizontal split: half width for the enlarged animated cat (`size: ~135px`, responsive clamp `120-155px`) with clean speech bubble, and half width for active tasks count, prominent `48px` percentage counter, `16px` pill progress bar, and completion summary.
  - `app/lib/services/floating_cat_service.dart` - MethodChannel bridge for controlling the floating cat overlay.
  - `app/android/app/src/main/kotlin/com/todocat/app/FloatingCatService.kt` - Android overlay implementation using WindowManager and theme-aware UI views.
  - `app/assets/runners/cat/` & `cat_white/` - Sprite sheets for running animations.
