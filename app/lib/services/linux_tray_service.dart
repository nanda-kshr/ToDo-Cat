import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';

import 'theme_service.dart';

class LinuxTrayService with TrayListener {
  static final LinuxTrayService instance = LinuxTrayService._();
  LinuxTrayService._();

  static bool get isSupported => !kIsWeb && Platform.isLinux;

  Timer? _animTimer;
  int _frame = 0;
  int _totalFrames = 7;
  int _activeTasks = 0;
  bool _initialized = false;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    _initialized = true;

    final runnerName = ThemeService.instance.selectedRunner.value.name.toLowerCase();
    _totalFrames = runnerName.contains('bunny') ? 5 : 7;

    trayManager.addListener(this);
    await _setTrayIcon(_frame);
    await _updateMenu();
    _startAnimation();
  }

  void dispose() {
    if (!isSupported) return;
    _animTimer?.cancel();
    trayManager.removeListener(this);
    trayManager.destroy();
    _initialized = false;
  }

  Future<void> update({required int activeTasks}) async {
    if (!isSupported || !_initialized) return;
    _activeTasks = activeTasks;
    // Update frame count if runner changed
    final runnerName = ThemeService.instance.selectedRunner.value.name.toLowerCase();
    _totalFrames = runnerName.contains('bunny') ? 5 : 7;
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
    // 'auto' — follow system theme
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final mode = ThemeService.instance.themeMode.value;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return brightness == Brightness.dark;
  }

  Future<void> _setTrayIcon(int frame) async {
    try {
      final runnerName = ThemeService.instance.selectedRunner.value.name.toLowerCase();
      final variant = _isCatWhite() ? '${runnerName}_white' : runnerName;
      final assetPath = 'assets/runners/$variant/run/$frame.png';

      final bytes = await rootBundle.load(assetPath);
      final tmpFile = File('${Directory.systemTemp.path}/todocat_tray_$frame.png');
      await tmpFile.writeAsBytes(bytes.buffer.asUint8List());
      await trayManager.setIcon(tmpFile.path);
    } catch (_) {
      // Silently ignore icon update failures (e.g. tray not available)
    }
  }

  Future<void> _updateMenu() async {
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(
        key: 'active_count',
        label: '$_activeTasks active task${_activeTasks == 1 ? '' : 's'}',
        disabled: true,
      ),
      MenuItem.separator(),
      MenuItem(key: 'show', label: 'Show TodoCat'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit'),
    ]));
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'quit') exit(0);
  }
}
