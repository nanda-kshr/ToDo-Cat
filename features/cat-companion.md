---
type: Feature
title: Cat Companion, Floating Overlay & macOS Menu Bar
description: Gamified animated cat/bunny companion reflecting user velocity, optional system-wide floating overlay on Android, and top status menu bar companion for macOS.
tags: [gamification, cat, bunny, animation, overlay, android, macos, menubar, theming]
status: active
last_updated: 2026-11-06
---

# Cat Companion, Floating Overlay & macOS Menu Bar

## Overview
A dynamic cat companion that animates across the header of the app, floats over Android applications, and runs on the top macOS menu bar next to Wi-Fi and Control Center:
- **Velocity Reactivity**: Companion's walking/running speed scales dynamically with the user's task completion pace.
- **Daily Cat Briefing**: Client-side time-of-day greeting and task debrief (Morning, Afternoon, Evening, Night) without background crons or emojis.
- **macOS Menu Bar Companion**: Native AppKit `NSStatusItem` displaying real-time running/sleeping companion frames next to system icons, complete with speed feedback, task counts, companion switcher, and quick window activation.
- **Floating Overlay Service**: Android native Foreground Service displaying a mini cat over any app with touch interactions.
- **Expanded Overlay View**: Tapping the floating cat reveals a full task management card supporting task creation, check-off, and priority indicators.
- **Theme & Color Parity**: Automatically mirrors the central theme palette across light and dark modes with selectable variants (Auto, Black, White).
- **Multiple Runner Companions**: Supports selectable companion mascots (`Cat` and `Bunny`), each with independent run/sleep frame counts (`assets/runners/<runner>/run/<frame>.png` and `assets/runners/<runner>/sleep/<frame>.png`).

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
  - `app/lib/services/floating_cat_service.dart` - MethodChannel bridge for controlling the floating companion overlay with dynamic runner parameter.
  - `app/android/app/src/main/kotlin/com/todocat/app/FloatingCatService.kt` - Android overlay implementation using WindowManager and theme-aware UI views supporting dynamic runner mascots (Cat and Bunny) in both running and sleeping states.
  - `app/lib/models/runner.dart` - `RunnerType` enum (Cat, Bunny) with dynamic frame counts and asset path resolvers.
  - `app/assets/runners/` - Multi-runner sprite frames categorized by `run/` and `sleep/` for Cat (7/6 frames) and Bunny (5/5 frames) in default and white color variants.
- **Desktop (macOS)**:
  - `app/macos/Runner/AppDelegate.swift` - Hosts `MenuBarCompanionManager`, managing AppKit's `NSStatusItem` (`28x28pt` sprite frames with `.scaleProportionallyDown` and dynamic `NSAppearance` menu bar contrast detection), sprite frame animation timer, and a compact, scrollable `NSPopover` interface with a Quick Task entry text box on top, optimistic task completion checkboxes, live task count badge, and runner switcher. Operates as a pure menu bar companion via `LSUIElement = true` and `NSApplication.ActivationPolicy.accessory`, preventing Dock clutter and running persistently on top. Prevents app termination on window close when the menu bar companion is active.
  - `app/macos/Runner/MainFlutterWindow.swift` - Connects the Flutter engine binary messenger with the native menu bar companion manager.
  - `app/lib/services/mac_menu_bar_service.dart` - Flutter `MethodChannel` (`com.todocat.app/macos_menu_bar`) sending real-time task velocity, active counts, theme variants, and runner mascot type.
  - `app/lib/presentation/screens/home/widgets/settings_modal.dart` - Provides native toggle for "Menu Bar Companion" on macOS devices.
- **Web (Next.js)**:
  - `Web/components/CatAnimation.tsx` - Reusable multi-runner animation component supporting dynamic frame loops, sleep/run cycles, theme cards/dark variants, and local storage synchronization.
  - `Web/public/runners/` - Synced multi-runner frames mirroring the Flutter asset structure.
  - `Web/app/dashboard/page.tsx` & `Web/app/page.tsx` - Live runner switcher (Cat vs. Bunny) and briefing messages.
