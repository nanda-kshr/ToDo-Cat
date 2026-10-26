---
type: Feature
title: Android Home Screen Widgets
description: Interactive Android home widgets including Quick Add dialog, pet companion widgets, and scrollable task lists adhering to light/dark themes.
tags: [widgets, android, home_widget, glance, theming]
status: active
last_updated: 2026-10-26
---

# Android Home Screen Widgets

## Overview
Android home screen widgets allowing users to view tasks and quickly create new tasks without opening the full application:
- **Quick Add Widget**: Direct pop-up dialog (`QuickAddActivity`) to enter and save tasks immediately.
- **Scrollable List Widget**: `RemoteViewsService` showing active tasks with direct check-off buttons.
- **Interactive Cat Companion Widgets**: Display cat status, current clock, task ratio, and custom progress bar with sleep/active animations.
- **Dual Theme Support**: Automatically adapts layout drawables, text colors, and card surfaces to match Light (`#FDF2DD` background, `#F7E9DD` card, `#2B1D16` text) and Dark (`#0E0E0E` background, `#1A1A1A` card, `#F5F5F5` text) modes.

## Components & Architecture
- **Mobile (Flutter & Android)**:
  - `app/lib/services/widget_service.dart` - Synchronizes task data to App Group / Widget preferences via `home_widget`.
  - `app/lib/presentation/screens/home/widgets/widget_choice_dialog.dart` - Flutter dialog for selecting widget layouts styled to theme tokens.
  - `app/android/app/src/main/kotlin/com/todocat/app/QuickAddActivity.kt` - Dialog activity for widget quick add supporting light/dark styling.
  - `app/android/app/src/main/kotlin/com/todocat/app/TodoCatWidgetService.kt` - RemoteViews provider with theme-aware task row and checkbox styling.
  - `app/android/app/src/main/kotlin/com/todocat/app/TodoCatWidgetProvider.kt` & `TodoCatListWidgetProvider.kt` - Widget broadcast receivers.
  - `app/android/app/src/main/res/drawable/` - Native shape drawables for light (`widget_background_light.xml`, `widget_cat_card_bg.xml`, etc.) and dark (`widget_background.xml`, `widget_cat_card_bg_dark.xml`, etc.) variants.
