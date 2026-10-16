String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'يا ريت تكتب رقم الموبايل';
  }
  final clean = value.replaceAll(RegExp(r'\D'), '');
  if (clean.length < 8) {
    return 'رقم الموبايل يجب أن يتكون من 8 أرقام على الأقل';
  }

  return null;
}

String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'يا ريت تكتب اسمك';
  }
  if (value.length < 2) {
    return 'الاسم لازم يكون حرفين على الأقل';
  }
  return null;
}

String? validateEgyptPhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'يا ريت تكتب رقم الموبايل';
  }
  if (!RegExp(r'^01[0125]').hasMatch(value)) {
    return 'الرقم لازم يبدأ بـ 010 أو 011 أو 012 أو 015';
  }
  if (value.length != 11) {
    return 'الرقم لازم يكون 11 رقم';
  }

  return null;
}
