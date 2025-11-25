import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecosphare/features/dashboard/domain/user_activity.dart';
import 'package:ecosphare/features/auth/data/user_stats_repository.dart';
import 'package:ecosphare/features/community/data/challenge_repository.dart';
import 'package:ecosphare/core/services/gamification_service.dart';
import 'package:ecosphare/core/services/achievement_service.dart';
import 'package:ecosphare/features/auth/domain/user.dart';

/// Service to integrate gamification with activity logging
/// Automatically awards XP, updates challenges, and unlocks badges
class GamificationIntegrationService {
  final UserStatsRepository _userStatsRepository;
  final ChallengeRepository _challengeRepository;

  GamificationIntegrationService({
    required UserStatsRepository userStatsRepository,
    required ChallengeRepository challengeRepository,
  })  : _userStatsRepository = userStatsRepository,
        _challengeRepository = challengeRepository;

  /// Process activity for gamification (call after activity is logged)
  Future<Map<String, dynamic>> processActivityLogged({
    required String userId,
    required UserActivity activity,
    required AppUser currentUser,
  }) async {
    final results = <String, dynamic>{
      'xpAwarded': 0,
      'pointsAwarded': 0,
      'levelUp': false,
      'oldLevel': currentUser.level,
      'newLevel': currentUser.level,
      'badgesUnlocked': <String>[],
      'challengesProgressed': <String>[],
    };

    try {
      // 1. Award XP for the activity
      final xpAwarded = gamificationService.calculateActivityXP(activity.carbonImpact);
      if (xpAwarded > 0) {
        await _userStatsRepository.awardXP(userId, xpAwarded);
        results['xpAwarded'] = xpAwarded;
      }

      // 1.5 Award Points for the activity
      final pointsAwarded = gamificationService.calculateActivityPoints(activity.carbonImpact);
      if (pointsAwarded > 0) {
        await _userStatsRepository.awardPoints(userId, pointsAwarded);
        results['pointsAwarded'] = pointsAwarded;
      }

      // 2. Update streak
      await _userStatsRepository.updateStreak(userId);

      // 3. Update challenge progress for active challenges
      final activeChallenges = await _challengeRepository.getUserActiveChallenges(userId);
      
      for (final progress in activeChallenges) {
        final challenge = await _challengeRepository.getChallenge(progress.challengeId);
        if (challenge == null) continue;

        // Check if this activity contributes to the challenge
        final progressAmount = _calculateChallengeProgress(activity, challenge.category.name);
        
        if (progressAmount > 0) {
          await _challengeRepository.updateChallengeProgress(
            userId: userId,
            challengeId: challenge.id,
            progress: progressAmount,
          );
          results['challengesProgressed'].add(challenge.id);

          // Check if challenge was just completed
          final updatedProgress = await _challengeRepository.getUserChallengeProgress(
            userId: userId,
            challengeId: challenge.id,
          );
          
          if (updatedProgress != null && updatedProgress.isCompleted) {
            // Award challenge XP and points
            await _userStatsRepository.awardXP(
              userId,
              challenge.xpReward,
              reason: 'Completed challenge: ${challenge.title}',
            );
            await _userStatsRepository.awardPoints(
              userId,
              challenge.pointsReward,
              reason: 'Completed challenge: ${challenge.title}',
            );
            results['xpAwarded'] = (results['xpAwarded'] as int) + challenge.xpReward;
            results['pointsAwarded'] = (results['pointsAwarded'] as int) + challenge.pointsReward;
          }
        }
      }

      // 4. Update all user stats and check for badges
      await _userStatsRepository.updateUserStats(userId);

      // 5. Check if user leveled up
      final levelProgress = await _userStatsRepository.getLevelProgress(userId);
      final newLevel = levelProgress['currentLevel'] as int;
      
      if (newLevel > currentUser.level) {
        results['levelUp'] = true;
        results['oldLevel'] = currentUser.level;
        results['newLevel'] = newLevel;
        
        // Award level up rewards
        final rewards = gamificationService.getLevelUpRewards(newLevel);
        final levelPoints = rewards['points'] as int? ?? 0;
        if (levelPoints > 0) {
          await _userStatsRepository.awardPoints(
            userId, 
            levelPoints, 
            reason: 'Level up to $newLevel',
          );
          results['pointsAwarded'] = (results['pointsAwarded'] as int) + levelPoints;
        }
      }

      // 6. Get newly unlocked badges
      // This is done by comparing current user badges with updated stats
      // The updateUserStats call above will have added new badges

      return results;
    } catch (e) {
      throw Exception('Failed to process activity gamification: $e');
    }
  }

