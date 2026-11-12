import 'package:easy_localization/easy_localization.dart';

enum PrintFormat {
  a4('a4'),
  thermal80('thermal80');

  final String value;
  const PrintFormat(this.value);

  static PrintFormat fromString(String? val) {
    if (val == null) return PrintFormat.a4;
    for (final format in PrintFormat.values) {
      if (format.value.toLowerCase() == val.toLowerCase() ||
          format.name.toLowerCase() == val.toLowerCase()) {
        return format;
      }
    }
    return PrintFormat.a4; // Fallback to A4
  }

  String get titleKey {
    switch (this) {
      case PrintFormat.a4:
        return 'print_format_a4';
      case PrintFormat.thermal80:
        return 'print_format_thermal80';
    }
  }

  String get descKey {
    switch (this) {
      case PrintFormat.a4:
        return 'print_format_a4_desc';
      case PrintFormat.thermal80:
        return 'print_format_thermal80_desc';
    }
  }

  String get title => titleKey.tr();
  String get description => descKey.tr();
}
