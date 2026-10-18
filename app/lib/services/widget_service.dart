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
    List<Task>? tasks,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('pending_count', pendingCount);
      await HomeWidget.saveWidgetData<int>('total_count', totalCount);
      await HomeWidget.saveWidgetData<int>('speed_percent', speedPercent);
      await HomeWidget.saveWidgetData<String>('speed_message', speedMessage);

      if (tasks != null) {
        final tasksJson = jsonEncode(tasks.map((t) => t.toJson()).toList());
        await HomeWidget.saveWidgetData<String>('tasks_json', tasksJson);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tasks_json', tasksJson);
      }

      await HomeWidget.updateWidget(
        name: _summaryWidgetProvider,
        androidName: _summaryWidgetProvider,
      );

      await HomeWidget.updateWidget(
        name: _listWidgetProvider,
        androidName: _listWidgetProvider,
      );
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
