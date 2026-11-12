import 'package:easy_localization/easy_localization.dart';

enum ShiftStatusEnum {
  open('open'),
  closed('closed'),
  closedPendingApproval('closed_pending_approval'),
  forceClosed('force_closed');

  final String value;
  const ShiftStatusEnum(this.value);

  static ShiftStatusEnum fromValue(String? val) {
    if (val == null) return ShiftStatusEnum.open;
    for (final status in ShiftStatusEnum.values) {
      if (status.value.toLowerCase() == val.toLowerCase() ||
          status.name.toLowerCase() == val.toLowerCase()) {
        return status;
      }
    }
    return ShiftStatusEnum.open;
  }

  String get translationKey {
    switch (this) {
      case ShiftStatusEnum.open:
        return 'cashier_shift_active';
      case ShiftStatusEnum.closed:
        return 'cashier_balanced';
      case ShiftStatusEnum.closedPendingApproval:
        return 'cashier_pending_approval';
      case ShiftStatusEnum.forceClosed:
        return 'cashier_force_close_shift';
    }
  }

  String get localizedName => translationKey.tr();
}
