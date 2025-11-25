import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecosphare/features/rewards/domain/reward.dart';
import 'package:ecosphare/features/rewards/presentation/providers/rewards_controller.dart';
import 'package:ecosphare/features/auth/presentation/providers/auth_controller.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsState = ref.watch(rewardsControllerProvider);
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Store'),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${user?.points ?? 0} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: rewardsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Store'),
                      Tab(text: 'My Rewards'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildStoreTab(context, ref, rewardsState),
                        _buildMyRewardsTab(context, rewardsState),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStoreTab(
    BuildContext context,
    WidgetRef ref,
    RewardsState state,
  ) {
    if (state.availableRewards.isEmpty) {
      return const Center(child: Text('No rewards available right now.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.availableRewards.length,
      itemBuilder: (context, index) {
        final reward = state.availableRewards[index];
        return _buildRewardCard(context, ref, reward, isStore: true);
      },
    );
  }

  Widget _buildMyRewardsTab(BuildContext context, RewardsState state) {
    if (state.userRewards.isEmpty) {
      return const Center(child: Text('You haven\'t redeemed any rewards yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.userRewards.length,
      itemBuilder: (context, index) {
        final reward = state.userRewards[index];
        return _buildRewardCard(context, null, reward, isStore: false);
      },
    );
  }

  Widget _buildRewardCard(
    BuildContext context,
    WidgetRef? ref,
    Reward reward, {
    required bool isStore,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder (or actual image if we had network images)
          Container(
            height: 120,
            width: double.infinity,
            color: colorScheme.surfaceContainerHighest,
            child: Center(
              child: Icon(
                _getRewardIcon(reward.type),
                size: 48,
                color: colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        reward.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (isStore)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${reward.cost} pts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reward.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (isStore) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _confirmRedemption(context, ref!, reward),
                      child: const Text('Redeem'),
                    ),
                  ),
                ] else if (reward.code != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Code: ${reward.code}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.copy, size: 20, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.virtual_item:
        return Icons.palette;
      case RewardType.real_world:
        return Icons.local_offer;
      case RewardType.donation:
        return Icons.volunteer_activism;
    }
  }

  void _confirmRedemption(
    BuildContext context,
    WidgetRef ref,
    Reward reward,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Reward'),
        content: Text(
          'Are you sure you want to redeem "${reward.title}" for ${reward.cost} points?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(rewardsControllerProvider.notifier)
                    .redeemReward(reward);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reward redeemed successfully!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
