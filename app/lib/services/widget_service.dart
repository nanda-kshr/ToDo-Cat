import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class WidgetService {
  static const String _summaryWidgetProvider = 'TodoCatWidgetProvider';
  static const String _listWidgetProvider = 'TodoCatListWidgetProvider';

  static Future<void> updateWidget({
    required int pendingCount,
    required int totalCount,
    required int speedPercent,
    required String speedMessage,
    bool? isDark,
    bool? isCatWhite,
    List<Task>? tasks,
    String? tasksJson,
  }) async {
    try {
      final saveFutures = <Future>[
        HomeWidget.saveWidgetData<int>('pending_count', pendingCount),
        HomeWidget.saveWidgetData<int>('total_count', totalCount),
        HomeWidget.saveWidgetData<int>('speed_percent', speedPercent),
        HomeWidget.saveWidgetData<String>('speed_message', speedMessage),
      ];

      if (isDark != null) {
        saveFutures.add(HomeWidget.saveWidgetData<bool>('is_dark', isDark));
      }
      if (isCatWhite != null) {
        saveFutures.add(HomeWidget.saveWidgetData<bool>('is_cat_white', isCatWhite));
      }

      await Future.wait(saveFutures);

      final prefs = await SharedPreferences.getInstance();
      if (isDark != null) await prefs.setBool('is_dark', isDark);
      if (isCatWhite != null) await prefs.setBool('is_cat_white', isCatWhite);

      final serialized = tasksJson ?? (tasks != null ? jsonEncode(tasks.map((t) => t.toJson()).toList()) : null);
      if (serialized != null) {
        await Future.wait([
          HomeWidget.saveWidgetData<String>('tasks_json', serialized),
          prefs.setString('tasks_json', serialized),
        ]);
      }

      await Future.wait([
        HomeWidget.updateWidget(
          name: _summaryWidgetProvider,
          androidName: _summaryWidgetProvider,
        ),
        HomeWidget.updateWidget(
          name: _listWidgetProvider,
          androidName: _listWidgetProvider,
        ),
      ]);
    } catch (_) {
      // Best-effort widget update
    }
  }

  static Future<bool> requestPinWidget({bool isCatWidget = false}) async {
    try {
      final isSupported = await HomeWidget.isRequestPinWidgetSupported();
      if (isSupported == true) {
        final provider = isCatWidget ? _summaryWidgetProvider : _listWidgetProvider;
        await HomeWidget.requestPinWidget(
          name: provider,
          androidName: provider,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
