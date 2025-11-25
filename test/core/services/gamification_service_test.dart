import 'package:flutter_test/flutter_test.dart';
import 'package:ecosphare/core/services/gamification_service.dart';

void main() {
  late GamificationService service;

  setUp(() {
    service = GamificationService();
  });

  group('GamificationService Tests', () {
    group('Level System', () {
      test('should calculate correct level from XP', () {
        expect(service.calculateLevel(0), 1);
        expect(service.calculateLevel(100), 2);
        expect(service.calculateLevel(300), 3);
        expect(service.calculateLevel(600), 4);
        expect(service.calculateLevel(10000), 10); // Max level
      });

      test('should return correct level title', () {
        expect(service.getLevelTitle(1), 'Eco Newbie');
        expect(service.getLevelTitle(3), 'Green Enthusiast');
        expect(service.getLevelTitle(5), 'Sustainability Star');
        expect(service.getLevelTitle(10), 'Climate Champion');
      });

      test('should return correct level color', () {
        final color1 = service.getLevelColor(1);
        final color5 = service.getLevelColor(5);
        final color10 = service.getLevelColor(10);

        expect(color1, isNotEmpty);
        expect(color5, isNotEmpty);
        expect(color10, isNotEmpty);
        expect(color1, isNot(equals(color10)));
      });

      test('should calculate XP required for next level', () {
        expect(service.getXPForNextLevel(1), 100);
        expect(service.getXPForNextLevel(2), 200);
        expect(service.getXPForNextLevel(3), 300);
      });

      test('should calculate level progress correctly', () {
        final progress = service.getLevelProgress(150);
        
        expect(progress['currentLevel'], 2);
        expect(progress['xpInCurrentLevel'], 50);
        expect(progress['xpForNextLevel'], 200);
        expect(progress['progress'], closeTo(0.25, 0.01));
      });

      test('should handle max level correctly', () {
        final progress = service.getLevelProgress(10000);
        expect(progress['currentLevel'], 10);
        expect(progress['isMaxLevel'], true);
      });
    });

    group('XP Rewards', () {
      test('should return correct XP for activity', () {
        expect(service.getActivityXP('logged_activity'), 10);
        expect(service.getActivityXP('completed_challenge'), 50);
        expect(service.getActivityXP('shared_activity'), 5);
      });

      test('should calculate streak bonus correctly', () {
        expect(service.getStreakBonus(1), 0);
        expect(service.getStreakBonus(3), 10);
        expect(service.getStreakBonus(7), 25);
        expect(service.getStreakBonus(30), 100);
      });

      test('should calculate total XP with bonuses', () {
        final baseXP = 10;
        final streakBonus = service.getStreakBonus(7);
        final total = baseXP + streakBonus;

        expect(total, 35); // 10 base + 25 streak bonus
      });
    });

    group('Unlockable Features', () {
      test('should return correct unlocks for each level', () {
        final level1Unlocks = service.getUnlocksForLevel(1);
        final level3Unlocks = service.getUnlocksForLevel(3);
        final level5Unlocks = service.getUnlocksForLevel(5);

        expect(level1Unlocks, isNotEmpty);
        expect(level3Unlocks, contains('Social Features'));
        expect(level5Unlocks, contains('Advanced Challenges'));
      });

      test('should check if feature is unlocked', () {
        expect(service.isFeatureUnlocked(1, 'Basic Tracking'), true);
        expect(service.isFeatureUnlocked(1, 'Social Features'), false);
        expect(service.isFeatureUnlocked(3, 'Social Features'), true);
      });
    });

    group('Edge Cases', () {
      test('should handle negative XP gracefully', () {
        expect(service.calculateLevel(-100), 1);
      });

      test('should handle extremely large XP', () {
        expect(service.calculateLevel(1000000), 10);
      });

      test('should handle zero streak', () {
        expect(service.getStreakBonus(0), 0);
      });

      test('should handle invalid level numbers', () {
        expect(() => service.getLevelTitle(0), returnsNormally);
        expect(() => service.getLevelTitle(100), returnsNormally);
      });
    });
  });
}
