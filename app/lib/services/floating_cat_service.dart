import 'dart:io';
import 'package:flutter/services.dart';

class FloatingCatService {
  static const MethodChannel _channel =
      MethodChannel('com.todocat.app/floating_cat');

  static void Function(String tasksJson)? onTasksUpdated;
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTasksUpdated') {
        final args = call.arguments;
        if (args is Map) {
          final tasksJson = args['tasksJson'] as String?;
          if (tasksJson != null && onTasksUpdated != null) {
            onTasksUpdated!(tasksJson);
          }
        }
      }
    });
  }

  static bool get isSupported => Platform.isAndroid;

  static Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('hasOverlayPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  static Future<bool> start({
    required int speedPercent,
    required String speedMessage,
    String? tasksJson,
    bool? isCatWhite,
    bool? isDark,
  }) async {
    if (!isSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('startFloatingCat', {
        'speedPercent': speedPercent,
        'speedMessage': speedMessage,
        'tasksJson': ?tasksJson,
        'isCatWhite': ?isCatWhite,
        'isDark': ?isDark,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> update({
    required int speedPercent,
    required String speedMessage,
    String? tasksJson,
    bool? isCatWhite,
    bool? isDark,
  }) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('updateFloatingCat', {
        'speedPercent': speedPercent,
        'speedMessage': speedMessage,
        'tasksJson': ?tasksJson,
        'isCatWhite': ?isCatWhite,
        'isDark': ?isDark,
      });
    } catch (_) {}
  }

  static Future<void> stop() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('stopFloatingCat');
    } catch (_) {}
  }

  static Future<bool> isRunning() async {
    if (!isSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isFloatingCatRunning');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
