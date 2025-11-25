import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/user.dart';
import '../domain/leaderboard_entry.dart';

/// Repository for fetching leaderboard data
class LeaderboardRepository {
  final FirebaseFirestore _firestore;

  LeaderboardRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Get top users by XP
  Future<List<LeaderboardEntry>> getTopUsersByXp({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('experiencePoints', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.asMap().entries.map((entry) {
        final index = entry.key;
        final doc = entry.value;
        final user = AppUser.fromFirestore(doc);
        return LeaderboardEntry.fromUser(user, index + 1, useCarbon: false);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch XP leaderboard: $e');
    }
  }

  /// Get top users by Carbon Saved
  Future<List<LeaderboardEntry>> getTopUsersByCarbon({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('totalCarbonSaved', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.asMap().entries.map((entry) {
        final index = entry.key;
        final doc = entry.value;
        final user = AppUser.fromFirestore(doc);
        return LeaderboardEntry.fromUser(user, index + 1, useCarbon: true);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch Carbon leaderboard: $e');
    }
  }
}

/// Provider for LeaderboardRepository
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(firestore: FirebaseFirestore.instance);
});
