import 'package:flutter_test/flutter_test.dart';
import 'package:ecosphare/features/auth/domain/user.dart';

void main() {
  DateTime now() => DateTime(2026, 1, 1, 12);

  group('AppUser', () {
    test('creates a user with required fields and sensible defaults', () {
      final createdAt = now();
      final updatedAt = now();
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoURL: 'https://example.com/photo.jpg',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(user.uid, 'test-uid-123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.photoURL, 'https://example.com/photo.jpg');
      expect(user.emailVerified, false);
      expect(user.createdAt, createdAt);
      expect(user.updatedAt, updatedAt);
      expect(user.preferredLanguage, 'en');
      expect(user.isDarkMode, false);
      expect(user.preferredUnits, 'metric');
      expect(user.level, 1);
      expect(user.experiencePoints, 0);
      expect(user.points, 0);
      expect(user.totalCarbonSaved, 0.0);
      expect(user.totalActivitiesLogged, 0);
      expect(user.currentStreak, 0);
      expect(user.challengesCompleted, 0);
      expect(user.unlockedBadgeIds, isEmpty);
    });

    test('stores gamification fields', () {
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        createdAt: now(),
        updatedAt: now(),
        level: 5,
        experiencePoints: 1000,
        points: 500,
        totalCarbonSaved: 100.5,
        totalActivitiesLogged: 25,
        currentStreak: 7,
        challengesCompleted: 3,
      );

      expect(user.level, 5);
      expect(user.experiencePoints, 1000);
      expect(user.points, 500);
      expect(user.totalCarbonSaved, 100.5);
      expect(user.totalActivitiesLogged, 25);
      expect(user.currentStreak, 7);
      expect(user.challengesCompleted, 3);
    });

    test('stores preferences and unlocked badges', () {
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        createdAt: now(),
        updatedAt: now(),
        preferredUnits: 'imperial',
        isDarkMode: true,
        preferredLanguage: 'es',
        unlockedBadgeIds: const ['badge1', 'badge2', 'badge3'],
      );

      expect(user.preferredUnits, 'imperial');
      expect(user.isDarkMode, true);
      expect(user.preferredLanguage, 'es');
      expect(user.unlockedBadgeIds, ['badge1', 'badge2', 'badge3']);
    });

    test('serialises to a Firestore map', () {
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: now(),
        updatedAt: now(),
        level: 3,
        experiencePoints: 500,
      );

      final map = user.toFirestore();

      expect(map['email'], 'test@example.com');
      expect(map['displayName'], 'Test User');
      expect(map['level'], 3);
      expect(map['experiencePoints'], 500);
      expect(map['createdAt'], isNotNull);
      expect(map['updatedAt'], isNotNull);
      expect(map['unlockedBadgeIds'], isEmpty);
    });

    test('copyWith updates provided fields and preserves the rest', () {
      final createdAt = now();
      final updatedAt = now();
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        createdAt: createdAt,
        updatedAt: updatedAt,
        level: 2,
        points: 10,
      );

      final updated = user.copyWith(level: 3, points: 25);

      expect(updated.uid, 'test-uid-123');
      expect(updated.email, 'test@example.com');
      expect(updated.createdAt, createdAt);
      expect(updated.level, 3);
      expect(updated.points, 25);
    });

    test('copyWith refreshes updatedAt when one is not supplied', () {
      final user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        createdAt: now(),
        updatedAt: DateTime(2020),
      );

      final updated = user.copyWith(level: 2);

      expect(updated.updatedAt.isAfter(DateTime(2020)), true);
    });

    test('is equal when every field matches', () {
      final createdAt = now();
      final updatedAt = now();

      AppUser build() => AppUser(
            uid: 'test-uid-123',
            email: 'test@example.com',
            createdAt: createdAt,
            updatedAt: updatedAt,
            unlockedBadgeIds: const ['badge1'],
          );

      expect(build(), equals(build()));
      expect(build().hashCode, build().hashCode);
      expect(build() == build().copyWith(level: 2), false);
    });
  });
}
