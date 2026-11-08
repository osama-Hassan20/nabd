class EgyptianPhoneHelper {
  EgyptianPhoneHelper._();

  /// Normalizes any representation of an Egyptian mobile number to standard stored format: `+20XXXXXXXXXX`.
  /// Accepts formats: `01012345678`, `1012345678`, `+201012345678`, `+20 10 1234 5678`, `00201012345678`.
  static String? normalize(String? phone) {
    if (phone == null) return null;
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return '';

    String digits = trimmed.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('0020')) {
      digits = digits.substring(4);
    } else if (digits.startsWith('20') && digits.length >= 12) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('0') && digits.length >= 11) {
      digits = digits.substring(1);
    }

    if (digits.length == 10 && RegExp(r'^1[0125]\d{8}$').hasMatch(digits)) {
      return '+20$digits';
    }

    if (digits.length == 10) {
      return '+20$digits';
    }

    return trimmed;
  }

  /// Validates if string is a valid Egyptian mobile number (11 digits national / 10 digits after +20).
  static bool isValid(String? phone) {
    if (phone == null) return false;
    final normalized = normalize(phone);
    if (normalized == null) return false;
    return RegExp(r'^\+201[0125]\d{8}$').hasMatch(normalized);
  }

  /// Formats for visual display e.g. "010 1234 5678".
  static String formatDisplay(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    final normalized = normalize(phone);
    if (normalized != null && RegExp(r'^\+201[0125]\d{8}$').hasMatch(normalized)) {
      final mobile = '0${normalized.substring(3)}'; // 01012345678
      return '${mobile.substring(0, 3)} ${mobile.substring(3, 7)} ${mobile.substring(7, 11)}';
    }
    return phone;
  }

  /// Formats for visual display with country code e.g. "+20 10 1234 5678".
  static String formatDisplayWithCode(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    final normalized = normalize(phone);
    if (normalized != null && RegExp(r'^\+201[0125]\d{8}$').hasMatch(normalized)) {
      const code = '+20';
      final prefix = normalized.substring(3, 5); // 10
      final mid = normalized.substring(5, 9);    // 1234
      final end = normalized.substring(9, 13);   // 5678
      return '$code $prefix $mid $end';
    }
    return phone;
  }
}

