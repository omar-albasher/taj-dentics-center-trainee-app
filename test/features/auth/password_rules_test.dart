import 'package:flutter_test/flutter_test.dart';
import 'package:trainee_app/features/auth/domain/password_rules.dart';

void main() {
  group('PasswordRules.validateCurrent', () {
    test('rejects empty value', () {
      expect(PasswordRules.validateCurrent(null), isNotNull);
      expect(PasswordRules.validateCurrent(''), isNotNull);
    });

    test('accepts any non-empty value', () {
      expect(PasswordRules.validateCurrent('123'), isNull);
    });
  });

  group('PasswordRules.validateNew', () {
    test('rejects empty value', () {
      expect(PasswordRules.validateNew(null, current: 'Old@1234'), isNotNull);
      expect(PasswordRules.validateNew('', current: 'Old@1234'), isNotNull);
    });

    test('rejects value shorter than 8 characters', () {
      expect(PasswordRules.validateNew('Aa1', current: 'Old@1234'), isNotNull);
      expect(PasswordRules.validateNew('Aa12345', current: 'Old@1234'),
          isNotNull);
    });

    test('rejects letters-only value', () {
      expect(PasswordRules.validateNew('abcdefgh', current: 'Old@1234'),
          isNotNull);
    });

    test('rejects digits-only value', () {
      expect(PasswordRules.validateNew('12345678', current: 'Old@1234'),
          isNotNull);
    });

    test('rejects value equal to current password', () {
      expect(PasswordRules.validateNew('New@1234', current: 'New@1234'),
          isNotNull);
    });

    test('accepts a valid mixed value of at least 8 characters', () {
      expect(PasswordRules.validateNew('New@1234', current: 'Old@1234'), isNull);
      expect(PasswordRules.validateNew('abcdefg1', current: 'Old@1234'), isNull);
    });
  });

  group('PasswordRules.validateConfirm', () {
    test('rejects empty value', () {
      expect(PasswordRules.validateConfirm(null, password: 'New@1234'),
          isNotNull);
      expect(PasswordRules.validateConfirm('', password: 'New@1234'),
          isNotNull);
    });

    test('rejects mismatched confirmation', () {
      expect(PasswordRules.validateConfirm('New@1235', password: 'New@1234'),
          isNotNull);
    });

    test('accepts matching confirmation', () {
      expect(PasswordRules.validateConfirm('New@1234', password: 'New@1234'),
          isNull);
    });
  });
}
