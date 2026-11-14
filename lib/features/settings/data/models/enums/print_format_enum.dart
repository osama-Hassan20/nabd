enum PrintFormat {
  a4,
  thermal80;

  static PrintFormat fromString(String? val) {
    if (val == 'thermal80') return PrintFormat.thermal80;
    return PrintFormat.a4;
  }

  static PrintFormat fromValue(String? val) => fromString(val);

  String get value => name;
}

enum PrintDocumentType {
  paymentReceipt,
  shiftReport,
  prescription;
}

