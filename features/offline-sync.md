---
type: Feature
title: Offline Sync & Local Caching
description: Offline-first task creation and status changes using SharedPreferences, automatically synced to the server upon reconnection.
tags: [offline, sync, caching, resilience]
status: active
last_updated: 2026-10-25
---

# Offline Sync & Local Caching

## Overview
Ensures the app remains fully responsive and functional even without internet connectivity:
- Tasks can be created while offline; they receive temporary IDs formatted as `local-${timestamp}`.
- Local task states and completions are persisted directly in `SharedPreferences` under `tasks_json`.
- When connectivity resumes (or on app resume / pull-to-refresh), `TaskSyncService` synchronizes offline creations and toggles to the MongoDB backend.

## Components & Architecture
- **Flutter**:
  - `app/lib/services/task_sync_service.dart` - Identifies `local-*` tasks, creates them on the server with full metadata (dates, times, recurrence, categories), and reconciles IDs.
  - `app/lib/presentation/screens/home/widgets/create_task_modal.dart` - Offline fallback catch handler that inserts local tasks.
  - `app/lib/presentation/screens/home_screen.dart` - `_syncWidget()` and `_loadData()` triggers.

## Sync Flow
1. User creates task offline $\rightarrow$ stored locally with `local-${id}`.
2. User regains connection / pulls to refresh $\rightarrow$ `TaskSyncService.syncOfflineTasksToServer` invoked.
3. Server returns persistent MongoDB `_id` $\rightarrow$ local ID is replaced and cached list updated.
