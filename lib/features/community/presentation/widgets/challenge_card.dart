import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/eco_challenge.dart';
import '../providers/challenge_controller.dart';

class ChallengeCard extends ConsumerWidget {
  final EcoChallenge challenge;
  final ChallengeProgress? progress;
  final bool isActive;
  final bool compact;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.progress,
    this.isActive = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final progressValue = progress?.progressPercentage ?? 0.0;
    final isCompleted = progress?.isCompleted ?? false;
    final categoryColor = _getCategoryColor();

    return Card(
      elevation: isActive ? 2 : 0,
      color: isActive
          ? colorScheme.primaryContainer.withOpacity(0.3)
          : colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: isActive
            ? null
            : () {
                ref.read(challengeControllerProvider.notifier).joinChallenge(challenge.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Challenge started: ${challenge.title}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Title and duration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${challenge.durationDays} ${challenge.durationDays == 1 ? "day" : "days"}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Difficulty badge
                  _buildDifficultyBadge(context),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description (hide in compact mode if needed, or limit lines)
              if (!compact)
                Text(
                  challenge.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              if (!compact) const SizedBox(height: 16),
              
              // Progress bar (if active)
              if (isActive && !isCompleted) ...[
                _buildProgressBar(context, progressValue / 100),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${progress!.currentProgress.toStringAsFixed(1)} / ${challenge.targetValue} ${challenge.targetUnit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (challenge.daysRemaining > 0)
                      Text(
                        '${challenge.daysRemaining}d left',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Completed badge
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Completed!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 300.ms).fadeIn(),
              
              // Stats row
              if (!isActive)
                Row(
                  children: [
                    Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.xpReward} XP',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    if (!compact) ...[
                      Icon(Icons.star, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${challenge.pointsReward} pts',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Icon(Icons.people, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${challenge.participantCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else ...[
                      const Spacer(),
                      Icon(Icons.people, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${challenge.participantCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(BuildContext context) {
    Color color;
    switch (challenge.difficulty) {
      case ChallengeDifficulty.easy:
        color = Colors.green;
        break;
      case ChallengeDifficulty.medium:
        color = Colors.orange;
        break;
      case ChallengeDifficulty.hard:
        color = Colors.red;
        break;
      case ChallengeDifficulty.expert:
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        challenge.difficultyLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double value) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = _getCategoryColor();
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (challenge.category) {
      case ChallengeCategory.transport:
        return Colors.orange;
      case ChallengeCategory.diet:
        return Colors.green;
      case ChallengeCategory.energy:
        return Colors.yellow[700]!;
      case ChallengeCategory.waste:
        return Colors.brown;
      case ChallengeCategory.shopping:
        return Colors.purple;
      case ChallengeCategory.mixed:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon() {
    switch (challenge.category) {
      case ChallengeCategory.transport:
        return Icons.directions_car;
      case ChallengeCategory.diet:
        return Icons.restaurant;
      case ChallengeCategory.energy:
        return Icons.bolt;
      case ChallengeCategory.waste:
        return Icons.delete;
      case ChallengeCategory.shopping:
        return Icons.shopping_bag;
      case ChallengeCategory.mixed:
        return Icons.eco;
    }
  }
}
