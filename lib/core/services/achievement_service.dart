import '../../features/community/domain/badge.dart';

/// Achievement service for checking badge eligibility and managing unlocks
class AchievementService {
  /// Check which badges should be unlocked based on user stats
  List<String> checkBadgeEligibility({
    required double carbonSaved,
    required int challengesCompleted,
    required int streakDays,
    required int activitiesLogged,
    required int currentLevel,
    List<String> alreadyUnlockedIds = const [],
  }) {
    final eligibleBadges = <String>[];

    // Carbon Saver Badges
    if (carbonSaved >= 10 && !alreadyUnlockedIds.contains('carbon_starter')) {
      eligibleBadges.add('carbon_starter');
    }
    if (carbonSaved >= 100 && !alreadyUnlockedIds.contains('carbon_saver')) {
      eligibleBadges.add('carbon_saver');
    }
    if (carbonSaved >= 500 && !alreadyUnlockedIds.contains('carbon_champion')) {
      eligibleBadges.add('carbon_champion');
    }
    if (carbonSaved >= 1000 && !alreadyUnlockedIds.contains('carbon_hero')) {
      eligibleBadges.add('carbon_hero');
    }

    // Challenge Badges
    if (challengesCompleted >= 1 &&
        !alreadyUnlockedIds.contains('challenge_starter')) {
      eligibleBadges.add('challenge_starter');
    }
    if (challengesCompleted >= 10 &&
        !alreadyUnlockedIds.contains('challenge_enthusiast')) {
      eligibleBadges.add('challenge_enthusiast');
    }
    if (challengesCompleted >= 50 &&
        !alreadyUnlockedIds.contains('challenge_master')) {
      eligibleBadges.add('challenge_master');
    }

    // Streak Badges
    if (streakDays >= 7 && !alreadyUnlockedIds.contains('weekly_streak')) {
      eligibleBadges.add('weekly_streak');
    }
    if (streakDays >= 30 && !alreadyUnlockedIds.contains('monthly_streak')) {
      eligibleBadges.add('monthly_streak');
    }
    if (streakDays >= 100 && !alreadyUnlockedIds.contains('century_streak')) {
      eligibleBadges.add('century_streak');
    }

    // Activity Logger Badges
    if (activitiesLogged >= 30 &&
        !alreadyUnlockedIds.contains('consistent_logger')) {
      eligibleBadges.add('consistent_logger');
    }
    if (activitiesLogged >= 100 &&
        !alreadyUnlockedIds.contains('dedicated_tracker')) {
      eligibleBadges.add('dedicated_tracker');
    }
    if (activitiesLogged >= 365 && !alreadyUnlockedIds.contains('year_round')) {
      eligibleBadges.add('year_round');
    }

    // Level Milestone Badges
    if (currentLevel >= 5 && !alreadyUnlockedIds.contains('level_5')) {
      eligibleBadges.add('level_5');
    }
    if (currentLevel >= 10 && !alreadyUnlockedIds.contains('level_10')) {
      eligibleBadges.add('level_10');
    }
    if (currentLevel >= 25 && !alreadyUnlockedIds.contains('level_25')) {
      eligibleBadges.add('level_25');
    }
    if (currentLevel >= 50 && !alreadyUnlockedIds.contains('level_50')) {
      eligibleBadges.add('level_50');
    }

    return eligibleBadges;
  }

  /// Get progress toward a specific badge
  Map<String, dynamic> getBadgeProgress({
    required String badgeId,
    required double carbonSaved,
    required int challengesCompleted,
    required int streakDays,
    required int activitiesLogged,
    required int currentLevel,
  }) {
    final badge = BadgeDefinitions.getById(badgeId);
    if (badge == null) {
      return {'error': 'Badge not found'};
    }

    double currentValue = 0;

    // Determine current value based on badge category
    switch (badge.category) {
      case BadgeCategory.carbonSaver:
        currentValue = carbonSaved;
        break;
      case BadgeCategory.challenger:
        currentValue = challengesCompleted.toDouble();
        break;
      case BadgeCategory.streakMaster:
        currentValue = streakDays.toDouble();
        break;
      case BadgeCategory.activityLogger:
        currentValue = activitiesLogged.toDouble();
        break;
      case BadgeCategory.levelMilestone:
        currentValue = currentLevel.toDouble();
        break;
      case BadgeCategory.socialButterfly:
      case BadgeCategory.earlyAdopter:
        currentValue = 0; // These require special tracking
        break;
    }

    final progress = (currentValue / badge.requiredValue * 100).clamp(0, 100);

    return {
      'badgeId': badgeId,
      'currentValue': currentValue,
      'requiredValue': badge.requiredValue,
      'progressPercentage': progress,
      'isUnlockable': currentValue >= badge.requiredValue,
      'remaining': (badge.requiredValue - currentValue).clamp(0, double.infinity),
    };
  }

  /// Get next achievable badges (closest to unlocking)
  List<Map<String, dynamic>> getNextAchievableBadges({
    required double carbonSaved,
    required int challengesCompleted,
    required int streakDays,
    required int activitiesLogged,
    required int currentLevel,
    required List<String> alreadyUnlockedIds,
    int limit = 5,
  }) {
    final allBadges = BadgeDefinitions.all
        .where((b) => !alreadyUnlockedIds.contains(b.id))
        .toList();

    final badgesWithProgress = allBadges.map((badge) {
      final progress = getBadgeProgress(
        badgeId: badge.id,
        carbonSaved: carbonSaved,
        challengesCompleted: challengesCompleted,
        streakDays: streakDays,
        activitiesLogged: activitiesLogged,
        currentLevel: currentLevel,
      );

      return {
        'badge': badge,
        ...progress,
      };
    }).toList();

    // Sort by progress (closest to completion first)
    badgesWithProgress.sort((a, b) {
      final progressA = a['progressPercentage'] as double;
      final progressB = b['progressPercentage'] as double;
      return progressB.compareTo(progressA);
    });

    return badgesWithProgress.take(limit).toList();
  }

  /// Calculate total XP from unlocked badges
  int calculateBadgeXP(List<String> unlockedBadgeIds) {
    return unlockedBadgeIds.fold<int>(0, (total, badgeId) {
      final badge = BadgeDefinitions.getById(badgeId);
      return total + (badge?.xpReward ?? 0);
    });
  }

  /// Get completion percentage for a category
  double getCategoryCompletion(BadgeCategory category, List<String> unlockedIds) {
    final categoryBadges = BadgeDefinitions.getByCategory(category);
    if (categoryBadges.isEmpty) return 0.0;

    final unlockedCount =
        categoryBadges.where((b) => unlockedIds.contains(b.id)).length;
    return (unlockedCount / categoryBadges.length * 100);
  }

  /// Get overall badge collection progress
  Map<String, dynamic> getCollectionProgress(List<String> unlockedIds) {
    final totalBadges = BadgeDefinitions.all.length;
    final unlockedCount = unlockedIds.length;
    final percentage = (unlockedCount / totalBadges * 100);

    final byRarity = <String, int>{};
    for (final rarity in BadgeRarity.values) {
      final rarityBadges = BadgeDefinitions.getByRarity(rarity);
      final unlocked =
          rarityBadges.where((b) => unlockedIds.contains(b.id)).length;
      byRarity[rarity.name] = unlocked;
    }

    return {
      'totalBadges': totalBadges,
      'unlockedCount': unlockedCount,
      'percentage': percentage,
      'byRarity': byRarity,
    };
  }
}

/// Singleton instance
final achievementService = AchievementService();
