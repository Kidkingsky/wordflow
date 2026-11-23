import 'package:flutter/material.dart';

import 'services/app_controller.dart';
import 'ui/app_shell.dart';
import 'ui/theme/wordflow_design.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.initialize();
  runApp(WordFlowApp(controller: controller));
}

class WordFlowApp extends StatelessWidget {
  const WordFlowApp({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WordFlow 每日英文',
        theme: WordFlowDesign.light,
        home: AppShell(controller: controller),
      );
}
