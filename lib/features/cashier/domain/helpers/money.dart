class Money {
  final int piastres;

  const Money(this.piastres);
  const Money.zero() : piastres = 0;

  factory Money.fromPiastres(int piastres) => Money(piastres);

  factory Money.fromEgpString(String text) => Money.fromString(text);

  static int egpToPiastres(num pounds) => Money.fromPounds(pounds).piastres;

  factory Money.fromPounds(num pounds) {
    if (pounds is int) {
      return Money(pounds * 100);
    }
    final str = pounds.toStringAsFixed(4);
    final parsed = tryFromString(str, maxDecimals: 4);
    if (parsed != null) return parsed;
    return Money((pounds * 100).round());
  }

  static Money? tryFromString(String? text, {int maxDecimals = 2}) {
    if (text == null || text.trim().isEmpty) return const Money.zero();

    var normalized = text.trim();

    // 1. Convert Arabic-Indic / Hindi digits to Latin digits
    const hindi = '٠١٢٣٤٥٦٧٨٩';
    for (int i = 0; i < hindi.length; i++) {
      normalized = normalized.replaceAll(hindi[i], '$i');
    }

    // 2. Handle negative sign
    bool isNegative = false;
    if (normalized.startsWith('-')) {
      isNegative = true;
      normalized = normalized.substring(1).trim();
    }

    // 3. Normalize decimal separators
    normalized = normalized.replaceAll('٫', '.').replaceAll(',', '.');

    // 4. Exactly one decimal separator allowed
    final dotMatches = '.'.allMatches(normalized).length;
    if (dotMatches > 1) return null;

    final parts = normalized.split('.');
    final wholeStr = parts[0];
    if (wholeStr.isNotEmpty && !RegExp(r'^\d+$').hasMatch(wholeStr)) {
      return null;
    }
    final whole = wholeStr.isEmpty ? 0 : int.tryParse(wholeStr);
    if (whole == null) return null;

    int fractionPiastres = 0;
    if (parts.length == 2) {
      final fracStr = parts[1];
      if (fracStr.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fracStr)) {
        return null;
      }
      if (maxDecimals == 2 && fracStr.length > 2) {
        // Ambiguous input (e.g. 1,500 with 3 decimal digits or thousands separator)
        return null;
      }

      if (fracStr.length == 1) {
        fractionPiastres = (int.tryParse(fracStr) ?? 0) * 10;
      } else if (fracStr.length == 2) {
        fractionPiastres = int.tryParse(fracStr) ?? 0;
      } else if (fracStr.length > 2) {
        final twoDigits = int.tryParse(fracStr.substring(0, 2)) ?? 0;
        final thirdDigit = int.tryParse(fracStr[2]) ?? 0;
        fractionPiastres = twoDigits + (thirdDigit >= 5 ? 1 : 0);
      }
    }

    final total = whole * 100 + fractionPiastres;
    return Money(isNegative ? -total : total);
  }

  factory Money.fromString(String? text) {
    if (text == null || text.trim().isEmpty) return const Money.zero();
    final res = tryFromString(text);
    if (res == null) {
      throw FormatException('Invalid money format: $text');
    }
    return res;
  }

  double toPounds() => piastres / 100.0;

  String formatEgp() {
    final pounds = toPounds();
    return '${pounds.toStringAsFixed(2)} ج.م';
  }

  String get formattedEgp => formatEgp();

  Money operator +(Money other) => Money(piastres + other.piastres);
  Money operator -(Money other) => Money(piastres - other.piastres);
  Money operator *(num factor) => Money((piastres * factor).round());

  bool operator <(Money other) => piastres < other.piastres;
  bool operator <=(Money other) => piastres <= other.piastres;
  bool operator >(Money other) => piastres > other.piastres;
  bool operator >=(Money other) => piastres >= other.piastres;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Money && other.piastres == piastres);

  @override
  int get hashCode => piastres.hashCode;

  @override
  String toString() => '${toPounds().toStringAsFixed(2)} EGP ($piastres piastres)';
}
