---
type: Feature
title: Task Management
description: Complete CRUD task management with nullable due dates, time precision, recurrence dropdown, priority, and categories.
tags: [tasks, crud, scheduling, recurrence, priority]
status: active
last_updated: 2026-10-25
---

# Task Management

## Overview
Allows users to create, view, edit, filter, and complete tasks with rich scheduling attributes:
- **Deadline Handling**: Defaults to `null` (no deadline). Can be set with optional specific time of day.
- **Recurrence**: Supports `none`, `daily`, `weekly`, `monthly`, and `yearly` recurrences via popup dropdowns.
- **Priority**: Categorized as `low`, `medium`, or `high`.
- **Category**: Custom category labels (e.g. `General`, `Work`, `Personal`).
- **Completion**: Fast toggle with instant UI feedback and cat animation triggers.

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
