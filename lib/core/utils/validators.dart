abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final _phoneRegex = RegExp(r'^[+()\d\s-]{7,20}$');

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? name(String? value) {
    final base = required(value, label: 'Full name');
    if (base != null) return base;
    if (value!.trim().length < 2) return 'Enter your full name';
    return null;
  }

  static String? email(String? value) {
    final base = required(value, label: 'Email');
    if (base != null) return base;
    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final base = required(value, label: 'Password');
    if (base != null) return base;
    if (value!.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Include at least one letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) return 'Include at least one number';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final base = required(value, label: 'Confirm password');
    if (base != null) return base;
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? minLength(
    String? value,
    int length, {
    String label = 'This field',
  }) {
    final base = required(value, label: label);
    if (base != null) return base;
    if (value!.trim().length < length) {
      return '$label must be at least $length characters';
    }
    return null;
  }

  static String? jobDescription(String? value) {
    return minLength(value, 80, label: 'Job description');
  }

  static String? resumeText(String? value) {
    return minLength(value, 100, label: 'Resume text');
  }
}
