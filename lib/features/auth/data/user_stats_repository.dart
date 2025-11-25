import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user.dart';
import '../../dashboard/data/activity_repository.dart';
import '../../community/data/challenge_repository.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/services/achievement_service.dart';

/// User statistics repository for tracking and updating gamification stats
class UserStatsRepository {
  final FirebaseFirestore _firestore;
  final ActivityRepository _activityRepository;
  final ChallengeRepository _challengeRepository;

  UserStatsRepository({
    required FirebaseFirestore firestore,
    required ActivityRepository activityRepository,
    required ChallengeRepository challengeRepository,
  })  : _firestore = firestore,
        _activityRepository = activityRepository,
        _challengeRepository = challengeRepository;

  /// Users collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Calculate and update all user stats
  Future<void> updateUserStats(String userId) async {
    try {
      // Get activity stats
      final activityStats = await _activityRepository.getActivityStatistics(userId);
      
      // Get challenge stats
      final challengeStats = await _challengeRepository.getChallengeStatistics(userId);
      
      // Calculate total carbon saved (negative = saved)
      final totalCarbonSaved = (activityStats['totalImpact'] as double).abs();
      
      // Get current user to check existing badges
      final userDoc = await _usersCollection.doc(userId).get();
      final currentUser = AppUser.fromFirestore(userDoc);
      
      // Calculate XP from activities (simplified - in production use actual activity data)
      final activityXP = (activityStats['totalActivities'] as int) * 10;
      final challengeXP = (challengeStats['completedChallenges'] as int) * 100;
      final totalXP = activityXP + challengeXP;
      
      // Calculate level
      final level = gamificationService.calculateLevel(totalXP);
      
      // Check for newly unlocked badges
      final eligibleBadges = achievementService.checkBadgeEligibility(
        carbonSaved: totalCarbonSaved,
        challengesCompleted: challengeStats['completedChallenges'] as int,
        streakDays: currentUser.currentStreak,
        activitiesLogged: activityStats['totalActivities'] as int,
        currentLevel: level,
        alreadyUnlockedIds: currentUser.unlockedBadgeIds,
      );
      
      // Merge with existing badges
      final allUnlockedBadges = {
        ...currentUser.unlockedBadgeIds,
        ...eligibleBadges,
      }.toList();
      
      // Update user document
      await _usersCollection.doc(userId).update({
        'totalCarbonSaved': totalCarbonSaved,
        'totalActivitiesLogged': activityStats['totalActivities'],
        'level': level,
        'experiencePoints': totalXP,
        'challengesCompleted': challengeStats['completedChallenges'],
        'unlockedBadgeIds': allUnlockedBadges,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user stats: $e');
    }
  }

  /// Update streak (call daily when user logs activity)
  Future<void> updateStreak(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final user = AppUser.fromFirestore(userDoc);
      
      final lastActivityDate = user.updatedAt;
      final now = DateTime.now();
      final daysSinceLastActivity = now.difference(lastActivityDate).inDays;
      
      int newStreak;
      if (daysSinceLastActivity == 0) {
        // Same day, keep streak
        newStreak = user.currentStreak;
      } else if (daysSinceLastActivity == 1) {
        // Next day, increment streak
        newStreak = user.currentStreak + 1;
      } else {
        // Missed days, reset streak
        newStreak = 1;
      }
      
      await _usersCollection.doc(userId).update({
        'currentStreak': newStreak,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }

  /// Award XP to user
  Future<void> awardXP(String userId, int xp, {String? reason}) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final user = AppUser.fromFirestore(userDoc);
      
      final oldXP = user.experiencePoints;
      final newXP = oldXP + xp;
      final newLevel = gamificationService.calculateLevel(newXP);
      
      // Check if user leveled up
      final didLevelUp = gamificationService.didLevelUp(oldXP, newXP);
      
      await _usersCollection.doc(userId).update({
        'experiencePoints': newXP,
        'level': newLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // If leveled up, check for level-based badges
      if (didLevelUp) {
        await updateUserStats(userId);
      }
    } catch (e) {
      throw Exception('Failed to award XP: $e');
    }
  }

  /// Award Points (currency) to user
  Future<void> awardPoints(String userId, int points, {String? reason}) async {
    try {
      await _usersCollection.doc(userId).update({
        'points': FieldValue.increment(points),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to award points: $e');
    }
  }

  /// Unlock a badge for user
  Future<void> unlockBadge(String userId, String badgeId) async {
    try {
      await _usersCollection.doc(userId).update({
        'unlockedBadgeIds': FieldValue.arrayUnion([badgeId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to unlock badge: $e');
    }
  }

  /// Get user level progress
  Future<Map<String, dynamic>> getLevelProgress(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final user = AppUser.fromFirestore(userDoc);
      
      return gamificationService.getLevelProgress(user.experiencePoints);
    } catch (e) {
      throw Exception('Failed to get level progress: $e');
    }
  }

  /// Get user's unlocked badges with details
  Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final user = AppUser.fromFirestore(userDoc);
      
      return user.unlockedBadgeIds.map((badgeId) {
        final badge = achievementService.getBadgeProgress(
          badgeId: badgeId,
          carbonSaved: user.totalCarbonSaved,
          challengesCompleted: user.challengesCompleted,
          streakDays: user.currentStreak,
          activitiesLogged: user.totalActivitiesLogged,
          currentLevel: user.level,
        );
        return badge;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user badges: $e');
    }
  }
}

/// Provider for UserStatsRepository
final userStatsRepositoryProvider = Provider<UserStatsRepository>((ref) {
  return UserStatsRepository(
    firestore: FirebaseFirestore.instance,
    activityRepository: ref.watch(activityRepositoryProvider),
    challengeRepository: ref.watch(challengeRepositoryProvider),
  );
});
