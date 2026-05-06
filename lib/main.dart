import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiConfig.validate();
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
      home: const AppShell(),
    );
  }
}
