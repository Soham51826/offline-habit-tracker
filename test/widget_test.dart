import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/ui/viewmodels/auth_viewmodel.dart';
import 'package:habit_tracker/ui/views/auth/login_view.dart';
import 'package:habit_tracker/ui/views/auth/signup_view.dart';
import 'package:habit_tracker/ui/views/auth/title_view.dart';
import 'package:habit_tracker/ui/views/main_navigation_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for local desktop/test database execution
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dotenv.loadFromString(envString: 'GEMINI_API_KEY=\nGOOGLE_MAPS_API_KEY=\n');
    SharedPreferences.setMockInitialValues({'is_logged_in': true, 'user_name': 'Soham'});
  });

  testWidgets('HabitForgeApp builds and displays navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitForgeApp(home: MainNavigationView()));
    await tester.pump();

    // Verify navigation items exist on home dashboard
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('TitleView renders branding, features, and action buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ],
        child: const MaterialApp(home: TitleView()),
      ),
    );

    expect(find.text('HabitForge'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I Already Have an Account'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('LoginView renders email, password inputs, and quick demo login', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ],
        child: const MaterialApp(home: LoginView()),
      ),
    );

    expect(find.text('Welcome Back 👋'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Quick Demo Login (Soham)'), findsOneWidget);
  });

  testWidgets('SignUpView renders name, email, password, and create account button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ],
        child: const MaterialApp(home: SignUpView()),
      ),
    );

    expect(find.text('Create Account 🌿'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
