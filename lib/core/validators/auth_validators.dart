/// Reusable validators for the authentication forms (SRS 1.6.1).
/// Return null for "valid" and a user-facing message for "invalid", matching
/// Flutter's TextFormField.validator contract.
class AuthValidators {
  AuthValidators._();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // Pakistani mobile numbers: 03XXXXXXXXX (11 digits) or +923XXXXXXXXX.
  // Spaces/dashes are stripped before matching so "0300-1234567" also works.
  static final _phoneRegex = RegExp(r'^(?:\+92|0)3\d{9}$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  static String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Full name is required';
    if (name.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? phone(String? value) {
    final raw = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (raw.isEmpty) return 'Phone number is required';
    if (!_phoneRegex.hasMatch(raw)) {
      return 'Enter a valid number, e.g. 03001234567';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain a lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain a number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  /// 0-4 score used to drive the strength indicator bar. Purely a UX signal;
  /// the actual policy is enforced by [password] above.
  static int strength(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password) || password.length >= 12) {
      score++;
    }
    return score;
  }
}
