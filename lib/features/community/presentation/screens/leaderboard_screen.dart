import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/leaderboard_entry.dart';
import '../providers/leaderboard_controller.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardState = ref.watch(leaderboardControllerProvider);
    final currentUser = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'XP Rankings', icon: Icon(Icons.star)),
            Tab(text: 'Carbon Saved', icon: Icon(Icons.eco)),
          ],
        ),
      ),
      body: leaderboardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : leaderboardState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load leaderboard',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        leaderboardState.error!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(leaderboardControllerProvider.notifier)
                            .refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaderboardList(
                      context,
                      leaderboardState.xpLeaderboard,
                      currentUser,
                      false,
                    ),
                    _buildLeaderboardList(
                      context,
                      leaderboardState.carbonLeaderboard,
                      currentUser,
                      true,
                    ),
                  ],
                ),
    );
  }

  Widget _buildLeaderboardList(
    BuildContext context,
    List<LeaderboardEntry> entries,
    dynamic currentUser,
    bool isCarbonLeaderboard,
  ) {
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
          // User's own rank (if not in top 3)
          if (userEntry != null && userEntry.rank > 3) ...[
            Container(
              margin: const EdgeInsets.all(16),
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
          ],

          // Top users list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
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
