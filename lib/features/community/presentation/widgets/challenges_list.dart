import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/eco_challenge.dart';
import '../providers/challenge_controller.dart';
import 'challenge_card.dart';

class ChallengesList extends ConsumerStatefulWidget {
  const ChallengesList({super.key});

  @override
  ConsumerState<ChallengesList> createState() => _ChallengesListState();
}

class _ChallengesListState extends ConsumerState<ChallengesList> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengeState = ref.watch(challengeControllerProvider);

    if (challengeState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (challengeState.error != null) {
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
              'Error loading challenges',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              challengeState.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(challengeControllerProvider.notifier).loadChallenges(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search challenges...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(challengeControllerProvider.notifier).clearSearch();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            onChanged: (value) {
              setState(() {}); // Update UI for clear button
              // Debounce could be added here
              ref.read(challengeControllerProvider.notifier).search(value);
            },
          ),
          const SizedBox(height: 16),

          // Search Results
          if (challengeState.searchResults != null) ...[
            Text(
              'Search Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (challengeState.searchResults!.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No challenges found matching your search.'),
                ),
              )
            else
              ...challengeState.searchResults!.map((challenge) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChallengeCard(
                    challenge: challenge,
                    isActive: false,
                  ),
                );
              }),
          ] else ...[
            // Stats card
            _buildStatsCard(context, challengeState),
            const SizedBox(height: 24),

            // Seasonal Events Section
            if (challengeState.seasonalChallenges.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.celebration,
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Seasonal Events',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onTertiaryContainer,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...challengeState.seasonalChallenges.map((challenge) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChallengeCard(
                          challenge: challenge,
                          isActive: false,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Daily Challenge Section
            if (challengeState.dailyChallenge != null) ...[
              Text(
                'Daily Challenge',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 12),
              ChallengeCard(
                challenge: challengeState.dailyChallenge!,
                isActive: false, // Or check if user joined
              ),
              const SizedBox(height: 24),
            ],

            // Weekly Challenges Section
            if (challengeState.weeklyChallenges.isNotEmpty) ...[
              Text(
                'Weekly Challenges',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: challengeState.weeklyChallenges.length,
                  itemBuilder: (context, index) {
                    final challenge = challengeState.weeklyChallenges[index];
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 12),
                      child: ChallengeCard(
                        challenge: challenge,
                        isActive: false,
                        compact: true,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Active challenges section
            if (challengeState.activeChallenges.isNotEmpty) ...[
              Text(
                'Active Challenges',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...challengeState.activeChallenges.map((challengeWithProgress) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChallengeCard(
                    challenge: challengeWithProgress['challenge'] as EcoChallenge,
                    progress: challengeWithProgress['progress'] as ChallengeProgress?,
                    isActive: true,
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Recommended Challenges
            if (challengeState.recommendedChallenges.isNotEmpty) ...[
              Text(
                'Recommended for You',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180, // Height for horizontal scrolling cards
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: challengeState.recommendedChallenges.length,
                  itemBuilder: (context, index) {
                    final challenge = challengeState.recommendedChallenges[index];
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 12),
                      child: ChallengeCard(
                        challenge: challenge,
                        isActive: false,
                        compact: true, // Assuming we might want a compact version
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Available challenges section
            Text(
              'All Challenges',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            if (challengeState.availableChallenges.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No challenges available',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new challenges!',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...challengeState.availableChallenges.map((challenge) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChallengeCard(
                    challenge: challenge,
                    isActive: false,
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, ChallengeState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              'Active',
              state.activeChallenges.length.toString(),
              Icons.play_circle_outline,
            ),
            Container(
              width: 1,
              height: 40,
              color: colorScheme.outline.withOpacity(0.3),
            ),
            _buildStatItem(
              context,
              'Completed',
              state.completedCount.toString(),
              Icons.check_circle_outline,
            ),
            Container(
              width: 1,
              height: 40,
              color: colorScheme.outline.withOpacity(0.3),
            ),
            _buildStatItem(
              context,
              'Available',
              state.availableChallenges.length.toString(),
              Icons.explore_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
        ),
      ],
    );
  }
}
