/// Input validation utilities for Kidnease application
class Validators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password (minimum 6 characters)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  /// Validate name (not empty)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }

    return null;
  }

  /// Validate positive number
  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number <= 0) {
      return '$fieldName must be greater than zero';
    }

    return null;
  }

  /// Validate number within range
  static String? validateNumberInRange(
    String? value,
    String fieldName,
    double min,
    double max,
  ) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number < min || number > max) {
      return '$fieldName must be between $min and $max';
    }

    return null;
  }

  /// Validate CKD stage (0-5, where 0 = Prevention/Healthy, 1-5 = CKD Stages)
  static String? validateCkdStage(int? value) {
    if (value == null) {
      return 'CKD stage is required';
    }

    if (value < 0 || value > 5) {
      return 'CKD stage must be between 0 and 5';
    }

    return null;
  }

  /// Validate KDIGO range for dietary limits
  static String? validateKdigoRange(
    double value,
    double reference,
    String nutrientName,
  ) {
    const minMultiplier = 0.5;
    const maxMultiplier = 2.0;

    final min = reference * minMultiplier;
    final max = reference * maxMultiplier;

    if (value < min || value > max) {
      return '$nutrientName should be between ${min.toStringAsFixed(0)} and ${max.toStringAsFixed(0)} (KDIGO recommended: ${reference.toStringAsFixed(0)})';
    }

    return null;
  }

  /// Check if string is not empty
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Check if value is a valid positive number
  static bool isPositiveNumber(String? value) {
    if (value == null || value.isEmpty) return false;
    final number = double.tryParse(value);
    return number != null && number > 0;
  }
}
