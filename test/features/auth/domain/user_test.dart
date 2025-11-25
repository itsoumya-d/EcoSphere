import 'package:flutter_test/flutter_test.dart';
import 'package:ecosphare/features/auth/domain/user.dart';

void main() {
  group('AppUser Model Tests', () {
    test('should create AppUser with all required fields', () {
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoURL: 'https://example.com/photo.jpg',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      expect(user.uid, 'test-uid-123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.level, 1); // Default level
      expect(user.experiencePoints, 0); // Default XP
      expect(user.points, 0); // Default points
    });

    test('should create AppUser with gamification fields', () {
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        level: 5,
        experiencePoints: 1000,
        points: 500,
        totalCarbonSaved: 100.5,
      );

      expect(user.level, 5);
      expect(user.experiencePoints, 1000);
      expect(user.points, 500);
      expect(user.totalCarbonSaved, 100.5);
    });

    test('should convert AppUser to Firestore map', () {
      final now = DateTime.now();
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: now,
        lastLoginAt: now,
        level: 3,
        experiencePoints: 500,
      );

      final map = user.toFirestore();

      expect(map['email'], 'test@example.com');
      expect(map['displayName'], 'Test User');
      expect(map['level'], 3);
      expect(map['experiencePoints'], 500);
      expect(map['createdAt'], isNotNull);
    });

    test('should handle unlocked badges list', () {
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        unlockedBadgeIds: ['badge1', 'badge2', 'badge3'],
      );

      expect(user.unlockedBadgeIds.length, 3);
      expect(user.unlockedBadgeIds, contains('badge1'));
    });

    test('should handle user preferences', () {
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        preferredUnits: 'imperial',
      );

      expect(user.preferredUnits, 'imperial');
    });

    test('should calculate total activities logged', () {
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        totalActivitiesLogged: 25,
      );

      expect(user.totalActivitiesLogged, 25);
    });

    test('should track current streak', () {
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        currentStreak: 7,
        longestStreak: 14,
      );

      expect(user.currentStreak, 7);
      expect(user.longestStreak, 14);
    });
  });
}
