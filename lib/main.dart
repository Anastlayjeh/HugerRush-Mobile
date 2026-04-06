import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const HungerRushApp());
}

class HungerRushApp extends StatelessWidget {
  const HungerRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HungerRush',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8EFE8),
      ),
      home: const LoginScreen(),
    );
  }
}
