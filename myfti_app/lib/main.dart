import 'package:flutter/material.dart';
import 'src/features/wallet/pages/home_page.dart';

void main() {
  runApp(const MyFTIApp());
}

class MyFTIApp extends StatelessWidget {
  const MyFTIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'myFTI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}