import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/domain/user.dart';
import '../../data/activity_repository.dart';
import '../../domain/user_activity.dart';
import '../../domain/emission_factors.dart';
import '../../../../core/services/gamification_integration_service.dart';

/// Dashboard state
class DashboardState {
  final List<UserActivity> activities;
  final Map<ActivityType, double> breakdown;
  final double totalCarbonImpact;
  final double todayImpact;
  final double weekImpact;
  final double monthImpact;
  final double ecoScore;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.activities = const [],
    this.breakdown = const {},
    this.totalCarbonImpact = 0.0,
    this.todayImpact = 0.0,
    this.weekImpact = 0.0,
    this.monthImpact = 0.0,
    this.ecoScore = 500.0,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    List<UserActivity>? activities,
    Map<ActivityType, double>? breakdown,
    double? totalCarbonImpact,
    double? todayImpact,
    double? weekImpact,
    double? monthImpact,
    double? ecoScore,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      activities: activities ?? this.activities,
      breakdown: breakdown ?? this.breakdown,
      totalCarbonImpact: totalCarbonImpact ?? this.totalCarbonImpact,
      todayImpact: todayImpact ?? this.todayImpact,
      weekImpact: weekImpact ?? this.weekImpact,
      monthImpact: monthImpact ?? this.monthImpact,
      ecoScore: ecoScore ?? this.ecoScore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Dashboard controller
class DashboardController extends StateNotifier<DashboardState> {
  final ActivityRepository _activityRepository;
  final GamificationIntegrationService? _gamificationService;
  final AppUser currentUser;

  DashboardController({
    required ActivityRepository activityRepository,
    required this.currentUser,
    GamificationIntegrationService? gamificationService,
  })  : _activityRepository = activityRepository,
        _gamificationService = gamificationService,
        super(const DashboardState()) {
    loadDashboardData();
  }

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get this week's date range
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

      // Get this month's date range
      final monthStart = DateTime(now.year, now.month, 1);

      // Fetch data in parallel
      final results = await Future.wait([
        _activityRepository.getUserActivities(currentUser.uid),
        _activityRepository.getCarbonBreakdown(currentUser.uid),
        _activityRepository.getTotalCarbonImpact(currentUser.uid),
        _activityRepository.getCarbonImpactByDateRange(
          userId: currentUser.uid,
          startDate: todayStart,
          endDate: todayEnd,
        ),
        _activityRepository.getCarbonImpactByDateRange(
          userId: currentUser.uid,
          startDate: weekStart,
          endDate: todayEnd,
        ),
        _activityRepository.getCarbonImpactByDateRange(
          userId: currentUser.uid,
          startDate: monthStart,
          endDate: todayEnd,
        ),
      ]);

      final activities = results[0] as List<UserActivity>;
      final breakdown = results[1] as Map<ActivityType, double>;
      final totalImpact = results[2] as double;
      final todayImpact = results[3] as double;
      final weekImpact = results[4] as double;
      final monthImpact = results[5] as double;

      // Calculate eco score based on daily average
      final daysWithActivities = activities.isNotEmpty
          ? now.difference(activities.last.timestamp).inDays + 1
          : 1;
      final dailyAverage = totalImpact / daysWithActivities;
      final ecoScore = CarbonCalculator.toEcoScore(dailyAverage);

      state = state.copyWith(
        activities: activities,
        breakdown: breakdown,
        totalCarbonImpact: totalImpact,
        todayImpact: todayImpact,
        weekImpact: weekImpact,
        monthImpact: monthImpact,
        ecoScore: ecoScore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add new activity
  Future<Map<String, dynamic>?> addActivity(UserActivity activity) async {
    try {
      await _activityRepository.createActivity(activity);
      
      // Process gamification if service is available
      Map<String, dynamic>? gamificationResults;
      if (_gamificationService != null) {
        try {
          gamificationResults = await _gamificationService.processActivityLogged(
            userId: currentUser.uid,
            activity: activity,
            currentUser: currentUser,
          );
        } catch (e) {
          // Don't fail activity logging if gamification fails
          print('Gamification processing failed: $e');
        }
      }
      
      // Reload dashboard data
      await loadDashboardData();
      
      return gamificationResults;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Delete activity
  Future<void> deleteActivity(String activityId) async {
    try {
      await _activityRepository.deleteActivity(activityId);
      
      // Reload dashboard data
      await loadDashboardData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Refresh dashboard
  Future<void> refresh() async {
    await loadDashboardData();
  }

  /// Quick log activity from preset
  Future<Map<String, dynamic>?> quickLog(int presetIndex) async {
    try {
      final activity = QuickLogPresets.createFromPreset(presetIndex, currentUser.uid);
      return await addActivity(activity);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

/// Provider for DashboardController
final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final user = ref.watch(currentUserProvider);
  final activityRepository = ref.watch(activityRepositoryProvider);
  
  // Optional: Add gamification service
  GamificationIntegrationService? gamificationService;
  try {
    gamificationService = ref.watch(gamificationIntegrationServiceProvider);
  } catch (e) {
    // Gamification service not available, continue without it
  }

  if (user == null) {
    throw Exception('User not authenticated');
  }

  return DashboardController(
    activityRepository: activityRepository,
    currentUser: user,
    gamificationService: gamificationService,
  );
});

/// Provider for activity stream
final activitiesStreamProvider = StreamProvider<List<UserActivity>>((ref) {
  final user = ref.watch(currentUserProvider);
  final activityRepository = ref.watch(activityRepositoryProvider);

  if (user == null) {
    return Stream.value([]);
  }

  return activityRepository.watchUserActivities(user.uid);
});
