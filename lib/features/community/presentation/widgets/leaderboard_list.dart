import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/leaderboard_entry.dart';
import '../providers/leaderboard_controller.dart';
import '../screens/leaderboard_screen.dart';

class LeaderboardList extends ConsumerWidget {
  const LeaderboardList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardState = ref.watch(leaderboardControllerProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (leaderboardState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leaderboardState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load leaderboard',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(leaderboardControllerProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Default to XP leaderboard
    final entries = leaderboardState.xpLeaderboard;

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.leaderboard_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No rankings available yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Start logging activities to appear on the leaderboard!',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Find current user's entry
    LeaderboardEntry? userEntry;
    if (currentUser != null) {
      try {
        userEntry = entries.firstWhere((e) => e.userId == currentUser.uid);
      } catch (e) {
        // User not in top 50
      }
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(leaderboardControllerProvider.notifier).refresh(),
      child: Column(
        children: [
          // Header with tabs info
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top EcoWarriors',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to full leaderboard screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LeaderboardScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_full, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
          ),

          // User's own rank (if not in top 3)
          if (userEntry != null && userEntry.rank > 3) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: _buildLeaderboardTile(context, userEntry, true),
            ),
            const SizedBox(height: 16),
          ],

          // Top users list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: entries.length > 10 ? 10 : entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isCurrentUser =
                    currentUser != null && entry.userId == currentUser.uid;

                return _buildLeaderboardCard(context, entry, isCurrentUser);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(
    BuildContext context,
    LeaderboardEntry entry,
    bool isCurrentUser,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Special styling for top 3
    Color? cardColor;
    IconData? medalIcon;
    Color? medalColor;

    if (entry.rank == 1) {
      cardColor = colorScheme.tertiaryContainer;
      medalIcon = Icons.emoji_events;
      medalColor = const Color(0xFFFFD700); // Gold
    } else if (entry.rank == 2) {
      cardColor = colorScheme.secondaryContainer;
      medalIcon = Icons.emoji_events;
      medalColor = const Color(0xFFC0C0C0); // Silver
    } else if (entry.rank == 3) {
      cardColor = colorScheme.surfaceContainerHighest;
      medalIcon = Icons.emoji_events;
      medalColor = const Color(0xFFCD7F32); // Bronze
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCurrentUser
          ? colorScheme.primaryContainer
          : (cardColor ?? colorScheme.surface),
      elevation: entry.rank <= 3 ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildLeaderboardTile(context, entry, isCurrentUser,
            medalIcon: medalIcon, medalColor: medalColor),
      ),
    );
  }

  Widget _buildLeaderboardTile(
    BuildContext context,
    LeaderboardEntry entry,
    bool isCurrentUser, {
    IconData? medalIcon,
    Color? medalColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Rank or Medal
        SizedBox(
          width: 40,
          child: medalIcon != null
              ? Icon(medalIcon, color: medalColor, size: 32)
              : Text(
                  '#${entry.rank}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser
                            ? colorScheme.onPrimaryContainer
                            : null,
                      ),
                  textAlign: TextAlign.center,
                ),
        ),
        const SizedBox(width: 12),

        // Avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.primary,
          backgroundImage:
              entry.photoUrl != null ? NetworkImage(entry.photoUrl!) : null,
          child: entry.photoUrl == null
              ? Text(
                  entry.displayName.isNotEmpty
                      ? entry.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),

        // Name and Level
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser
                                ? colorScheme.onPrimaryContainer
                                : null,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: const Text('You'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimary,
                      ),
                      backgroundColor: colorScheme.primary,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
              Text(
                'Level ${entry.level}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isCurrentUser
                          ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),

        // Score
        Text(
          entry.formattedScore ?? entry.score.toStringAsFixed(0),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? colorScheme.onPrimaryContainer : null,
              ),
        ),
      ],
    );
  }
}
