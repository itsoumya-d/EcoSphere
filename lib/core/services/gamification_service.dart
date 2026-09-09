import '../../../core/constants/app_constants.dart';

/// Gamification service for managing XP, levels, and rewards
class GamificationService {
  /// Calculate XP awarded for an activity based on carbon impact
  int calculateActivityXP(double carbonImpact) {
    // Award more XP for bigger positive impact (negative = saved CO2)
    final impactValue = carbonImpact.abs();
    
    if (carbonImpact < 0) {
      // Eco-friendly activity - bonus XP
      return (impactValue * AppConstants.basePointsPerKgCO2Saved * 1.5).toInt();
    } else {
      // Regular tracking - base XP
      return (impactValue * AppConstants.basePointsPerKgCO2Saved * 0.5).toInt();
    }
  }

  /// Calculate Points (currency) awarded for an activity
  int calculateActivityPoints(double carbonImpact) {
    // Points are spendable currency, usually a fraction of XP
    // For now, let's say 1 Point per 10 XP (10% of XP)
    final xp = calculateActivityXP(carbonImpact);
    return (xp * 0.1).ceil();
  }

  /// Calculate level from total XP
  int calculateLevel(int totalXP) {
    // Guard against negative XP so level never drops below 1.
    if (totalXP < 0) return 1;
    return (totalXP / AppConstants.xpPerLevel).floor() + 1;
  }

  /// Calculate XP required for next level
  int xpRequiredForLevel(int level) {
    return level * AppConstants.xpPerLevel;
  }

  /// Calculate XP progress to next level
  Map<String, dynamic> getLevelProgress(int totalXP) {
    final currentLevel = calculateLevel(totalXP);
    final currentLevelXP = xpRequiredForLevel(currentLevel - 1);
    final nextLevelXP = xpRequiredForLevel(currentLevel);
    final xpInCurrentLevel = totalXP - currentLevelXP;
    final xpNeededForNext = nextLevelXP - currentLevelXP;
    final progress = xpInCurrentLevel / xpNeededForNext;

    return {
      'currentLevel': currentLevel,
      'totalXP': totalXP,
      'xpInCurrentLevel': xpInCurrentLevel,
      'xpNeededForNext': xpNeededForNext,
      'xpForNextLevel': nextLevelXP - totalXP,
      'progress': progress.clamp(0.0, 1.0),
    };
  }

  /// Calculate streak bonus XP
  int calculateStreakBonus(int streakDays) {
    final effectiveDays = streakDays.clamp(0, AppConstants.maxStreakBonusDays);
    return effectiveDays * AppConstants.streakBonusMultiplier;
  }

  /// Calculate XP for challenge completion
  int calculateChallengeXP({
    required int baseXP,
    required String difficulty,
    bool isFirstCompletion = false,
  }) {
    double multiplier = 1.0;

    // Difficulty multiplier
    switch (difficulty) {
      case 'easy':
        multiplier = 1.0;
        break;
      case 'medium':
        multiplier = 1.5;
        break;
      case 'hard':
        multiplier = 2.0;
        break;
      case 'expert':
        multiplier = 2.5;
        break;
    }

    // First completion bonus
    if (isFirstCompletion) {
      multiplier *= 1.2;
    }

    return (baseXP * multiplier).toInt();
  }

  /// Calculate Points for challenge completion
  int calculateChallengePoints({
    required int basePoints,
    required String difficulty,
  }) {
    double multiplier = 1.0;

    // Difficulty multiplier for points
    switch (difficulty) {
      case 'easy':
        multiplier = 1.0;
        break;
      case 'medium':
        multiplier = 1.2;
        break;
      case 'hard':
        multiplier = 1.5;
        break;
      case 'expert':
        multiplier = 2.0;
        break;
    }

    return (basePoints * multiplier).toInt();
  }

