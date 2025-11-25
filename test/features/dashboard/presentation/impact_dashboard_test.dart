import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecosphare/features/dashboard/presentation/widgets/impact_dashboard.dart';
import 'package:ecosphare/features/dashboard/presentation/providers/dashboard_controller.dart';
import 'package:ecosphare/core/services/cache_service.dart';
import 'package:mockito/mockito.dart';

class MockCacheService extends Mock implements CacheService {
  @override
  Future<void> init() async {}
  
  @override
  Map<String, dynamic>? getDashboardData() => null;
  
  @override
  Future<void> saveDashboardData(Map<String, dynamic> data) async {}
}

void main() {
  testWidgets('ImpactDashboard renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cacheServiceProvider.overrideWithValue(MockCacheService()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ImpactDashboard()),
        ),
      ),
    );

    // Allow animations to complete
    await tester.pumpAndSettle();

    // Verify static text
    expect(find.text('Eco Score'), findsOneWidget);
    expect(find.text('Your Impact Breakdown'), findsOneWidget);
    expect(find.text('Suggested Actions'), findsOneWidget);

    // Verify score (default is 750)
    expect(find.text('750'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);

    // Verify breakdown categories
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.text('Diet'), findsOneWidget);
  });
}
