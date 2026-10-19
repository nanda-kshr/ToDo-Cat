import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'api_service.dart';
import 'floating_cat_service.dart';
import 'theme_service.dart';
import 'widget_service.dart';

List<Task> _decodeTasksList(String raw) {
  try {
    final List<dynamic> localList = jsonDecode(raw);
    return localList
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

class TaskSyncService {
  TaskSyncService._();

  static Future<String?> getCachedTasksJson() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.getString('tasks_json');
    } catch (_) {
      return null;
    }
  }

  static List<Task> parseTasksJson(String raw) => _decodeTasksList(raw);

  static Future<List<Task>> parseTasksJsonAsync(String raw) async {
    if (raw.length > 2048) {
      return compute(_decodeTasksList, raw);
    }
    return _decodeTasksList(raw);
  }

  static List<Task> mergeLocalTasks({
    required List<Task> loaded,
    required List<Task> current,
  }) {
    if (loaded.isEmpty && current.isNotEmpty) return current;
    if (current.isEmpty) return loaded;

    final localMap = {for (var t in loaded) t.id: t};
    final existingIds = current.map((t) => t.id).toSet();
    final newTasks = loaded.where((t) => !existingIds.contains(t.id)).toList();

    return [
      ...newTasks,
      ...current.map((t) {
        if (localMap.containsKey(t.id)) {
          final lt = localMap[t.id]!;
          return t.copyWith(
            completed: lt.completed,
            updatedAt: lt.updatedAt ?? t.updatedAt,
          );
        }
        return t;
      }),
    ];
  }

  static Future<bool> syncOfflineTasksToServer({
    required ApiService apiService,
    required List<Task> currentTasks,
    List<Task>? serverTasks,
  }) async {
    try {
      final raw = await getCachedTasksJson();
      if (raw == null || raw.isEmpty) return false;

      final List<dynamic> localList = jsonDecode(raw);
      final targetList = serverTasks ?? currentTasks;
      final serverTaskMap = {for (var t in targetList) t.id: t};
      final serverTitles = targetList.map((t) => t.title).toSet();
      bool hasChanges = false;

      for (final item in localList) {
        final title = item['title'] as String?;
        final id = item['id'] as String?;
        final completed = item['completed'] as bool? ?? false;

        if (title != null &&
            title.isNotEmpty &&
            id != null &&
            id.contains('-') &&
            !serverTitles.contains(title)) {
          final created = await apiService.createTask(title: title);
          if (serverTasks != null) {
            serverTasks.insert(0, created);
          } else {
            final idx = currentTasks.indexWhere((t) => t.id == id);
            if (idx != -1) {
              currentTasks[idx] = created;
            } else {
              currentTasks.insert(0, created);
            }
          }
          serverTitles.add(title);
          hasChanges = true;
        } else if (id != null && serverTaskMap.containsKey(id)) {
          final serverTask = serverTaskMap[id]!;
          if (serverTask.completed != completed) {
            await apiService.updateTask(id, completed: completed);
            final idx = targetList.indexWhere((t) => t.id == id);
            if (idx != -1) {
              targetList[idx] = targetList[idx].copyWith(
                completed: completed,
                updatedAt: DateTime.now(),
              );
            }
            hasChanges = true;
          }
        }
      }

      return hasChanges;
    } catch (_) {
      return false;
    }
  }

  static void syncWidget(
    BuildContext context, {
    required List<Task> tasks,
    required int activeCount,
    required int todayTotalCount,
    required int catSpeed,
    required bool isFloatingOverlayRunning,
  }) {
    final tasksJson = jsonEncode(tasks.map((t) => t.toJson()).toList());
    final isWhite = ThemeService.instance.isCatWhite(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final speedMessage = activeCount == 0 ? 'All caught up' : '$activeCount tasks pending';

    WidgetService.updateWidget(
      pendingCount: activeCount,
      totalCount: todayTotalCount,
      speedPercent: catSpeed,
      speedMessage: speedMessage,
      isDark: isDark,
      isCatWhite: isWhite,
      tasksJson: tasksJson,
    );

    if (isFloatingOverlayRunning) {
      FloatingCatService.update(
        speedPercent: catSpeed,
        speedMessage: speedMessage,
        tasksJson: tasksJson,
        isCatWhite: isWhite,
        isDark: isDark,
      );
    }
  }
}
