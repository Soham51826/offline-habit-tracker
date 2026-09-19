import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'services/background_worker.dart';
import 'ui/core/app_theme.dart';
import 'ui/viewmodels/habit_viewmodel.dart';
import 'ui/viewmodels/insights_viewmodel.dart';
import 'ui/viewmodels/stats_viewmodel.dart';
import 'ui/views/main_navigation_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Notifications
  await NotificationService.instance.initialize();

  // Initialize Android WorkManager
  await BackgroundWorkerService.instance.initialize();
  await BackgroundWorkerService.instance.schedulePeriodicHabitCheck();

  runApp(const OfflineHabitTrackerApp());
}

class OfflineHabitTrackerApp extends StatelessWidget {
  const OfflineHabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HabitViewModel>(
          create: (_) => HabitViewModel(),
        ),
        ChangeNotifierProvider<InsightsViewModel>(
          create: (_) => InsightsViewModel(),
        ),
        ChangeNotifierProvider<StatsViewModel>(
          create: (_) => StatsViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Offline Habit Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainNavigationView(),
      ),
    );
  }
}
