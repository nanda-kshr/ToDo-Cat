---
type: Feature
title: Android Home Screen Widgets
description: Interactive Android home widgets including Quick Add dialog and scrollable task lists.
tags: [widgets, android, home_widget, glance]
status: active
last_updated: 2026-10-25
---

# Android Home Screen Widgets

## Overview
Android home screen widgets allowing users to view tasks and quickly create new tasks without opening the full application:
- **Quick Add Widget**: Direct pop-up dialog (`QuickAddActivity`) to enter and save tasks immediately.
- **Scrollable List Widget**: `RemoteViewsService` showing active tasks with direct check-off buttons.

## Components & Architecture
- **Mobile (Flutter & Android)**:
  - `app/lib/services/widget_service.dart` - Synchronizes task data to App Group / Widget preferences via `home_widget`.
  - `app/android/app/src/main/kotlin/com/todocat/app/QuickAddActivity.kt` - Dialog activity for widget quick add.
  - `app/android/app/src/main/kotlin/com/todocat/app/TodoCatWidgetService.kt` - RemoteViews provider.
