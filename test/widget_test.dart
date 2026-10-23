import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/ui/viewmodels/habit_viewmodel.dart';
import 'package:habit_tracker/ui/viewmodels/insights_viewmodel.dart';
import 'package:habit_tracker/ui/viewmodels/stats_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for local desktop/test database execution
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dotenv.loadFromString(envString: 'GEMINI_API_KEY=\nGOOGLE_MAPS_API_KEY=\n');
  });

  testWidgets('HabitForgeApp builds and displays navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HabitViewModel()),
          ChangeNotifierProvider(create: (_) => InsightsViewModel()),
          ChangeNotifierProvider(create: (_) => StatsViewModel()),
        ],
        child: const HabitForgeApp(),
      ),
    );

    await tester.pump();

    // Verify app title and navigation items exist
    expect(find.text('HabitForge'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
