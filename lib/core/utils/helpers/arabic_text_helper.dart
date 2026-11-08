class ArabicTextHelper {
  ArabicTextHelper._();

  /// Normalizes Arabic text for fuzzy search:
  /// - Removes tashkeel / diacritics
  /// - Removes tatweel / kashida (\u0640)
  /// - Replaces [إأآ] with ا
  /// - Replaces ة with ه
  /// - Replaces ى with ي
  /// - Lowercases English characters and trims
  static String normalize(String? text) {
    if (text == null) return '';
    var result = text.trim();
    // Remove diacritics
    result = result.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    // Remove tatweel / kashida
    result = result.replaceAll('\u0640', '');
    // Normalize alefs
    result = result.replaceAll(RegExp(r'[إأآ]'), 'ا');
    // Normalize teh marbuta
    result = result.replaceAll('ة', 'ه');
    // Normalize alef maqsura
    result = result.replaceAll('ى', 'ي');
    return result.toLowerCase();
  }

  /// Checks if [source] contains [query] after Arabic normalization.
  static bool containsNormalized(String? source, String? query) {
    if (source == null || query == null) return false;
    final normSource = normalize(source);
    final normQuery = normalize(query);
    if (normQuery.isEmpty) return true;
    return normSource.contains(normQuery);
  }
}

