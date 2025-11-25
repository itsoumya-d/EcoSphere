import 'package:flutter/material.dart';

/// Widget displaying user statistics in a card layout
class UserStatsCard extends StatelessWidget {
  final double totalCarbonSaved;
  final int totalActivitiesLogged;
  final int challengesCompleted;
  final int currentStreak;

  const UserStatsCard({
    super.key,
    required this.totalCarbonSaved,
    required this.totalActivitiesLogged,
    required this.challengesCompleted,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Impact',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            
            // Stats grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _StatItem(
                  icon: Icons.eco,
                  iconColor: Colors.green,
                  label: 'Carbon Saved',
                  value: '${totalCarbonSaved.toStringAsFixed(1)} kg',
                ),
                _StatItem(
                  icon: Icons.analytics,
                  iconColor: Colors.blue,
                  label: 'Activities',
                  value: '$totalActivitiesLogged',
                ),
                _StatItem(
                  icon: Icons.emoji_events,
                  iconColor: Colors.amber,
                  label: 'Challenges',
                  value: '$challengesCompleted',
                ),
                _StatItem(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.orange,
                  label: 'Day Streak',
                  value: '$currentStreak',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
