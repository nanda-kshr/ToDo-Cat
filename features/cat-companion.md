---
type: Feature
title: Cat Companion & Floating Overlay
description: Gamified animated cat mascot reflecting user velocity and optional system-wide floating overlay on Android.
tags: [gamification, cat, animation, overlay, android]
status: active
last_updated: 2026-10-25
---

# Cat Companion & Floating Overlay

## Overview
A dynamic cat companion that animates across the header of the app and can float over other Android applications:
- **Velocity Reactivity**: Cat's walking/running speed scales dynamically with the user's task completion pace.
- **Floating Overlay Service**: Android native Foreground Service displaying a mini cat over any app with touch interactions.

## Components & Architecture
- **Mobile (Flutter & Android)**:
  - `app/lib/services/floating_cat_service.dart` - MethodChannel bridge for controlling the floating cat overlay.
  - `app/android/app/src/main/kotlin/com/todocat/app/FloatingCatService.kt` - Android overlay implementation using WindowManager.
  - `app/assets/runners/cat/` & `cat_white/` - Sprite sheets for running animations.
