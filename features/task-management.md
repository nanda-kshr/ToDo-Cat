---
type: Feature
title: Task Management
description: Complete CRUD task management with nullable due dates, time precision, recurrence dropdown, priority, and categories.
tags: [tasks, crud, scheduling, recurrence, priority]
status: active
last_updated: 2026-10-26
---

# Task Management

## Overview
Allows users to create, view, edit, filter, and complete tasks with rich scheduling attributes:
- **Frosted Blur Creation Modal**: The task creation modal applies an ambient frosted glass background blur (`ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0)`) over the background home screen with a soft dark barrier dimming.
- **Deadline Handling**: Defaults to `null` (no deadline). Can be set with optional specific time of day.
- **Recurrence**: Supports `none`, `daily`, `weekly`, `monthly`, and `yearly` recurrences via popup dropdowns.
- **Priority**: Categorized as `low`, `medium`, or `high`, rendered visually as custom outlined SVG art (flame, balance bars, calm chevron) with no text.
- **Category**: Custom category labels (e.g. `General`, `Work`, `Personal`).
- **Completion**: Fast toggle with instant UI feedback, textless outlined SVG status indicators (`Completed`, `Pending`), and cat animation triggers.
- **5-Second Undo Deletion**:
  - Deleting a task immediately removes it from the UI optimistically.
  - Displays a 5-second toast/banner notification with an **"Undo"** action.
  - Tapping **Undo** cancels the deletion timer and restores the task to its exact position in the list without sending any DELETE request to the backend.
  - If 5 seconds elapse without undo, the task deletion is permanently committed via `DELETE /api/tasks/:id`.
  - Pending deletions are automatically flushed if the app enters background or page unloads.

## Components & Architecture
- **Web Backend**:
  - `Web/models/Task.ts` - Task schema with indices on `userId`, `completed`, and `dueDate`.
  - `Web/app/api/tasks/route.ts` - List tasks with pagination and creation.
  - `Web/app/api/tasks/[id]/route.ts` - PATCH/DELETE task endpoints with cache invalidation.
  - `Web/lib/taskCache.ts` - In-memory task caching per user.
- **Mobile (Flutter)**:
  - `app/lib/models/task.dart` - `Task` model with `toJson()` and `fromJson()`.
  - `app/lib/presentation/screens/home/widgets/create_task_modal.dart` - Task creation bottom sheet.
  - `app/lib/presentation/screens/home/widgets/task_details_modal.dart` - Task viewing and editing modal.
  - `app/lib/presentation/screens/home/widgets/home_tasks_view.dart` - Task list and filter pills.

## API Specification
- `GET /api/tasks?page=1&limit=50`: Returns paginated tasks.
- `POST /api/tasks`: Create task `{ title, description?, dueDate?, hasTime?, recurrence?, priority?, category? }`.
- `PATCH /api/tasks/:id`: Update fields or toggle completion `{ completed?, ... }`.
- `DELETE /api/tasks/:id`: Delete task.
