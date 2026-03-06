import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/features/dashboard/presentation/overview_tab.dart';
import 'package:inflabasket/features/dashboard/presentation/history_tab.dart';
import 'package:inflabasket/features/dashboard/presentation/categories_tab.dart';
import 'package:inflabasket/features/settings/presentation/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InflaBasket')),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          OverviewTab(),
          HistoryTab(),
          CategoriesTab(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/home/add'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
