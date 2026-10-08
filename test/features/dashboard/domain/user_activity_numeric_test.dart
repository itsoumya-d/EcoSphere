import 'package:flutter_test/flutter_test.dart';
import 'package:ecosphare/features/dashboard/domain/user_activity.dart';

void main() {
  const categories = {
    ActivityType.transport: 'car_gasoline',
    ActivityType.diet: 'beef',
    ActivityType.energy: 'electricity_us_avg',
    ActivityType.waste: 'recycled_paper',
    ActivityType.shopping: 'laptop',
  };

  test('new activities reject invalid quantities before they can be saved', () {
    for (final entry in categories.entries) {
      for (final quantity in [
        double.nan,
        double.infinity,
        -double.infinity,
        -1.0,
        0.0,
      ]) {
        expect(
          () => UserActivity.create(
            userId: 'test-user',
            type: entry.key,
            category: entry.value,
            quantity: quantity,
          ),
          throwsArgumentError,
          reason: '${entry.key}: $quantity',
        );
      }
    }
  });

  test('shopping cannot silently truncate fractions or enormous counts', () {
    for (final quantity in [0.5, 1.5, 1e308]) {
      expect(
        () => UserActivity.create(
          userId: 'test-user',
          type: ActivityType.shopping,
          category: 'laptop',
          quantity: quantity,
        ),
        throwsArgumentError,
      );
    }
  });

  test('new activities reject non-finite calculated impacts', () {
    expect(
      () => UserActivity.create(
        userId: 'test-user',
        type: ActivityType.diet,
        category: 'beef',
        quantity: 1e308,
      ),
      throwsArgumentError,
    );
  });

  test('every quick-log preset retains a finite impact', () {
    for (var index = 0; index < QuickLogPresets.presets.length; index++) {
      final activity = QuickLogPresets.createFromPreset(index, 'test-user');
      expect(activity.quantity, greaterThan(0));
      expect(activity.carbonImpact.isFinite, isTrue);
    }
  });

  test('zero-emission transport and recycling savings stay valid', () {
    final bike = UserActivity.create(
      userId: 'test-user',
      type: ActivityType.transport,
      category: 'bike',
      quantity: 10,
    );
    final recycling = UserActivity.create(
      userId: 'test-user',
      type: ActivityType.waste,
      category: 'recycled_paper',
      quantity: 0.5,
    );
    expect(bike.carbonImpact, 0);
    expect(recycling.carbonImpact, -0.5);
    expect(recycling.toJson()['carbonImpact'], -0.5);
  });
}
