import 'package:flutter/material.dart';

import 'src/core/navigation/main_navigation.dart';
import 'src/features/authentication/pages/login_page.dart';
import 'src/features/authentication/pages/register_page.dart';
import 'src/features/authentication/pages/settings_page.dart';
import 'src/features/authentication/pages/splash_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFTI',
      debugShowCheckedModeBanner: false,
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