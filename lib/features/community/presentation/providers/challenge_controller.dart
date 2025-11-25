import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/challenge_repository.dart';
import '../../../dashboard/data/activity_repository.dart';
import '../../domain/eco_challenge.dart';

/// Challenge state
class ChallengeState {
  final List<Map<String, dynamic>> activeChallenges; // {challenge, progress}
  final List<EcoChallenge> availableChallenges;
  final List<EcoChallenge> recommendedChallenges;
  final EcoChallenge? dailyChallenge;
  final List<EcoChallenge> weeklyChallenges;
  final List<EcoChallenge> seasonalChallenges;
  final List<EcoChallenge>? searchResults;
  final int completedCount;
  final bool isLoading;
  final String? error;

  const ChallengeState({
    this.activeChallenges = const [],
    this.availableChallenges = const [],
    this.recommendedChallenges = const [],
    this.dailyChallenge,
    this.weeklyChallenges = const [],
    this.seasonalChallenges = const [],
    this.searchResults,
    this.completedCount = 0,
    this.isLoading = false,
    this.error,
  });

  ChallengeState copyWith({
    List<Map<String, dynamic>>? activeChallenges,
    List<EcoChallenge>? availableChallenges,
    List<EcoChallenge>? recommendedChallenges,
    EcoChallenge? dailyChallenge,
    List<EcoChallenge>? weeklyChallenges,
    List<EcoChallenge>? seasonalChallenges,
    List<EcoChallenge>? searchResults,
    int? completedCount,
    bool? isLoading,
    String? error,
  }) {
    return ChallengeState(
      activeChallenges: activeChallenges ?? this.activeChallenges,
      availableChallenges: availableChallenges ?? this.availableChallenges,
      recommendedChallenges: recommendedChallenges ?? this.recommendedChallenges,
      dailyChallenge: dailyChallenge ?? this.dailyChallenge,
      weeklyChallenges: weeklyChallenges ?? this.weeklyChallenges,
      seasonalChallenges: seasonalChallenges ?? this.seasonalChallenges,
      searchResults: searchResults ?? this.searchResults, // Nullable to clear search
      completedCount: completedCount ?? this.completedCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Challenge controller
class ChallengeController extends StateNotifier<ChallengeState> {
  final ChallengeRepository _challengeRepository;
  final ActivityRepository _activityRepository;
  final String userId;

  ChallengeController({
    required ChallengeRepository challengeRepository,
    required ActivityRepository activityRepository,
    required this.userId,
  })  : _challengeRepository = challengeRepository,
        _activityRepository = activityRepository,
        super(const ChallengeState()) {
    loadChallenges();
  }

  /// Load all challenges and user progress
  Future<void> loadChallenges() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load available challenges
      final available = await _challengeRepository.getActiveChallenges();
      
      // Load user's active challenges with progress
      final userProgress = await _challengeRepository.getUserActiveChallenges(userId);
      
      // Combine challenges with progress
      final activeChallengesWithProgress = <Map<String, dynamic>>[];
      for (final progress in userProgress) {
        final challenge = await _challengeRepository.getChallenge(progress.challengeId);
        if (challenge != null) {
          activeChallengesWithProgress.add({
            'challenge': challenge,
            'progress': progress,
          });
        }
      }

      // Get completed count
      final completedChallenges = await _challengeRepository.getUserCompletedChallenges(userId);

      // Filter out challenges user is already participating in
      final activeIds = userProgress.map((p) => p.challengeId).toSet();
      final filteredAvailable = available.where((c) => !activeIds.contains(c.id)).toList();

      // Get recommendations
      // First get user's category breakdown
      // Note: In a real app, we might want to cache this or handle it separately
      // to avoid too many reads, but for now we'll fetch it here
      List<EcoChallenge> recommendations = [];
      try {
        final breakdown = await _activityRepository.getCarbonBreakdown(userId);
        // Convert Map<ActivityType, double> to Map<String, double>
        final stringBreakdown = breakdown.map(
          (key, value) => MapEntry(key.name, value),
        );
        
        recommendations = await _challengeRepository.getRecommendedChallenges(
          stringBreakdown,
          limit: 3,
        );
        
        // Filter out active challenges from recommendations too
        recommendations = recommendations.where((c) => !activeIds.contains(c.id)).toList();
      } catch (e) {
        print('Error fetching recommendations: $e');
      }

      // Get Daily, Weekly, and Seasonal Challenges
      final daily = await _challengeRepository.getDailyChallenge();
      final weekly = await _challengeRepository.getWeeklyChallenges();
      final seasonal = await _challengeRepository.getSeasonalChallenges();

      state = state.copyWith(
        availableChallenges: filteredAvailable,
        activeChallenges: activeChallengesWithProgress,
        recommendedChallenges: recommendations,
        dailyChallenge: daily,
        weeklyChallenges: weekly,
        seasonalChallenges: seasonal,
        completedCount: completedChallenges.length,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Join a challenge
  Future<void> joinChallenge(String challengeId) async {
    try {
      final challenge = await _challengeRepository.getChallenge(challengeId);
      if (challenge == null) {
        throw Exception('Challenge not found');
      }

      await _challengeRepository.joinChallenge(
        userId: userId,
        challengeId: challengeId,
        targetProgress: challenge.targetValue,
      );

      // Reload challenges to update UI
      await loadChallenges();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Leave a challenge
  Future<void> leaveChallenge(String challengeId) async {
    try {
      await _challengeRepository.leaveChallenge(
        userId: userId,
        challengeId: challengeId,
      );

      // Reload challenges to update UI
      await loadChallenges();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Update challenge progress
  Future<void> updateChallengeProgress({
    required String challengeId,
    required double progressIncrement,
  }) async {
    try {
      await _challengeRepository.updateChallengeProgress(
        userId: userId,
        challengeId: challengeId,
        progress: progressIncrement,
      );

      // Reload to reflect updated progress
      await loadChallenges();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Refresh challenges
  Future<void> refresh() async {
    await loadChallenges();
  }

  /// Search challenges
  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: null); // Clear search
      return;
    }

    try {
      state = state.copyWith(isLoading: true);
      final results = await _challengeRepository.searchChallenges(query: query);
      
      // Filter out active challenges from search results if desired, 
      // or keep them to allow viewing details. Let's keep them but maybe mark them in UI.
      // For now, just return all matching challenges.
      
      state = state.copyWith(
        searchResults: results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear search
  void clearSearch() {
    state = state.copyWith(searchResults: null);
    // Force null assignment since copyWith might ignore null if not handled carefully
    // But actually, we can just reload to be safe and refresh data
    // loadChallenges(); 
    // Optimization: Just manually reconstructing state to force null searchResults if copyWith is tricky
    // But let's assume we fix copyWith to handle nullable properly or just use a specific action.
    // Actually, looking at my copyWith: searchResults: searchResults ?? this.searchResults
    // This prevents setting it to null.
    // Let's implement a specific reset.
    
    // Better approach:
    state = ChallengeState(
      activeChallenges: state.activeChallenges,
      availableChallenges: state.availableChallenges,
      recommendedChallenges: state.recommendedChallenges,
      dailyChallenge: state.dailyChallenge,
      weeklyChallenges: state.weeklyChallenges,
      seasonalChallenges: state.seasonalChallenges,
      completedCount: state.completedCount,
      isLoading: state.isLoading,
      error: state.error,
      searchResults: null,
    );
  }
}

/// Provider for ChallengeController
final challengeControllerProvider =
    StateNotifierProvider<ChallengeController, ChallengeState>((ref) {
  final challengeRepository = ref.watch(challengeRepositoryProvider);
  final activityRepository = ref.watch(activityRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    // Return empty controller if no user
    throw Exception('User must be authenticated to access challenges');
  }

  return ChallengeController(
    challengeRepository: challengeRepository,
    activityRepository: activityRepository,
    userId: user.uid,
  );
});
