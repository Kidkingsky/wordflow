import 'package:flutter/material.dart';

import '../services/app_controller.dart';
import 'pages/explore_page.dart';
import 'pages/home_page.dart';
import 'pages/review_page.dart';
import 'pages/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.controller, super.key});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: _index,
              children: [
                HomePage(
                  controller: widget.controller,
                  onOpenTab: (index) => setState(() => _index = index),
                ),
                ExplorePage(controller: widget.controller),
                ReviewPage(controller: widget.controller),
                SettingsPage(controller: widget.controller),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.wb_sunny_outlined),
                selectedIcon: Icon(Icons.wb_sunny),
                label: '今日',
              ),
              const NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: '探索',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: widget.controller.dueItems.isNotEmpty,
                  child: const Icon(Icons.autorenew),
                ),
                selectedIcon: const Icon(Icons.autorenew),
                label: '複習',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: '我的',
              ),
            ],
          ),
        );
      },
    );
  }
}
