import 'dart:io';
import 'package:flutter/services.dart';
import '../models/runner.dart';
import 'theme_service.dart';

class MacMenuBarService {
  static const MethodChannel _channel =
      MethodChannel('com.todocat.app/macos_menu_bar');

  static bool _initialized = false;
  static void Function(RunnerType runner)? onRunnerChangedFromMenu;
  static void Function(String taskId)? onTaskToggledFromMenu;

  static bool get isSupported => Platform.isMacOS;

  static void initialize() {
    if (_initialized || !isSupported) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onRunnerSelectedFromMenu') {
        final args = call.arguments;
        if (args is Map) {
          final runnerStr = args['runner'] as String?;
          final runner = RunnerType.fromString(runnerStr);
          await ThemeService.instance.setSelectedRunner(runner);
          if (onRunnerChangedFromMenu != null) {
            onRunnerChangedFromMenu!(runner);
          }
        }
      } else if (call.method == 'onTaskToggledFromMenu') {
        final args = call.arguments;
        if (args is Map) {
          final taskId = args['taskId'] as String?;
          if (taskId != null && onTaskToggledFromMenu != null) {
            onTaskToggledFromMenu!(taskId);
          }
        }
      }
    });
  }

  static Future<void> update({
    required int speedPercent,
    required String speedMessage,
    required int activeCount,
    required int todayTotalCount,
    required String runner,
    required bool isWhite,
    required bool isDark,
    String? tasksJson,
  }) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('updateMenuBar', {
        'speedPercent': speedPercent,
        'speedMessage': speedMessage,
        'activeCount': activeCount,
        'todayTotalCount': todayTotalCount,
        'runner': runner,
        'isWhite': isWhite,
        'isDark': isDark,
        'isSleeping': activeCount <= 0 && speedPercent <= 0,
        'tasksJson': tasksJson,
      });
    } catch (_) {}
  }

  static Future<void> setEnabled(bool enabled) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('setEnabled', {'enabled': enabled});
    } catch (_) {}
  }

  static Future<bool> isEnabled() async {
    if (!isSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isEnabled');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> openWindow() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('openWindow');
    } catch (_) {}
  }
}
