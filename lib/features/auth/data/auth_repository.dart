import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user.dart';

/// Repository for managing user data in Firestore
class AuthRepository {
  final FirebaseFirestore _firestore;

  AuthRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  /// Users collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Get user document by UID
  DocumentReference _userDoc(String uid) => _usersCollection.doc(uid);

  /// Create new user in Firestore
  Future<AppUser> createUser(AppUser user) async {
    try {
      await _userDoc(user.uid).set(user.toFirestore());
      return user;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Get user by UID
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Stream of user data
  Stream<AppUser?> watchUser(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  /// Update user
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _userDoc(uid).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _userDoc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Update user stats (called after activities/challenges)
  Future<void> updateUserStats({
    required String uid,
    double? carbonSavedDelta,
    int? activitiesLoggedDelta,
    int? experiencePointsDelta,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (carbonSavedDelta != null) {
        updates['totalCarbonSaved'] = FieldValue.increment(carbonSavedDelta);
      }
      if (activitiesLoggedDelta != null) {
        updates['totalActivitiesLogged'] = FieldValue.increment(activitiesLoggedDelta);
      }
      if (experiencePointsDelta != null) {
        updates['experiencePoints'] = FieldValue.increment(experiencePointsDelta);
        
        // Calculate level from XP (100 XP per level for now)
        final currentUser = await getUser(uid);
        if (currentUser != null) {
          final newXP = currentUser.experiencePoints + experiencePointsDelta;
          final newLevel = (newXP / 100).floor() + 1;
          if (newLevel > currentUser.level) {
            updates['level'] = newLevel;
          }
        }
      }

      if (updates.isNotEmpty) {
        await updateUser(uid, updates);
      }
    } catch (e) {
      throw Exception('Failed to update user stats: $e');
    }
  }

  /// Update user streak
  Future<void> updateStreak(String uid, int streak) async {
    await updateUser(uid, {'currentStreak': streak});
  }

  /// Update user preferences
  Future<void> updatePreferences({
    required String uid,
    String? language,
    bool? darkMode,
    String? units,
  }) async {
    final updates = <String, dynamic>{};
    
    if (language != null) updates['preferredLanguage'] = language;
    if (darkMode != null) updates['isDarkMode'] = darkMode;
    if (units != null) updates['preferredUnits'] = units;

    if (updates.isNotEmpty) {
      await updateUser(uid, updates);
    }
  }

  /// Check if user exists
  Future<bool> userExists(String uid) async {
    final doc = await _userDoc(uid).get();
    return doc.exists;
  }
}

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firestore: FirebaseFirestore.instance,
  );
});
