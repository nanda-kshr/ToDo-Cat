import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';

import '../models/runner.dart';
import '../models/task.dart';
import 'theme_service.dart';

class LinuxTrayService with TrayListener {
  static final LinuxTrayService instance = LinuxTrayService._();
  LinuxTrayService._();

  static const MethodChannel _windowChannel =
      MethodChannel('com.todocat.app/linux_window');

  static bool get isSupported => !kIsWeb && Platform.isLinux;

  Timer? _animTimer;
  int _frame = 0;
  int _totalFrames = 7;
  int _activeTasks = 0;
  String _speedMessage = '';
  List<Task> _tasks = [];
  bool _initialized = false;

  void Function(String taskId)? onTaskToggled;
  VoidCallback? onQuickAddRequested;
  VoidCallback? onShowWindow;
  void Function(RunnerType runner)? onRunnerChanged;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    _initialized = true;

    _updateRunnerFrames();

    trayManager.addListener(this);
    await _setTrayIcon(_frame);
    await _updateMenu();
    _startAnimation();
  }

  void _updateRunnerFrames() {
    final runnerName =
        ThemeService.instance.selectedRunner.value.name.toLowerCase();
    _totalFrames = runnerName.contains('bunny') ? 5 : 7;
  }

  void dispose() {
    if (!isSupported) return;
    _animTimer?.cancel();
    trayManager.removeListener(this);
    trayManager.destroy();
    _initialized = false;
  }

  Future<void> showWindow() async {
    if (!isSupported) return;
    try {
      await _windowChannel.invokeMethod('showWindow');
    } catch (_) {}
  }

  Future<void> hideWindow() async {
    if (!isSupported) return;
    try {
      await _windowChannel.invokeMethod('hideWindow');
    } catch (_) {}
  }

  Future<void> update({
    required int activeTasks,
    List<Task>? tasks,
    int? speedPercent,
    String? speedMessage,
  }) async {
    if (!isSupported || !_initialized) return;
    _activeTasks = activeTasks;
    if (tasks != null) _tasks = tasks;
    if (speedMessage != null) _speedMessage = speedMessage;
    _updateRunnerFrames();
    await _updateMenu();
  }

  void _startAnimation() {
    _animTimer?.cancel();
    _animTimer = Timer.periodic(const Duration(milliseconds: 150), (_) async {
      _frame = (_frame + 1) % _totalFrames;
      await _setTrayIcon(_frame);
    });
  }

  bool _isCatWhite() {
    final variant = ThemeService.instance.catColorVariant.value;
    if (variant == 'white') return true;
    if (variant == 'black') return false;
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final mode = ThemeService.instance.themeMode.value;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return brightness == Brightness.dark;
  }

  Future<void> _setTrayIcon(int frame) async {
    try {
      final runnerName =
          ThemeService.instance.selectedRunner.value.name.toLowerCase();
      final variant = _isCatWhite() ? '${runnerName}_white' : runnerName;
      final assetPath = 'assets/runners/$variant/run/$frame.png';

      final bytes = await rootBundle.load(assetPath);
      final tmpFile =
          File('${Directory.systemTemp.path}/todocat_tray_$frame.png');
      await tmpFile.writeAsBytes(bytes.buffer.asUint8List());
      await trayManager.setIcon(tmpFile.path);
    } catch (_) {}
  }

  Future<void> _updateMenu() async {
    final currentRunner = ThemeService.instance.selectedRunner.value;

    final headerText = _speedMessage.isNotEmpty
        ? 'TodoCat - $_activeTasks active ($_speedMessage)'
        : 'TodoCat - $_activeTasks active task${_activeTasks == 1 ? '' : 's'}';

    final items = <MenuItem>[
      MenuItem(
        key: 'header',
        label: headerText,
        disabled: true,
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'quick_add',
        label: '+ Add Task...',
      ),
      MenuItem.separator(),
    ];

    if (_tasks.isEmpty) {
      items.add(MenuItem(
        key: 'no_tasks',
        label: 'No tasks for today',
        disabled: true,
      ));
    } else {
      for (final task in _tasks.take(10)) {
        final title = task.title.length > 35
            ? '${task.title.substring(0, 32)}...'
            : task.title;
        items.add(MenuItem.checkbox(
          key: 'task_${task.id}',
          label: title,
          checked: task.completed,
        ));
      }
      if (_tasks.length > 10) {
        items.add(MenuItem(
          key: 'more_tasks',
          label: '+${_tasks.length - 10} more in app',
          disabled: true,
        ));
      }
    }

    items.addAll([
      MenuItem.separator(),
      MenuItem.submenu(
        key: 'companion_menu',
        label: 'Companion',
        submenu: Menu(items: [
          MenuItem.checkbox(
            key: 'runner_cat',
            label: 'Cat',
            checked: currentRunner == RunnerType.cat,
          ),
          MenuItem.checkbox(
            key: 'runner_bunny',
            label: 'Bunny',
            checked: currentRunner == RunnerType.bunny,
          ),
        ]),
      ),
      MenuItem.separator(),
      MenuItem(key: 'show', label: 'Open TodoCat'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit'),
    ]);

    await trayManager.setContextMenu(Menu(items: items));
  }

  @override
  void onTrayIconMouseDown() {
    showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final key = menuItem.key;
    if (key == null) return;

    if (key == 'quit') {
      exit(0);
    } else if (key == 'show') {
      showWindow();
      onShowWindow?.call();
    } else if (key == 'quick_add') {
      showWindow();
      onQuickAddRequested?.call();
    } else if (key == 'runner_cat') {
      ThemeService.instance.setSelectedRunner(RunnerType.cat);
      _updateRunnerFrames();
      onRunnerChanged?.call(RunnerType.cat);
      _updateMenu();
    } else if (key == 'runner_bunny') {
      ThemeService.instance.setSelectedRunner(RunnerType.bunny);
      _updateRunnerFrames();
      onRunnerChanged?.call(RunnerType.bunny);
      _updateMenu();
    } else if (key.startsWith('task_')) {
      final taskId = key.substring(5);
      onTaskToggled?.call(taskId);
    }
  }
}
