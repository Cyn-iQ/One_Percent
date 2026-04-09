import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GrowthSystemApp());
}

class GrowthSystemApp extends StatelessWidget {
  const GrowthSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AppRepository();

    return MaterialApp(
      title: '成长系统',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: HomeScreen(repository: repository),
    );
  }
}