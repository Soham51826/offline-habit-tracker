import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  // Load environment variables securely (supports local .env and fresh clone .env.example)
  try {
    await dotenv.load(fileName: "assets/env/.env");
  } catch (_) {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      try {
        await dotenv.load(fileName: "assets/env/.env.example");
      } catch (e) {
        debugPrint('Environment initialized with default fallbacks: $e');
      }
    }
  }

  // Initialize Local Notifications
  await NotificationService.instance.initialize();

  // Initialize Android WorkManager
  await BackgroundWorkerService.instance.initialize();
  await BackgroundWorkerService.instance.schedulePeriodicHabitCheck();

  runApp(const HabitForgeApp());
}

class HabitForgeApp extends StatelessWidget {
  const HabitForgeApp({super.key});

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
        title: 'HabitForge',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const MainNavigationView(),
      ),
    );
  }
}
