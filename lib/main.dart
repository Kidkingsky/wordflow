import 'package:flutter/material.dart';
import 'services/app_controller.dart';
import 'ui/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.initialize();
  runApp(WordFlowApp(controller: controller));
}

class WordFlowApp extends StatelessWidget {
  const WordFlowApp({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    const deepNavy = Color(0xFF152839);
    const primary = Color(0xFF167F83);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WordFlow 每日英文',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: deepNavy,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F9FA),
          foregroundColor: deepNavy,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          height: 72,
          indicatorColor: const Color(0xFFDDF2EE),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Color(0xFF8F9CA5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: AppShell(controller: controller),
    );
  }
}
