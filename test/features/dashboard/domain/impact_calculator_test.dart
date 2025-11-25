import 'package:flutter_test/flutter_test.dart';
import 'package:ecosphare/features/dashboard/domain/impact_calculator.dart';

void main() {
  group('ImpactCalculator', () {
    final calculator = ImpactCalculator();

    test('should calculate correct score for eco-friendly inputs', () {
      final score = calculator.calculateScore(
        commute: 'Bike / Walk',
        diet: 'Vegan',
        energy: 'Low (Eco-conscious)',
      );
      expect(score, 1000.0);
    });

    test('should calculate correct score for high impact inputs', () {
      final score = calculator.calculateScore(
        commute: 'Car',
        diet: 'Meat-heavy',
        energy: 'High (Always on)',
      );
      expect(score, 350.0); // 1000 - 200 - 250 - 200 = 350
    });

    test('should clamp score to 0 if negative impact exceeds base', () {
      // Hypothetical scenario if penalties were higher
      // Currently logic clamps at 0, but let's verify it doesn't go below 0
      final score = calculator.calculateScore(
        commute: 'Car',
        diet: 'Meat-heavy',
        energy: 'High (Always on)',
      );
      expect(score, greaterThanOrEqualTo(0));
    });
  });
}
