import 'package:flutter_test/flutter_test.dart';
import 'package:ecosphare/features/dashboard/domain/activity_quantity.dart';

void main() {
  test('empty and malformed text report an input error', () {
    for (final value in [null, '', '  ', 'abc', '1.2.3']) {
      expect(ActivityQuantity.validateText(value), isNotNull);
    }
  });

  test('non-finite, negative and zero quantities are rejected', () {
    for (final value in ['NaN', 'Infinity', '-Infinity', '1e309', '-1', '0']) {
      expect(ActivityQuantity.validateText(value), isNotNull, reason: value);
    }
  });

  test('positive fractional measurements remain valid', () {
    for (final value in ['0.5', '2', ' 1.25 ', '1e2']) {
      expect(ActivityQuantity.validateText(value), isNull, reason: value);
    }
  });

  test('shopping accepts only exactly representable whole item counts', () {
    for (final value in [
      '0.5',
      '1.5',
      '1e308',
      '9007199254740992',
      '1.0000000000000001',
      '9007199254740990.5',
      '10.000000000000001e-1',
    ]) {
      expect(ActivityQuantity.validateText(value, wholeItems: true), isNotNull);
    }
    for (final value in [
      '1',
      '2.0',
      '9007199254740991',
      '1e2',
      '100e-2',
      '+.1e1',
    ]) {
      expect(ActivityQuantity.validateText(value, wholeItems: true), isNull);
    }
  });
}
