---
type: Feature
title: Analytics & Productivity Metrics
description: Task completion rate, streak calculations, and velocity stats filtered by period.
tags: [analytics, metrics, streaks, productivity]
status: active
last_updated: 2026-10-25
---

# Analytics & Productivity Metrics

## Overview
Provides visual analytics to help users track productivity across time horizons (all, today, this week, this month):
- **Completion Rate**: Percentage of completed vs pending tasks.
- **Current & Best Streaks**: Daily consecutive task completion tracking.
- **Productivity Velocity**: Speed metrics displayed visually through cat animation speeds.

## Components & Architecture
- **Web Backend**:
  - `Web/app/api/analytics/route.ts` - Aggregation pipelines for streaks, counts, and completion ratios.
- **Mobile (Flutter)**:
  - `app/lib/models/analytics.dart` - `TaskAnalytics` model.
  - `app/lib/presentation/screens/home/widgets/stats_view.dart` - Visual charts and streak cards.
