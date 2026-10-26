import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'presentation/screens/home_screen.dart';
import 'services/theme_service.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.instance.init();
  await FcmService().initialize();
  runApp(const TodoCatApp());
}

class TodoCatApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const TodoCatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, currentMode, _) {
        final pageTransitions = PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          },
        );

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'TodoCat',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            fontFamily: 'Sniglet',
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.light.background,
            colorScheme: ColorScheme.light(
              primary: AppColors.light.textPrimary,
              onPrimary: AppColors.light.background,
              surface: AppColors.light.surface,
              onSurface: AppColors.light.textPrimary,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.light.background,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.light.appTitle),
              titleTextStyle: TextStyle(
                fontFamily: 'Sniglet',
                color: AppColors.light.appTitle,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardColor: AppColors.light.surface,
            dividerColor: AppColors.light.divider,
            pageTransitionsTheme: pageTransitions,
          ),
          darkTheme: ThemeData(
            fontFamily: 'Sniglet',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.dark.background,
            colorScheme: ColorScheme.dark(
              primary: AppColors.dark.textPrimary,
              onPrimary: AppColors.dark.background,
              surface: AppColors.dark.surface,
              onSurface: AppColors.dark.textPrimary,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.dark.background,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.dark.appTitle),
              titleTextStyle: TextStyle(
                fontFamily: 'Sniglet',
                color: AppColors.dark.appTitle,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardColor: AppColors.dark.surface,
            dividerColor: AppColors.dark.divider,
            pageTransitionsTheme: pageTransitions,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
