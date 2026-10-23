import 'package:flutter/material.dart';
import 'presentation/screens/home_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.instance.init();
  runApp(const TodoCatApp());
}

class TodoCatApp extends StatelessWidget {
  const TodoCatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, currentMode, _) {
        final pageTransitions = PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        );

        return MaterialApp(
          title: 'TodoCat',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            fontFamily: 'Sniglet',
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF9FAFB),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4B5563),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF4B5563),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF4B5563)),
              titleTextStyle: TextStyle(
                fontFamily: 'Sniglet',
                color: Color(0xFF4B5563),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardColor: Colors.white,
            dividerColor: const Color(0xFFE5E7EB),
            pageTransitionsTheme: pageTransitions,
          ),
          darkTheme: ThemeData(
            fontFamily: 'Sniglet',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A0A0A),
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Color(0xFF0A0A0A),
              surface: Color(0xFF171717),
              onSurface: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0A0A0A),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                fontFamily: 'Sniglet',
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardColor: const Color(0xFF171717),
            dividerColor: const Color(0xFF262626),
            pageTransitionsTheme: pageTransitions,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
