---
type: Feature
title: Analytics & Productivity Metrics
description: Task completion rate, streak calculations, velocity stats, and social friend stats sharing with public/private controls.
tags: [analytics, metrics, streaks, productivity, privacy, profile]
status: active
last_updated: 2026-10-26
---

# Analytics & Productivity Metrics

## Overview
Provides visual analytics to help users track productivity across time horizons (today, 7d, 30d, this month):
- **Profile & Stats Integration**: The bottom navigation features a dedicated **Profile** tab that displays the user profile at the top and productivity stats below.
- **Privacy Controls**: Users can toggle stats visibility between **Private** (default) and **Public**.
- **Social Sharing**: When public, friends can view a user's stats directly by tapping on their card in the **Friends** tab.
- **Completion & Velocity**: Metrics including total, completed, pending, completion rate, due status, priority breakdown, category distribution, and completion trends.

## Components & Architecture
- **Web Backend**:
  - `Web/models/User.ts` - `isProfilePublic` field (default `false`).
  - `Web/app/api/auth/me/route.ts` - `PATCH` endpoint to update profile and privacy.
  - `Web/app/api/analytics/route.ts` - Calculates metrics; enforces friendship checks and `isProfilePublic` verification when `friendId` is requested.
- **Mobile (Flutter)**:
  - `app/lib/models/analytics.dart` - `TaskAnalytics` model.
  - `app/lib/presentation/screens/home/widgets/profile_view.dart` - Profile header with public/private toggle and integrated stats view below.
  - `app/lib/presentation/screens/home/widgets/friend_stats_sheet.dart` - Modal sheet allowing friends to view public stats.
  - `app/lib/presentation/screens/home/widgets/home_bottom_bar.dart` - 'Profile' tab navigation item.
