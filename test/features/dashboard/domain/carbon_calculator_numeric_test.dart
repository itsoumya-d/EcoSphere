import 'package:flutter_test/flutter_test.dart';
import 'package:ecosphare/features/dashboard/domain/emission_factors.dart';

void main() {
  final calculations = <String, double Function(double)>{
    'transportation': (value) =>
        CarbonCalculator.transportation(mode: 'car_gasoline', miles: value),
    'diet': (value) => CarbonCalculator.diet(foodType: 'beef', servings: value),
    'energy': (value) =>
        CarbonCalculator.energy(source: 'electricity_us_avg', kwh: value),
    'waste': (value) =>
        CarbonCalculator.waste(wasteType: 'recycled_paper', kg: value),
  };

  group('physical quantities', () {
    for (final entry in calculations.entries) {
      test('${entry.key} rejects negative and non-finite quantities', () {
        for (final value in [
          -1.0,
          double.nan,
          double.infinity,
          -double.infinity,
        ]) {
          expect(
            () => entry.value(value),
            throwsArgumentError,
            reason: '${entry.key} must reject $value',
          );
        }
      });

      test('${entry.key} accepts zero', () {
        expect(entry.value(0), 0);
      });
    }

    test('zero-emission factors still reject invalid quantities', () {
      for (final value in [double.nan, double.infinity, -1.0]) {
        expect(
          () => CarbonCalculator.transportation(mode: 'bike', miles: value),
          throwsArgumentError,
        );
        expect(
          () => CarbonCalculator.energy(
            source: 'electricity_renewable',
            kwh: value,
          ),
          throwsArgumentError,
        );
      }
      expect(CarbonCalculator.transportation(mode: 'bike', miles: 10), 0);
      expect(
        CarbonCalculator.energy(source: 'electricity_renewable', kwh: 25),
        0,
      );
    });

    test('shopping rejects negative counts without rejecting zero', () {
      expect(
        () => CarbonCalculator.shopping(item: 'laptop', quantity: -1),
        throwsArgumentError,
      );
      expect(CarbonCalculator.shopping(item: 'laptop', quantity: 0), 0);
      expect(CarbonCalculator.shopping(item: 'laptop', quantity: 2), 600);
    });

    test('finite input cannot overflow into an infinite impact', () {
      expect(
        () => CarbonCalculator.diet(foodType: 'beef', servings: 1e308),
        throwsArgumentError,
      );
      expect(
        () => CarbonCalculator.energy(source: 'heating_oil', kwh: 1e308),
        throwsArgumentError,
      );
      expect(
        () => CarbonCalculator.waste(wasteType: 'recycled_metal', kg: 1e308),
        throwsArgumentError,
      );
    });

    test('positive recycling quantities retain negative credits', () {
      expect(
        CarbonCalculator.waste(wasteType: 'recycled_paper', kg: 0.5),
        -0.5,
      );
      expect(CarbonCalculator.waste(wasteType: 'recycled_metal', kg: 2), -4);
    });
  });

  group('aggregates and scores', () {
    test('lifestyle estimates reject invalid physical inputs', () {
      for (final value in [double.nan, double.infinity, -1.0]) {
        expect(
          () => CarbonCalculator.estimateDailyFootprint(
            commuteMode: 'car_gasoline',
            commuteMiles: value,
            dietType: 'vegan',
            homeEnergy: 10,
          ),
          throwsArgumentError,
        );
        expect(
          () => CarbonCalculator.estimateDailyFootprint(
            commuteMode: 'bike',
            commuteMiles: 0,
            dietType: 'vegan',
            homeEnergy: value,
          ),
          throwsArgumentError,
        );
      }
    });

    test('yearly projections reject non-finite input and overflow', () {
      for (final value in [
        double.nan,
        double.infinity,
        -double.infinity,
        1e308,
        -1e308,
      ]) {
        expect(
          () => CarbonCalculator.dailyToYearly(value),
          throwsArgumentError,
        );
      }
      expect(CarbonCalculator.dailyToYearly(1.5), 547.5);
      expect(CarbonCalculator.dailyToYearly(-0.5), -182.5);
    });

    test('scores reject non-finite totals and preserve finite boundaries', () {
      for (final value in [double.nan, double.infinity, -double.infinity]) {
        expect(() => CarbonCalculator.toEcoScore(value), throwsArgumentError);
      }
      expect(CarbonCalculator.toEcoScore(-0.5), 1000);
      expect(CarbonCalculator.toEcoScore(0), 1000);
      expect(CarbonCalculator.toEcoScore(13.7), 1000);
      expect(CarbonCalculator.toEcoScore(28.75), closeTo(650, 0.0001));
      expect(CarbonCalculator.toEcoScore(43.8), 300);
      expect(CarbonCalculator.toEcoScore(100), 300);
    });
  });
}
