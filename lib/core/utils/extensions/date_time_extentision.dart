import 'package:eyadty/core/utils/helpers/app_formatter_helper.dart';

extension DateTimeExtension on DateTime? {
  /// Formats to unified Latin digits: "2026/01/25"
  String toCustomFormat() {
    if (this == null) return "";
    return AppFormatterHelper.formatDate(this!);
  }

  /// Formats to unified Latin digits with time: "2026/01/25 - 02:30 م"
  String toCustomFormatWithTime() {
    if (this == null) return "";
    return AppFormatterHelper.formatDateTime(this!);
  }
}
