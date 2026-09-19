import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/insights_viewmodel.dart';
import 'dashboard_view.dart';
import 'insights_view.dart';
import 'analytics_view.dart';
import 'settings_view.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardView(),
    InsightsView(),
    AnalyticsView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final insightsVm = context.watch<InsightsViewModel>();
    final urgentCount = insightsVm.insights
        .where((i) => i.severity.name == 'urgent')
        .length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline_rounded),
            activeIcon: Icon(Icons.check_circle_rounded),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: urgentCount > 0,
              label: Text('$urgentCount'),
              backgroundColor: const Color(0xFFEF4444),
              child: const Icon(Icons.psychology_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: urgentCount > 0,
              label: Text('$urgentCount'),
              backgroundColor: const Color(0xFFEF4444),
              child: const Icon(Icons.psychology_rounded),
            ),
            label: 'Insights',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics_rounded),
            label: 'Analytics',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