  /// Get level title/rank
  String getLevelTitle(int level) {
    if (level >= 50) return 'Eco Legend';
    if (level >= 40) return 'Environmental Champion';
    if (level >= 30) return 'Sustainability Expert';
    if (level >= 20) return 'Green Warrior';
    if (level >= 15) return 'Eco Enthusiast';
    if (level >= 10) return 'Climate Advocate';
    if (level >= 5) return 'Earth Friend';
    return 'Eco Beginner';
  }

  /// Get level color theme
  String getLevelColor(int level) {
    if (level >= 50) return '#FFD700'; // Gold
    if (level >= 40) return '#C0C0C0'; // Silver
    if (level >= 30) return '#CD7F32'; // Bronze
    if (level >= 20) return '#4CAF50'; // Green
    if (level >= 10) return '#2196F3'; // Blue
    return '#9E9E9E'; // Gray
  }

  /// Check if user leveled up
  bool didLevelUp(int oldXP, int newXP) {
    return calculateLevel(oldXP) < calculateLevel(newXP);
  }

  /// Calculate rewards for level up
  Map<String, dynamic> getLevelUpRewards(int newLevel) {
    return {
      'points': newLevel * 50, // Award 50 points per level
      'badge': newLevel % 5 == 0 ? 'milestone_${newLevel}' : null,
      'title': getLevelTitle(newLevel),
      'unlocks': _getLevelUnlocks(newLevel),
    };
  }

  /// Features unlocked at each level
  List<String> _getLevelUnlocks(int level) {
    final unlocks = <String>[];
    
    if (level == 5) unlocks.add('Custom Challenges');
    if (level == 10) unlocks.add('Advanced Statistics');
    if (level == 15) unlocks.add('Carbon Offset Marketplace');
    if (level == 20) unlocks.add('Team Challenges');
    if (level == 25) unlocks.add('Expert Tips');
    if (level == 30) unlocks.add('Leaderboard Badge');
    if (level == 40) unlocks.add('Mentor Status');
    if (level == 50) unlocks.add('Legend Badge');
    
    return unlocks;
  }

  /// Calculate total points from activities and challenges
  int calculateTotalPoints({
    required int activityPoints,
    required int challengePoints,
    required int streakBonus,
  }) {
    return activityPoints + challengePoints + streakBonus;
  }

  /// Determine badge eligibility based on achievements
  List<String> checkBadgeEligibility({
    required int totalXP,
    required double carbonSaved,
    required int activitiesLogged,
    required int challengesCompleted,
    required int streakDays,
  }) {
    final eligibleBadges = <String>[];

    // XP-based badges
    if (totalXP >= 10000) eligibleBadges.add('xp_master');
    if (totalXP >= 5000) eligibleBadges.add('xp_expert');
    if (totalXP >= 1000) eligibleBadges.add('xp_pro');

    // Carbon savings badges
    if (carbonSaved >= 1000) eligibleBadges.add('carbon_hero');
    if (carbonSaved >= 500) eligibleBadges.add('carbon_champion');
    if (carbonSaved >= 100) eligibleBadges.add('carbon_saver');

    // Activity badges
    if (activitiesLogged >= 365) eligibleBadges.add('year_round');
    if (activitiesLogged >= 100) eligibleBadges.add('dedicated_tracker');
    if (activitiesLogged >= 30) eligibleBadges.add('consistent_logger');

    // Challenge badges
    if (challengesCompleted >= 50) eligibleBadges.add('challenge_master');
    if (challengesCompleted >= 20) eligibleBadges.add('challenge_enthusiast');
    if (challengesCompleted >= 5) eligibleBadges.add('challenge_starter');

    // Streak badges
    if (streakDays >= 100) eligibleBadges.add('century_streak');
    if (streakDays >= 30) eligibleBadges.add('monthly_streak');
    if (streakDays >= 7) eligibleBadges.add('weekly_streak');

    return eligibleBadges;
  }
}

/// Singleton instance
final gamificationService = GamificationService();
