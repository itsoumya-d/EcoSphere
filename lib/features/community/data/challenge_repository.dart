import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../domain/eco_challenge.dart';

/// Repository for managing challenges in Firestore
class ChallengeRepository {
  final FirebaseFirestore _firestore;

  ChallengeRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Challenges collection
  CollectionReference get _challengesCollection =>
      _firestore.collection('challenges');

  /// User challenge progress subcollection
  CollectionReference _userChallengeProgress(String userId) =>
      _firestore.collection('users').doc(userId).collection('challengeProgress');

  // ==================== CHALLENGES ====================

  /// Get all active challenges
  Future<List<EcoChallenge>> getActiveChallenges() async {
    try {
      final now = DateTime.now();
      final snapshot = await _challengesCollection
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('endDate')
          .get();

      return snapshot.docs
          .map((doc) => EcoChallenge.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active challenges: $e');
    }
  }

  /// Get challenges by category
  Future<List<EcoChallenge>> getChallengesByCategory(
    ChallengeCategory category,
  ) async {
    try {
      final snapshot = await _challengesCollection
          .where('category', isEqualTo: category.name)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => EcoChallenge.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get challenges by category: $e');
    }
  }

  /// Get seasonal challenges
  Future<List<EcoChallenge>> getSeasonalChallenges() async {
    try {
      final snapshot = await _challengesCollection
          .where('isActive', isEqualTo: true)
          .where('isSeasonal', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => EcoChallenge.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get seasonal challenges: $e');
    }
  }

  /// Get challenge by ID
  Future<EcoChallenge?> getChallenge(String challengeId) async {
    try {
      final doc = await _challengesCollection.doc(challengeId).get();
      if (!doc.exists) return null;
      return EcoChallenge.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get challenge: $e');
    }
  }

  /// Create a new challenge (admin function)
  Future<EcoChallenge> createChallenge(EcoChallenge challenge) async {
    try {
      final docRef = _challengesCollection.doc(challenge.id);
      await docRef.set(challenge.toFirestore());
      final doc = await docRef.get();
      return EcoChallenge.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create challenge: $e');
    }
  }

  /// Update challenge
  Future<void> updateChallenge(
    String challengeId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _challengesCollection.doc(challengeId).update(updates);
    } catch (e) {
      throw Exception('Failed to update challenge: $e');
    }
  }

  /// Increment participant count
  Future<void> incrementParticipants(String challengeId) async {
    try {
      await _challengesCollection.doc(challengeId).update({
        'participantCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment participants: $e');
    }
  }

  /// Get recommended challenges based on user's high impact categories
  Future<List<EcoChallenge>> getRecommendedChallenges(
    Map<String, double> categoryBreakdown, {
    int limit = 3,
  }) async {
    try {
      // Find category with highest impact
      String? topCategory;
      double maxImpact = 0;
      
      categoryBreakdown.forEach((category, impact) {
        if (impact > maxImpact) {
          maxImpact = impact;
          topCategory = category;
        }
      });

      if (topCategory == null) {
        // Fallback to trending/popular challenges if no data
        return getPopularChallenges(limit: limit);
      }

      // Map activity category string to ChallengeCategory enum name
      // This mapping depends on how categories are stored in breakdown
      // Assuming they match or can be mapped
      
      final snapshot = await _challengesCollection
          .where('category', isEqualTo: topCategory)
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      var recommendations = snapshot.docs
          .map((doc) => EcoChallenge.fromFirestore(doc))
          .toList();
          
      // If not enough recommendations, fill with popular ones
      if (recommendations.length < limit) {
        final popular = await getPopularChallenges(limit: limit - recommendations.length);
        recommendations.addAll(popular);
      }
      
      return recommendations;
    } catch (e) {
      // Fallback to popular on error
      return getPopularChallenges(limit: limit);
    }
  }

  /// Get popular challenges (sorted by participant count)
  Future<List<EcoChallenge>> getPopularChallenges({int limit = 3}) async {
    try {
      final snapshot = await _challengesCollection
          .where('isActive', isEqualTo: true)
          .orderBy('participantCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => EcoChallenge.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching popular challenges: $e');
      return [];
    }
  }

  /// Search and filter challenges
  Future<List<EcoChallenge>> searchChallenges({
    String? query,
    ChallengeCategory? category,
    ChallengeDifficulty? difficulty,
  }) async {
    try {
      Query queryRef = _challengesCollection.where('isActive', isEqualTo: true);

      if (category != null) {
        queryRef = queryRef.where('category', isEqualTo: category.name);
      }

      if (difficulty != null) {
        queryRef = queryRef.where('difficulty', isEqualTo: difficulty.name);
      }

      final snapshot = await queryRef.get();
      
      var results = snapshot.docs
          .map((doc) => EcoChallenge.fromFirestore(doc))
          .toList();

      // Client-side text search (Firestore doesn't support native full-text search)
      if (query != null && query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        results = results.where((challenge) {
          return challenge.title.toLowerCase().contains(lowercaseQuery) ||
                 challenge.description.toLowerCase().contains(lowercaseQuery);
        }).toList();
      }

      return results;
    } catch (e) {
      throw Exception('Failed to search challenges: $e');
    }
  }

  /// Get Daily Challenge (Deterministic based on date)
  Future<EcoChallenge?> getDailyChallenge() async {
    try {
      // Get all active challenges
      final challenges = await getActiveChallenges();
      if (challenges.isEmpty) return null;

      // Use current date as seed for deterministic random selection
      final now = DateTime.now();
      final seed = now.year * 10000 + now.month * 100 + now.day;
      final random = Random(seed);

      // Select one challenge
      final index = random.nextInt(challenges.length);
      return challenges[index];
    } catch (e) {
      print('Error fetching daily challenge: $e');
      return null;
    }
  }

  /// Get Weekly Challenges (Deterministic based on week number)
  Future<List<EcoChallenge>> getWeeklyChallenges({int limit = 3}) async {
    try {
      // Get all active challenges
      final challenges = await getActiveChallenges();
      if (challenges.isEmpty) return [];

      // Use current week number as seed
      final now = DateTime.now();
      // Simple week number calculation
      final dayOfYear = int.parse('${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}');
      final weekNumber = (dayOfYear / 7).floor();
      
      final seed = weekNumber;
      final random = Random(seed);

      // Shuffle list deterministically
      final shuffled = List<EcoChallenge>.from(challenges)..shuffle(random);
      
      // Return top N
      return shuffled.take(limit).toList();
    } catch (e) {
      print('Error fetching weekly challenges: $e');
      return [];
    }
  }

  // ==================== USER CHALLENGE PROGRESS ====================

  /// Join a challenge
  Future<ChallengeProgress> joinChallenge({
    required String userId,
    required String challengeId,
    required double targetProgress,
  }) async {
    try {
      final progress = ChallengeProgress(
        userId: userId,
        challengeId: challengeId,
        currentProgress: 0.0,
        targetProgress: targetProgress,
        joinedAt: DateTime.now(),
      );

      await _userChallengeProgress(userId)
          .doc(challengeId)
          .set(progress.toFirestore());

      // Increment participant count
      await incrementParticipants(challengeId);

      return progress;
    } catch (e) {
      throw Exception('Failed to join challenge: $e');
    }
  }

  /// Get user's challenge progress
  Future<ChallengeProgress?> getUserChallengeProgress({
    required String userId,
    required String challengeId,
  }) async {
    try {
      final doc =
          await _userChallengeProgress(userId).doc(challengeId).get();
      if (!doc.exists) return null;
      return ChallengeProgress.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user challenge progress: $e');
    }
  }

  /// Get all user's active challenges
  Future<List<ChallengeProgress>> getUserActiveChallenges(
    String userId,
  ) async {
    try {
      final snapshot = await _userChallengeProgress(userId)
          .where('isCompleted', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) => ChallengeProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user active challenges: $e');
    }
  }

  /// Get all user's completed challenges
  Future<List<ChallengeProgress>> getUserCompletedChallenges(
    String userId,
  ) async {
    try {
      final snapshot = await _userChallengeProgress(userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ChallengeProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user completed challenges: $e');
    }
  }

  /// Update challenge progress
  Future<void> updateChallengeProgress({
    required String userId,
    required String challengeId,
    required double progress,
  }) async {
    try {
      final currentProgress = await getUserChallengeProgress(
        userId: userId,
        challengeId: challengeId,
      );

      if (currentProgress == null) {
        throw Exception('User not enrolled in challenge');
      }

      final newProgress = currentProgress.currentProgress + progress;
      final updates = <String, dynamic>{
        'currentProgress': newProgress,
      };

      // Check if challenge should be completed
      if (newProgress >= currentProgress.targetProgress &&
          !currentProgress.isCompleted) {
        updates['isCompleted'] = true;
        updates['completedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _userChallengeProgress(userId).doc(challengeId).update(updates);
    } catch (e) {
      throw Exception('Failed to update challenge progress: $e');
    }
  }

  /// Leave a challenge
  Future<void> leaveChallenge({
    required String userId,
    required String challengeId,
  }) async {
    try {
      await _userChallengeProgress(userId).doc(challengeId).delete();
      
      // Decrement participant count
      await _challengesCollection.doc(challengeId).update({
        'participantCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to leave challenge: $e');
    }
  }

  /// Stream of user's active challenges
  Stream<List<ChallengeProgress>> watchUserActiveChallenges(String userId) {
    return _userChallengeProgress(userId)
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChallengeProgress.fromFirestore(doc))
            .toList());
  }

  /// Get challenge statistics for user
  Future<Map<String, dynamic>> getChallengeStatistics(String userId) async {
    try {
      final active = await getUserActiveChallenges(userId);
      final completed = await getUserCompletedChallenges(userId);

      return {
        'activeChallenges': active.length,
        'completedChallenges': completed.length,
        'totalChallenges': active.length + completed.length,
      };
    } catch (e) {
      throw Exception('Failed to get challenge statistics: $e');
    }
  }
}

/// Provider for ChallengeRepository
final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(
    firestore: FirebaseFirestore.instance,
  );
});
