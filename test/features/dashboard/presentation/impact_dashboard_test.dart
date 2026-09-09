import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ecosphare/features/auth/domain/user.dart';
import 'package:ecosphare/features/dashboard/data/activity_repository.dart';
import 'package:ecosphare/features/dashboard/domain/user_activity.dart';
import 'package:ecosphare/features/dashboard/presentation/providers/dashboard_controller.dart';
import 'package:ecosphare/features/dashboard/presentation/widgets/impact_dashboard.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _FakeActivityRepository extends ActivityRepository {
  _FakeActivityRepository() : super(firestore: _MockFirestore());
}

final AppUser _testUser = AppUser(
  uid: 'test-user',
  email: 'test@example.com',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

const DashboardState _fixedState = DashboardState(
  ecoScore: 750,
  breakdown: {
    ActivityType.transport: 8.0,
    ActivityType.diet: 11.0,
    ActivityType.energy: 13.0,
  },
);

class _FakeDashboardController extends DashboardController {
  _FakeDashboardController()
      : super(
          activityRepository: _FakeActivityRepository(),
          currentUser: _testUser,
        );

  @override
  Future<void> loadDashboardData() async {
    state = _fixedState;
  }
}

void main() {
  testWidgets('ImpactDashboard renders the score, breakdown, and actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            (ref) => _FakeDashboardController(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ImpactDashboard()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Eco Score'), findsOneWidget);
    expect(find.text('750'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
    expect(find.text('Your Impact Breakdown'), findsOneWidget);
    expect(find.text('Suggested Actions'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.text('Diet'), findsOneWidget);
  });
}
