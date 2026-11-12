import 'package:easy_localization/easy_localization.dart';

enum PrintDocumentType {
  paymentReceipt('paymentReceipt'),
  shiftReport('shiftReport'),
  prescription('prescription');

  final String value;
  const PrintDocumentType(this.value);

  static PrintDocumentType fromValue(String? val) {
    if (val == null) return PrintDocumentType.paymentReceipt;
    for (final doc in PrintDocumentType.values) {
      if (doc.value.toLowerCase() == val.toLowerCase() ||
          doc.name.toLowerCase() == val.toLowerCase()) {
        return doc;
      }
    }
    return PrintDocumentType.paymentReceipt;
  }

  String get titleKey {
    switch (this) {
      case PrintDocumentType.paymentReceipt:
        return 'print_doc_receipt';
      case PrintDocumentType.shiftReport:
        return 'print_doc_shift_report';
      case PrintDocumentType.prescription:
        return 'print_doc_prescription';
    }
  }

  String get descKey {
    switch (this) {
      case PrintDocumentType.paymentReceipt:
        return 'print_doc_receipt_desc';
      case PrintDocumentType.shiftReport:
        return 'print_doc_shift_report_desc';
      case PrintDocumentType.prescription:
        return 'print_doc_prescription_desc';
    }
  }

  String get title => titleKey.tr();
  String get description => descKey.tr();
}
