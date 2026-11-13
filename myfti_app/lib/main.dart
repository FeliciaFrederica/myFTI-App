import 'package:flutter/material.dart';

import 'src/core/navigation/main_navigation.dart';
import 'src/features/authentication/pages/login_page.dart';
import 'src/features/authentication/pages/register_page.dart';
import 'src/features/authentication/pages/settings_page.dart';
import 'src/features/authentication/pages/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF673AB7);
    const secondary = Color(0xFF9575CD);
    const background = Color(0xFFF8F6FC);
    const textColor = Color(0xFF2D1B46);

    return MaterialApp(
      title: 'MyFTI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          error: const Color(0xFFE53935),
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: textColor,
              displayColor: textColor,
            ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => SplashScreen(),
        '/login': (_) => LoginScreen(),
        '/register': (_) => RegisterScreen(),
        '/home': (_) => const MainNavigation(),
        '/settings': (_) => SettingsScreen(),
      },
    );
  }
}