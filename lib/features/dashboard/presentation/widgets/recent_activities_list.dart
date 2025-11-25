import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/user_activity.dart';
import '../providers/dashboard_controller.dart';
import 'activity_entry_form.dart';
import '../../../community/data/social_feed_repository.dart';
import '../../../community/domain/social_post.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

/// Widget displaying list of recent user activities
class RecentActivitiesList extends ConsumerWidget {
  final int? maxItems;
  final bool showHeader;

  const RecentActivitiesList({
    super.key,
    this.maxItems,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);

    if (dashboardState.isLoading && dashboardState.activities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboardState.error != null) {
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
              'Error loading activities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              dashboardState.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final activities = maxItems != null
        ? dashboardState.activities.take(maxItems!).toList()
        : dashboardState.activities;

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No activities yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your eco-actions!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: const ActivityEntryForm(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Log First Activity'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (maxItems != null && dashboardState.activities.length > maxItems!)
                  TextButton(
                    onPressed: () {
                      // Navigate to full activities list
                      Navigator.of(context).pushNamed('/activities');
                    },
                    child: const Text('See All'),
                  ),
              ],
            ),
          ),
        ],
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return _ActivityListItem(activity: activities[index]);
          },
        ),
      ],
    );
  }
}

/// Individual activity list item
class _ActivityListItem extends ConsumerWidget {
  final UserActivity activity;

  const _ActivityListItem({required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEcoFriendly = activity.carbonImpact < 0;

    return Dismissible(
      key: Key(activity.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete_outline,
          color: colorScheme.error,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Activity'),
            content: const Text('Are you sure you want to delete this activity?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await ref
            .read(dashboardControllerProvider.notifier)
            .deleteActivity(activity.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        onTap: () => _showActivityOptions(context, ref),
        leading: _getActivityIcon(),
        title: Text(
          activity.getDescription(),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(activity.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (activity.notes != null) ...[
              const SizedBox(height: 4),
              Text(
                activity.notes!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isEcoFriendly
                    ? colorScheme.primaryContainer
                    : colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEcoFriendly
                        ? Icons.trending_down
                        : Icons.trending_up,
                    size: 16,
                    color: isEcoFriendly
                        ? colorScheme.primary
                        : colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${activity.carbonImpact.abs().toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isEcoFriendly
                              ? colorScheme.primary
                              : colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
              title: const Text('Share to Social Feed'),
              subtitle: const Text('Let others see your eco-action'),
              onTap: () {
                Navigator.pop(context);
                _shareToSocialFeed(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: const Text('Delete Activity'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Activity'),
                    content: const Text('Are you sure you want to delete this activity?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await ref
                      .read(dashboardControllerProvider.notifier)
                      .deleteActivity(activity.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Activity deleted'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToSocialFeed(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to share')),
        );
      }
      return;
    }

    // Generate a nice message for the activity
    String message = _generateShareMessage();

    // Show dialog to edit message before posting
    final controller = TextEditingController(text: message);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share to Social Feed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity: ${activity.getDescription()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Add a message',
                border: OutlineInputBorder(),
                hintText: 'Share your thoughts...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final post = SocialPost(
          id: '', // Will be generated
          userId: currentUser.uid,
          userDisplayName: currentUser.displayName ?? 'Anonymous',
          userPhotoUrl: currentUser.photoURL,
          content: controller.text.trim(),
          activityId: activity.id,
          activityType: activity.type.name,
          carbonImpact: activity.carbonImpact,
          createdAt: DateTime.now(),
        );

        final repository = ref.read(socialFeedRepositoryProvider);
        await repository.createPost(post);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Shared to social feed! 🎉'),
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  // Navigate to social feed tab
                  // This would need proper navigation context
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to share: $e')),
          );
        }
      }
    }

    controller.dispose();
  }

  String _generateShareMessage() {
    final isEcoFriendly = activity.carbonImpact < 0;
    final impact = activity.carbonImpact.abs().toStringAsFixed(1);
    
    if (isEcoFriendly) {
      return '🌱 Just ${activity.getDescription().toLowerCase()} and saved $impact kg of CO₂! Every small action counts! #EcoSphere #ClimateAction';
    } else {
      return '📊 Tracked my ${activity.getDescription().toLowerCase()} ($impact kg CO₂). Working on reducing my footprint! #EcoSphere #Sustainability';
    }
  }

  Widget _getActivityIcon() {
    IconData iconData;

    switch (activity.type) {
      case ActivityType.transport:
        iconData = Icons.directions_car;
        break;
      case ActivityType.diet:
        iconData = Icons.restaurant;
        break;
      case ActivityType.energy:
        iconData = Icons.bolt;
        break;
      case ActivityType.waste:
        iconData = Icons.delete;
        break;
      case ActivityType.shopping:
        iconData = Icons.shopping_bag;
        break;
    }

    return CircleAvatar(
      backgroundColor: activity.isEcoFriendly
          ? Colors.green.withOpacity(0.1)
          : Colors.orange.withOpacity(0.1),
      child: Icon(
        iconData,
        color: activity.isEcoFriendly ? Colors.green : Colors.orange,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}