  /// Calculate how much progress an activity contributes to a challenge
  double _calculateChallengeProgress(UserActivity activity, String challengeCategory) {
    // Map activity types to challenge categories
    final activityCategoryMap = {
      'transport': ActivityType.transport,
      'diet': ActivityType.diet,
      'energy': ActivityType.energy,
      'waste': ActivityType.waste,
      'shopping': ActivityType.shopping,
    };

    final matchingType = activityCategoryMap[challengeCategory];
    
    if (matchingType != null && activity.type == matchingType) {
      // For matching categories, contribute 1 unit of progress
      // In a real app, you might have more sophisticated logic
      return 1.0;
    }
    
    // For "mixed" category challenges, any activity contributes
    if (challengeCategory == 'mixed') {
      return 1.0;
    }

    return 0.0;
  }

  /// Process challenge completion (manual trigger or scheduled job)
  Future<Map<String, dynamic>> processChallengeCompletion({
    required String userId,
    required String challengeId,
  }) async {
    final results = <String, dynamic>{
      'xpAwarded': 0,
      'pointsAwarded': 0,
      'badgesUnlocked': <String>[],
    };

    try {
      final challenge = await _challengeRepository.getChallenge(challengeId);
      if (challenge == null) return results;

      // Award XP
      await _userStatsRepository.awardXP(
        userId,
        challenge.xpReward,
        reason: 'Completed challenge: ${challenge.title}',
      );
      results['xpAwarded'] = challenge.xpReward;

      // Award Points
      await _userStatsRepository.awardPoints(
        userId,
        challenge.pointsReward,
        reason: 'Completed challenge: ${challenge.title}',
      );
      results['pointsAwarded'] = challenge.pointsReward;

      // Award any associated badges
      for (final badgeId in challenge.badgeIds) {
        await _userStatsRepository.unlockBadge(userId, badgeId);
        results['badgesUnlocked'].add(badgeId);
      }

      // Update user stats
      await _userStatsRepository.updateUserStats(userId);

      return results;
    } catch (e) {
      throw Exception('Failed to process challenge completion: $e');
    }
  }

  /// Check and unlock eligible badges (can be called periodically)
  Future<List<String>> checkAndUnlockBadges({
    required String userId,
    required AppUser currentUser,
  }) async {
    final newlyUnlocked = <String>[];

    try {
      final eligibleBadges = achievementService.checkBadgeEligibility(
        carbonSaved: currentUser.totalCarbonSaved,
        challengesCompleted: currentUser.challengesCompleted,
        streakDays: currentUser.currentStreak,
        activitiesLogged: currentUser.totalActivitiesLogged,
        currentLevel: currentUser.level,
        alreadyUnlockedIds: currentUser.unlockedBadgeIds,
      );

      for (final badgeId in eligibleBadges) {
        await _userStatsRepository.unlockBadge(userId, badgeId);
        newlyUnlocked.add(badgeId);
      }

      return newlyUnlocked;
    } catch (e) {
      throw Exception('Failed to check and unlock badges: $e');
    }
  }
}

/// Provider for GamificationIntegrationService
final gamificationIntegrationServiceProvider = Provider<GamificationIntegrationService>((ref) {
  return GamificationIntegrationService(
    userStatsRepository: ref.watch(userStatsRepositoryProvider),
    challengeRepository: ref.watch(challengeRepositoryProvider),
  );
});
