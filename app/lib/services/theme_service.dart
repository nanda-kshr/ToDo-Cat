import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._();
  ThemeService._();

  static const String _themePrefKey = 'theme_mode';
  static const String _catColorPrefKey = 'cat_color_variant';
  static const String _v2InitializedKey = 'theme_defaults_v2_set';

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  final ValueNotifier<String> catColorVariant = ValueNotifier<String>('auto'); // 'auto', 'white', 'black'

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isV2Set = prefs.getBool(_v2InitializedKey) ?? false;
      if (!isV2Set) {
        themeMode.value = ThemeMode.system;
        catColorVariant.value = 'auto';
        await prefs.setString(_themePrefKey, 'system');
        await prefs.setString(_catColorPrefKey, 'auto');
        await prefs.setBool(_v2InitializedKey, true);
        return;
      }

      final savedTheme = prefs.getString(_themePrefKey);
      if (savedTheme == 'light') {
        themeMode.value = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        themeMode.value = ThemeMode.dark;
      } else {
        themeMode.value = ThemeMode.system;
      }

      final savedCat = prefs.getString(_catColorPrefKey);
      if (savedCat == 'white') {
        catColorVariant.value = 'white';
      } else if (savedCat == 'black') {
        catColorVariant.value = 'black';
      } else {
        catColorVariant.value = 'auto';
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
              ? 'dark'
              : 'system';
      await prefs.setString(_themePrefKey, str);
    } catch (_) {}
  }

  Future<void> setCatColorVariant(String variant) async {
    catColorVariant.value = variant;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_catColorPrefKey, variant);
    } catch (_) {}
  }

  bool isDarkMode(BuildContext context) {
    if (themeMode.value == ThemeMode.dark) return true;
    if (themeMode.value == ThemeMode.light) return false;
    final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return platformBrightness == Brightness.dark;
  }

  bool isCatWhite(BuildContext context) {
    if (catColorVariant.value == 'white') return true;
    if (catColorVariant.value == 'black') return false;
    return isDarkMode(context);
  }
}
