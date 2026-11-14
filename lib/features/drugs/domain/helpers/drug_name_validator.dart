class DrugNameValidator {
  static const int minLength = 2;
  static const int maxLength = 100;

  /// Sanitizes the name by trimming and collapsing multiple whitespace characters.
  static String sanitize(String? name) {
    if (name == null) return '';
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Returns true if the sanitized name meets all clinical drug name criteria.
  static bool isValid(String? name) {
    return validate(name) == null;
  }

  /// Returns null if valid, or an error key if invalid.
  static String? validate(String? name) {
    final sanitized = sanitize(name);
    if (sanitized.isEmpty) {
      return 'drugs_validation_name_required';
    }
    if (sanitized.length < minLength) {
      return 'drugs_validation_name_too_short';
    }
    if (sanitized.length > maxLength) {
      return 'drugs_validation_name_too_long';
    }

    // Reject pure numbers (e.g. '7', '123123')
    if (RegExp(r'^\d+$').hasMatch(sanitized)) {
      return 'drugs_validation_name_pure_digits';
    }

    // Reject pure symbols/punctuation: must contain at least one Arabic or Latin letter
    final hasLetter = RegExp(r'[\u0600-\u06FFA-Za-z]').hasMatch(sanitized);
    if (!hasLetter) {
      return 'drugs_validation_name_invalid_symbols';
    }

    return null;
  }
}
