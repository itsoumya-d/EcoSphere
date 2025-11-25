import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_activity.dart';

/// Repository for managing user activities in Firestore
class ActivityRepository {
  final FirebaseFirestore _firestore;

  ActivityRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  /// Activities collection reference
  CollectionReference get _activitiesCollection => 
      _firestore.collection('activities');

  /// Create new activity
  Future<UserActivity> createActivity(UserActivity activity) async {
    try {
      final docRef = _activitiesCollection.doc(activity.id);
      await docRef.set(activity.toFirestore());
      return activity;
    } catch (e) {
      throw Exception('Failed to create activity: $e');
    }
  }

  /// Get activity by ID
  Future<UserActivity?> getActivity(String activityId) async {
    try {
      final doc = await _activitiesCollection.doc(activityId).get();
      if (!doc.exists) return null;
      return UserActivity.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get activity: $e');
    }
  }

  /// Get all activities for a user
  Future<List<UserActivity>> getUserActivities(String userId) async {
    try {
      final snapshot = await _activitiesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserActivity.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user activities: $e');
    }
  }

  /// Get activities for a user within a date range
  Future<List<UserActivity>> getActivitiesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _activitiesCollection
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserActivity.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activities by date range: $e');
    }
  }

  /// Get activities by type
  Future<List<UserActivity>> getActivitiesByType({
    required String userId,
    required ActivityType type,
    int? limit,
  }) async {
    try {
      Query query = _activitiesCollection
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserActivity.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activities by type: $e');
    }
  }

  /// Stream of user activities (real-time)
  Stream<List<UserActivity>> watchUserActivities(String userId) {
    return _activitiesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit for performance
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserActivity.fromFirestore(doc))
            .toList());
  }

  /// Update activity
  Future<void> updateActivity(
    String activityId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _activitiesCollection.doc(activityId).update(updates);
    } catch (e) {
      throw Exception('Failed to update activity: $e');
    }
  }

  /// Delete activity
  Future<void> deleteActivity(String activityId) async {
    try {
      await _activitiesCollection.doc(activityId).delete();
    } catch (e) {
      throw Exception('Failed to delete activity: $e');
    }
  }

  /// Calculate total carbon impact for a user
  Future<double> getTotalCarbonImpact(String userId) async {
    try {
      final activities = await getUserActivities(userId);
      return activities.fold<double>(
        0.0,
        (sum, activity) => sum + activity.carbonImpact,
      );
    } catch (e) {
      throw Exception('Failed to calculate total carbon impact: $e');
    }
  }

  /// Get carbon impact by date range
  Future<double> getCarbonImpactByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final activities = await getActivitiesByDateRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      
      return activities.fold<double>(
        0.0,
        (sum, activity) => sum + activity.carbonImpact,
      );
    } catch (e) {
      throw Exception('Failed to calculate carbon impact by date range: $e');
    }
  }

  /// Get breakdown by activity type
  Future<Map<ActivityType, double>> getCarbonBreakdown(String userId) async {
    try {
      final activities = await getUserActivities(userId);
      final Map<ActivityType, double> breakdown = {};

      for (final activity in activities) {
        breakdown[activity.type] = 
            (breakdown[activity.type] ?? 0.0) + activity.carbonImpact;
      }

      return breakdown;
    } catch (e) {
      throw Exception('Failed to get carbon breakdown: $e');
    }
  }

  /// Get overall activity statistics for a user
  Future<Map<String, dynamic>> getActivityStatistics(String userId) async {
    try {
      final activities = await getUserActivities(userId);
      final totalImpact = activities.fold<double>(
        0.0,
        (sum, activity) => sum + activity.carbonImpact,
      );

      return {
        'totalActivities': activities.length,
        'totalImpact': totalImpact,
      };
    } catch (e) {
      throw Exception('Failed to get activity statistics: $e');
    }
  }

  /// Get statistics for a time period
  Future<Map<String, dynamic>> getStatistics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final activities = await getActivitiesByDateRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      final totalImpact = activities.fold<double>(
        0.0,
        (sum, activity) => sum + activity.carbonImpact,
      );

      final breakdown = <ActivityType, double>{};
      for (final activity in activities) {
        breakdown[activity.type] = 
            (breakdown[activity.type] ?? 0.0) + activity.carbonImpact;
      }

      return {
        'totalActivities': activities.length,
        'totalCarbonImpact': totalImpact,
        'averageDailyImpact': totalImpact / (endDate.difference(startDate).inDays + 1),
        'breakdown': breakdown,
        'activities': activities,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
}

/// Provider for ActivityRepository
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(
    firestore: FirebaseFirestore.instance,
  );
});
