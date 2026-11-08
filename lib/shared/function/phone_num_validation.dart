String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'يرجى إدخال رقم الهاتف';
  }
  final clean = value.replaceAll(RegExp(r'\D'), '');
  if (clean.length < 10) {
    return 'رقم الهاتف غير مكتمل';
  }

  return null;
}

String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'يرجى إدخال الاسم';
  }
  if (value.trim().length < 2) {
    return 'يجب أن يتكون الاسم من حرفين على الأقل';
  }
  return null;
}

String? validateEgyptPhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'يرجى إدخال رقم الهاتف';
  }
  final clean = value.replaceAll(RegExp(r'\D'), '');
  if (!RegExp(r'^(01[0125]\d{8}|1[0125]\d{8})$').hasMatch(clean)) {
    return 'الرقم يجب أن يبدأ بـ 010 أو 011 أو 012 أو 015 ويتكون من 11 رقمًا';
  }

  return null;
}
