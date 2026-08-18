import 'package:flutter_test/flutter_test.dart';

import 'package:eventease/core/validators/auth_validators.dart';

void main() {
  group('AuthValidators.email', () {
    test('returns required message for null', () {
      expect(AuthValidators.email(null), 'Email is required');
    });
    test('returns required message for empty', () {
      expect(AuthValidators.email(''), 'Email is required');
    });
    test('returns required message for whitespace only', () {
      expect(AuthValidators.email('   '), 'Email is required');
    });
    test('returns invalid message for missing domain', () {
      expect(AuthValidators.email('user@eventease'), isNotNull);
    });
    test('returns null for a valid email', () {
      expect(AuthValidators.email('user@eventease.demo'), isNull);
    });
    test('validates after trimming whitespace', () {
      expect(AuthValidators.email('  user@eventease.demo  '), isNull);
    });
  });

  group('AuthValidators.name', () {
    test('returns required for empty', () {
      expect(AuthValidators.name(''), 'Full name is required');
    });
    test('returns too-short for single character', () {
      expect(AuthValidators.name('A'), 'Name must be at least 2 characters');
    });
    test('returns null for a valid name', () {
      expect(AuthValidators.name('Alex Attendee'), isNull);
    });
  });

  group('AuthValidators.phone', () {
    test('returns required for empty', () {
      expect(AuthValidators.phone(''), 'Phone number is required');
    });
    test('rejects too-short number', () {
      expect(AuthValidators.phone('0300123'), isNotNull);
    });
    test('accepts 03XXXXXXXXX format', () {
      expect(AuthValidators.phone('03001234567'), isNull);
    });
    test('accepts +923XXXXXXXXX format', () {
      expect(AuthValidators.phone('+923001234567'), isNull);
    });
    test('accepts number with internal dash after stripping', () {
      expect(AuthValidators.phone('0300-1234567'), isNull);
    });
  });

  group('AuthValidators.password', () {
    test('returns required for empty', () {
      expect(AuthValidators.password(''), 'Password is required');
    });
    test('rejects short password', () {
      expect(AuthValidators.password('Ab1'), isNotNull);
    });
    test('rejects missing uppercase', () {
      expect(AuthValidators.password('lowercase1'), isNotNull);
    });
    test('rejects missing lowercase', () {
      expect(AuthValidators.password('UPPERCASE1'), isNotNull);
    });
    test('rejects missing digit', () {
      expect(AuthValidators.password('Uppercase'), isNotNull);
    });
    test('returns null for a valid password', () {
      expect(AuthValidators.password('Abcdef1!'), isNull);
    });
  });

  group('AuthValidators.confirmPassword', () {
    test('returns required for null', () {
      expect(AuthValidators.confirmPassword(null, 'Abcdef1!'),
          'Please confirm your password');
    });
    test('returns required for empty', () {
      expect(AuthValidators.confirmPassword('', 'Abcdef1!'),
          'Please confirm your password');
    });
    test('returns mismatch for different value', () {
      expect(AuthValidators.confirmPassword('nope', 'Abcdef1!'),
          'Passwords do not match');
    });
    test('returns null when matching', () {
      expect(AuthValidators.confirmPassword('Abcdef1!', 'Abcdef1!'), isNull);
    });
  });

  group('AuthValidators.strength', () {
    test('scores 0 for empty password', () {
      expect(AuthValidators.strength(''), 0);
    });
    test('scores 4 for a strong password (max score is 4)', () {
      expect(AuthValidators.strength('Abcdefgh1!'), 4);
    });
  });
}
