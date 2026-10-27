---
type: Feature
title: Task Management
description: Complete CRUD task management with nullable due dates, time precision, recurrence dropdown, priority, and categories.
tags: [tasks, crud, scheduling, recurrence, priority]
status: active
last_updated: 2026-10-27
---

# Task Management

## Overview
Allows users to create, view, edit, filter, and complete tasks with rich scheduling attributes:
- **Frosted Blur Creation Modal**: The task creation modal applies an ambient frosted glass background blur (`ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0)`) over the background home screen with a soft dark barrier dimming.
- **Deadline Handling**: Defaults to `null` (no deadline). Can be set with optional specific time of day.
- **Recurrence**: Supports `none`, `daily`, `weekly`, `monthly`, and `yearly` recurrences via popup dropdowns.
- **Priority**: Categorized as `low`, `medium`, or `high`, rendered visually as custom outlined SVG art (flame, balance bars, calm chevron) with no text.
- **Category & Shared Category System**:
  - Default preset categories are strictly `General` and `Work`.
  - Deprecated and removed unused clutter chips (`Personal`, `Study`, `Health`, `Shopping`) to preserve visual breathing room.
  - Features an inline `+ Add Category` button that opens a modal to name the category and optionally select friends.
  - Tasks created under a shared category automatically inherit member sharing with all collaborators.
- **Completion & Optimistic UI**: Instant tick mark toggle with zero network latency. The UI updates locally immediately, fires the background update API call, and automatically rolls back if the network drops or server fails.
- **Swipe Gestures & Accidental Scroll Protection**:
  - Requires a deliberate horizontal swipe threshold (35%) so vertical scrolling never triggers accidental actions.
  - **Swipe Right $\to$**: Instantly toggles completion status optimistically and snaps back smoothly.
  - **Swipe Left $\leftarrow$**: Moves the task to the `'deleted'` status section.
- **'deleted' Status Section**:
  - Deleted tasks are retained as a `'deleted'` status rather than instantly destroyed.
  - Displayed in a collapsible section right below Today's tasks with a smooth animation and count badge.
  - Users can tap "Restore" (or swipe right) to return the task to active status smoothly.
  - Permanent deletion is available via the "Delete Forever" action.

## Components & Architecture
- **Web Backend**:
  - `Web/models/Task.ts` - Task schema with indices on `userId`, `completed`, and `dueDate`.
  - `Web/models/Category.ts` - Category schema with compound index on `(userId, name)` and `sharedWith`.
  - `Web/app/api/categories/route.ts` - List and create categories with collaborator sharing.
  - `Web/app/api/tasks/route.ts` - List tasks and create tasks with auto-inherited category collaborators.
  - `Web/app/api/tasks/[id]/route.ts` - PATCH/DELETE task endpoints with cache invalidation.
  - `Web/lib/taskCache.ts` - In-memory task caching per user.
- **Mobile (Flutter)**:
  - `app/lib/models/task.dart` - `Task` model with `toJson()` and `fromJson()`.
  - `app/lib/models/category.dart` - `CategoryItem` model supporting shared collaborators.
  - `app/lib/presentation/screens/home/widgets/create_task_modal.dart` - Task creation bottom sheet with dynamic categories and Add Category modal.
  - `app/lib/presentation/screens/home/widgets/task_details_modal.dart` - Task viewing and editing modal with dynamic category chips.
  - `app/lib/presentation/screens/home/widgets/home_tasks_view.dart` - Task list and filter pills.

## API Specification
- `GET /api/categories`: Returns categories owned by user or shared with user.
- `POST /api/categories`: Create category `{ name, sharedWith?: string[] }`.
- `GET /api/tasks?page=1&limit=50`: Returns paginated tasks.
- `POST /api/tasks`: Create task `{ title, description?, dueDate?, hasTime?, recurrence?, priority?, category? }`.
- `PATCH /api/tasks/:id`: Update fields or toggle completion `{ completed?, ... }`.
- `DELETE /api/tasks/:id`: Delete task.
