import 'package:flutter_test/flutter_test.dart';
import 'package:ecosphare/core/constants/app_constants.dart';
import 'package:ecosphare/core/services/gamification_service.dart';

void main() {
  late GamificationService service;

  setUp(() {
    service = GamificationService();
  });

  group('GamificationService', () {
    group('calculateLevel', () {
      test('starts at level 1 for zero XP', () {
        expect(service.calculateLevel(0), 1);
      });

      test('advances one level per xpPerLevel', () {
        expect(service.calculateLevel(AppConstants.xpPerLevel), 2);
        expect(service.calculateLevel(AppConstants.xpPerLevel * 3), 4);
        expect(service.calculateLevel(AppConstants.xpPerLevel * 6), 7);
      });

      test('rounds partial XP down', () {
        expect(service.calculateLevel(99), 1);
        expect(service.calculateLevel(150), 2);
      });

      test('has no upper cap', () {
        expect(service.calculateLevel(10000), 101);
      });

      test('never drops below level 1 for negative XP', () {
        expect(service.calculateLevel(-100), 1);
      });
    });

    group('xpRequiredForLevel', () {
      test('scales linearly with the level', () {
        expect(service.xpRequiredForLevel(0), 0);
        expect(service.xpRequiredForLevel(1), 100);
        expect(service.xpRequiredForLevel(3), 300);
      });
    });

    group('getLevelProgress', () {
      test('reports progress within the current level', () {
        final progress = service.getLevelProgress(150);

        expect(progress['currentLevel'], 2);
        expect(progress['totalXP'], 150);
        expect(progress['xpInCurrentLevel'], 50);
        expect(progress['xpNeededForNext'], 100);
        expect(progress['xpForNextLevel'], 50);
        expect(progress['progress'], closeTo(0.5, 0.001));
      });

      test('reports zero progress at the start of a level', () {
        final progress = service.getLevelProgress(0);

        expect(progress['currentLevel'], 1);
        expect(progress['progress'], 0.0);
        expect(progress['xpForNextLevel'], 100);
      });
    });

    group('getLevelTitle', () {
      test('returns a title for every level band', () {
        expect(service.getLevelTitle(1), 'Eco Beginner');
        expect(service.getLevelTitle(5), 'Earth Friend');
        expect(service.getLevelTitle(10), 'Climate Advocate');
        expect(service.getLevelTitle(15), 'Eco Enthusiast');
        expect(service.getLevelTitle(20), 'Green Warrior');
        expect(service.getLevelTitle(30), 'Sustainability Expert');
        expect(service.getLevelTitle(40), 'Environmental Champion');
        expect(service.getLevelTitle(50), 'Eco Legend');
      });

      test('handles out-of-range levels without throwing', () {
        expect(() => service.getLevelTitle(0), returnsNormally);
        expect(() => service.getLevelTitle(1000), returnsNormally);
      });
    });

    group('getLevelColor', () {
      test('returns the documented color for each band', () {
        expect(service.getLevelColor(1), '#9E9E9E');
        expect(service.getLevelColor(10), '#2196F3');
        expect(service.getLevelColor(20), '#4CAF50');
        expect(service.getLevelColor(30), '#CD7F32');
        expect(service.getLevelColor(40), '#C0C0C0');
        expect(service.getLevelColor(50), '#FFD700');
      });
    });

    group('activity XP and points', () {
      test('rewards a bonus for carbon-saving activities', () {
        expect(service.calculateActivityXP(-10.0), 150);
        expect(service.calculateActivityXP(-2.5), 37);
      });

      test('rewards base XP for tracked emissions', () {
        expect(service.calculateActivityXP(10.0), 50);
        expect(service.calculateActivityXP(2.5), 12);
      });

      test('returns zero XP for zero impact', () {
        expect(service.calculateActivityXP(0), 0);
      });

      test('derives points from XP as a spendable fraction', () {
        expect(service.calculateActivityPoints(-10.0), 15);
        expect(service.calculateActivityPoints(10.0), 5);
        expect(service.calculateActivityPoints(0), 0);
      });
    });

    group('streak bonus', () {
      test('adds XP per streak day', () {
        expect(service.calculateStreakBonus(0), 0);
        expect(service.calculateStreakBonus(3), 15);
        expect(service.calculateStreakBonus(7), 35);
        expect(service.calculateStreakBonus(30), 150);
      });

      test('caps the bonus at maxStreakBonusDays', () {
        expect(service.calculateStreakBonus(40), 150);
      });
    });

    group('challenge XP and points', () {
      test('applies a difficulty multiplier to XP', () {
        expect(
          service.calculateChallengeXP(baseXP: 100, difficulty: 'easy'),
          100,
        );
        expect(
          service.calculateChallengeXP(baseXP: 100, difficulty: 'medium'),
          150,
        );
        expect(
          service.calculateChallengeXP(baseXP: 100, difficulty: 'hard'),
          200,
        );
        expect(
          service.calculateChallengeXP(baseXP: 100, difficulty: 'expert'),
          250,
        );
      });

      test('applies a first-completion bonus', () {
        expect(
          service.calculateChallengeXP(
            baseXP: 100,
            difficulty: 'easy',
            isFirstCompletion: true,
          ),
          120,
        );
      });

      test('applies a smaller multiplier to points', () {
        expect(
          service.calculateChallengePoints(basePoints: 100, difficulty: 'easy'),
          100,
        );
        expect(
          service.calculateChallengePoints(
            basePoints: 100,
            difficulty: 'medium',
          ),
          120,
        );
        expect(
          service.calculateChallengePoints(basePoints: 100, difficulty: 'hard'),
          150,
        );
        expect(
          service.calculateChallengePoints(
            basePoints: 100,
            difficulty: 'expert',
          ),
          200,
        );
      });
    });

    group('level ups', () {
      test('detects a level change', () {
        expect(service.didLevelUp(90, 110), true);
        expect(service.didLevelUp(110, 120), false);
      });

      test('awards points, a title, and unlocks on level up', () {
        final rewards = service.getLevelUpRewards(10);

        expect(rewards['points'], 500);
        expect(rewards['title'], 'Climate Advocate');
        expect(rewards['badge'], 'milestone_10');
        expect(rewards['unlocks'], contains('Advanced Statistics'));
      });

      test('does not award a milestone badge on non-milestone levels', () {
        expect(service.getLevelUpRewards(11)['badge'], isNull);
      });
    });

    group('calculateTotalPoints', () {
      test('sums all point sources', () {
        expect(
          service.calculateTotalPoints(
            activityPoints: 10,
            challengePoints: 50,
            streakBonus: 5,
          ),
          65,
        );
      });
    });

    group('checkBadgeEligibility', () {
      test('returns no badges for a brand new user', () {
        final badges = service.checkBadgeEligibility(
          totalXP: 0,
          carbonSaved: 0,
          activitiesLogged: 0,
          challengesCompleted: 0,
          streakDays: 0,
        );

        expect(badges, isEmpty);
      });

      test('awards badges across every category', () {
        final badges = service.checkBadgeEligibility(
          totalXP: 10000,
          carbonSaved: 1000,
          activitiesLogged: 365,
          challengesCompleted: 50,
          streakDays: 100,
        );

        expect(
          badges,
          containsAll([
            'xp_master',
            'carbon_hero',
            'year_round',
            'challenge_master',
            'century_streak',
          ]),
        );
      });
    });
  });
}
