import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime? {
  String toCustomFormat() {
    if (this == null) return "";
    return DateFormat('yyyy/MM/dd', 'ar').format(this!);
  }
  // make another show minutes :seconds beside

  String toCustomFormatWithTime() {
    if (this == null) return "";
    return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(this!);
  }
}
