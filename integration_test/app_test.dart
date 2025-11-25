import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecosphare/main.dart' as app;
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full App Flow: Onboarding -> Login -> Dashboard', (WidgetTester tester) async {
    // Initialize Hive for test
    await Hive.initFlutter();
    
    // Run the app
    app.main();
    await tester.pumpAndSettle();

    // 1. Verify Onboarding Screen
    expect(find.text('Track Your Impact'), findsOneWidget);
    
    // Tap Next
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    
    // Tap Next again
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    
    // Tap Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // 2. Verify Login Screen
    expect(find.text('Welcome Back'), findsOneWidget);
    
    // Enter Email
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    
    // Enter Password
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    
    // Tap Login
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // 3. Verify Profile Setup
    expect(find.text('Let\'s set up your profile'), findsOneWidget);
    
    // Tap Next (skip through profile setup for speed)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    // 4. Verify Dashboard
    expect(find.text('Eco Score'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
  });
}
