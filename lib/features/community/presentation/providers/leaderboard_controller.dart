import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/leaderboard_repository.dart';
import '../../domain/leaderboard_entry.dart';

/// State for the LeaderboardController
class LeaderboardState {
  final List<LeaderboardEntry> xpLeaderboard;
  final List<LeaderboardEntry> carbonLeaderboard;
  final bool isLoading;
  final String? error;

  const LeaderboardState({
    this.xpLeaderboard = const [],
    this.carbonLeaderboard = const [],
    this.isLoading = false,
    this.error,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? xpLeaderboard,
    List<LeaderboardEntry>? carbonLeaderboard,
    bool? isLoading,
    String? error,
  }) {
    return LeaderboardState(
      xpLeaderboard: xpLeaderboard ?? this.xpLeaderboard,
      carbonLeaderboard: carbonLeaderboard ?? this.carbonLeaderboard,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Controller for managing leaderboard state
class LeaderboardController extends StateNotifier<LeaderboardState> {
  final LeaderboardRepository _repository;

  LeaderboardController({required LeaderboardRepository repository})
      : _repository = repository,
        super(const LeaderboardState()) {
    loadLeaderboards();
  }

  /// Load both leaderboards
  Future<void> loadLeaderboards() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final xpList = await _repository.getTopUsersByXp();
      final carbonList = await _repository.getTopUsersByCarbon();

      state = state.copyWith(
        xpLeaderboard: xpList,
        carbonLeaderboard: carbonList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh leaderboards
  Future<void> refresh() async {
    await loadLeaderboards();
  }
}

/// Provider for LeaderboardController
final leaderboardControllerProvider =
    StateNotifierProvider<LeaderboardController, LeaderboardState>((ref) {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return LeaderboardController(repository: repository);
});
