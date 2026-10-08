/// Input rules shared by activity creation and the custom-entry form.
class ActivityQuantity {
  // Keep item counts exact on both native Dart and JavaScript targets.
  static const maxWholeItems = 9007199254740991;

  static String? validate(double quantity, {bool wholeItems = false}) {
    if (!quantity.isFinite) return 'Please enter a finite number';
    if (quantity <= 0) return 'Value must be greater than 0';
    if (wholeItems) {
      if (quantity != quantity.truncateToDouble()) {
        return 'Please enter a whole number of items';
      }
      if (quantity > maxWholeItems) return 'Value is too large';
    }
    return null;
  }

  static String? validateText(String? value, {bool wholeItems = false}) {
    if (value == null || value.trim().isEmpty) return 'Please enter a value';
    final quantity = double.tryParse(value);
    if (quantity == null) return 'Please enter a valid number';
    final error = validate(quantity, wholeItems: wholeItems);
    if (error != null || !wholeItems) return error;

    // A double can round a fractional input to an integer. Check the original
    // decimal digits as well, so shopping never silently drops part of an item.
    final match = RegExp(r'^\+?(\d*)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$')
        .firstMatch(value.trim());
    if (match == null) return 'Please enter a whole number of items';
    final fraction = match[2] ?? '';
    final exponent = int.tryParse(match[3] ?? '0');
    if (exponent == null) return 'Please enter a whole number of items';
    final fractionalDigits = fraction.length - exponent;
    if (fractionalDigits > 0) {
      final digits = '${match[1]}$fraction';
      final start = (digits.length - fractionalDigits).clamp(0, digits.length);
      if (digits.substring(start).contains(RegExp(r'[1-9]'))) {
        return 'Please enter a whole number of items';
      }
    }
    return null;
  }
}
