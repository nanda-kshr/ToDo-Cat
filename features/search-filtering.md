---
type: Feature
title: Task Search & Dynamic Filtering
description: Real-time search query matching with status, date, priority, and category filter chips.
tags: [search, filtering, categories, priorities]
status: active
last_updated: 2026-10-25
---

# Task Search & Dynamic Filtering

## Overview
Allows users to rapidly locate and segment tasks in real-time without reloading:
- **Search Bar**: Instant client-side text filtering against task titles and descriptions.
- **Filter Chips**:
  - `All`: View all active and completed tasks.
  - `Today`: Tasks due today.
  - `Upcoming`: Future-dated tasks.
  - `High Priority`: Tasks marked with high urgency.
  - `Category`: Dynamic chips by custom category (e.g. `Work`, `Personal`).

## Components & Architecture
- **Mobile (Flutter)**:
  - `app/lib/presentation/screens/home/widgets/home_search_filter_bar.dart` - Search input and horizontally scrollable filter chips.
  - `app/lib/presentation/screens/home/widgets/home_tasks_view.dart` - Grouping into Today vs Earlier tasks with empty state placeholders.
