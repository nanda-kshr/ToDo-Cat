import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupService {
  static final StartupService instance = StartupService._internal();
  StartupService._internal();

  static const String prefKey = 'pref_launch_on_startup';
  static const MethodChannel _macChannel =
      MethodChannel('com.todocat.app/macos_menu_bar');

  @visibleForTesting
  static MethodChannel macChannel = _macChannel;

  @visibleForTesting
  static File? testLinuxDesktopFile;

  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isLinux;
  }

  File _getLinuxDesktopFile() {
    if (testLinuxDesktopFile != null) return testLinuxDesktopFile!;
    final home = Platform.environment['HOME'] ?? '';
    return File('$home/.config/autostart/todocat.desktop');
  }

  String _getLinuxExecPath() {
    final appImage = Platform.environment['APPIMAGE'];
    if (appImage != null && appImage.isNotEmpty) {
      return appImage;
    }
    return Platform.resolvedExecutable;
  }

  Future<bool> isEnabled() async {
    if (!isSupported) return false;

    try {
      if (Platform.isMacOS) {
        final res = await macChannel.invokeMethod<bool>('isLaunchAtStartupEnabled');
        if (res != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(prefKey, res);
          return res;
        }
      } else if (Platform.isLinux) {
        final file = _getLinuxDesktopFile();
        final exists = file.existsSync();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(prefKey, exists);
        return exists;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKey) ?? false;
  }

  Future<bool> setEnabled(bool enabled) async {
    if (!isSupported) return false;

    bool success = false;
    try {
      if (Platform.isMacOS) {
        final res = await macChannel.invokeMethod<bool>(
          'setLaunchAtStartup',
          {'enabled': enabled},
        );
        success = res ?? false;
      } else if (Platform.isLinux) {
        final file = _getLinuxDesktopFile();
        if (enabled) {
          if (!file.parent.existsSync()) {
            await file.parent.create(recursive: true);
          }
          final exec = _getLinuxExecPath();
          final content = '''[Desktop Entry]
Type=Application
Version=1.0
Name=TodoCat
Comment=Visual task management app
Exec=$exec
Icon=todocat
Terminal=false
StartupNotify=false
Categories=Utility;Office;
''';
          await file.writeAsString(content);
          success = true;
        } else {
          if (file.existsSync()) {
            await file.delete();
          }
          success = true;
        }
      }
    } catch (_) {
      success = false;
    }

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, enabled);
    }

    return success;
  }
}
