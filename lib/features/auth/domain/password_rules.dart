class PasswordRules {
  PasswordRules._();

  static const int minLength = 8;

  static String? validateCurrent(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور الحالية';
    }
    return null;
  }

  static String? validateNew(String? value, {required String current}) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور الجديدة';
    }
    if (value.length < minLength) {
      return 'كلمة المرور يجب أن لا تقل عن $minLength خانات';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'يجب أن تجمع كلمة المرور بين أحرف وأرقام';
    }
    if (value == current) {
      return 'كلمة المرور الجديدة يجب أن تختلف عن الحالية';
    }
    return null;
  }

  static String? validateConfirm(String? value, {required String password}) {
    if (value == null || value.isEmpty) {
      return 'يرجى تأكيد كلمة المرور الجديدة';
    }
    if (value != password) {
      return 'تأكيد كلمة المرور غير مطابق';
    }
    return null;
  }
}
