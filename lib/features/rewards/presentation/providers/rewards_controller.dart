import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecosphare/features/auth/presentation/providers/auth_controller.dart';
import 'package:ecosphare/features/rewards/data/reward_repository.dart';
import 'package:ecosphare/features/rewards/domain/reward.dart';

class RewardsState {
  final List<Reward> availableRewards;
  final List<Reward> userRewards;
  final bool isLoading;
  final String? error;

  const RewardsState({
    this.availableRewards = const [],
    this.userRewards = const [],
    this.isLoading = false,
    this.error,
  });

  RewardsState copyWith({
    List<Reward>? availableRewards,
    List<Reward>? userRewards,
    bool? isLoading,
    String? error,
  }) {
    return RewardsState(
      availableRewards: availableRewards ?? this.availableRewards,
      userRewards: userRewards ?? this.userRewards,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RewardsController extends StateNotifier<RewardsState> {
  final RewardRepository _repository;
  final String userId;

  RewardsController({
    required RewardRepository repository,
    required this.userId,
  })  : _repository = repository,
        super(const RewardsState()) {
    loadRewards();
  }

  Future<void> loadRewards() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final available = await _repository.getAvailableRewards();
      final userRewards = await _repository.getUserRewards(userId);
      
      state = state.copyWith(
        availableRewards: available,
        userRewards: userRewards,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> redeemReward(Reward reward) async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.redeemReward(userId: userId, reward: reward);
      await loadRewards(); // Reload to update lists and balance
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final rewardsControllerProvider = StateNotifierProvider<RewardsController, RewardsState>((ref) {
  final user = ref.watch(currentUserProvider);
  final repository = ref.watch(rewardRepositoryProvider);

  if (user == null) throw Exception('User not authenticated');

  return RewardsController(repository: repository, userId: user.uid);
});
