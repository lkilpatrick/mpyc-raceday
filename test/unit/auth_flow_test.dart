import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';

void main() {
  group('MemberRole', () {
    test('all roles exist', () {
      expect(MemberRole.values, hasLength(4));
      expect(MemberRole.values, contains(MemberRole.admin));
      expect(MemberRole.values, contains(MemberRole.pro));
      expect(MemberRole.values, contains(MemberRole.rcCrew));
      expect(MemberRole.values, contains(MemberRole.member));
    });

    test('role hierarchy: admin > pro > rcCrew > member', () {
      bool isAdminOrPro(MemberRole role) =>
          role == MemberRole.admin || role == MemberRole.pro;
      bool isRcOrAbove(MemberRole role) =>
          role == MemberRole.admin ||
          role == MemberRole.pro ||
          role == MemberRole.rcCrew;

      expect(isAdminOrPro(MemberRole.admin), true);
      expect(isAdminOrPro(MemberRole.pro), true);
      expect(isAdminOrPro(MemberRole.rcCrew), false);
      expect(isAdminOrPro(MemberRole.member), false);

      expect(isRcOrAbove(MemberRole.admin), true);
      expect(isRcOrAbove(MemberRole.pro), true);
      expect(isRcOrAbove(MemberRole.rcCrew), true);
      expect(isRcOrAbove(MemberRole.member), false);
    });
  });

  group('Member number validation', () {
    test('valid member numbers', () {
      expect(_isValidMemberNumber('100'), true);
      expect(_isValidMemberNumber('9999'), true);
      expect(_isValidMemberNumber('1'), true);
    });

    test('invalid member numbers', () {
      expect(_isValidMemberNumber(''), false);
      expect(_isValidMemberNumber('abc'), false);
      expect(_isValidMemberNumber(' '), false);
    });
  });

  group('Email masking', () {
    test('masks email correctly', () {
      expect(_maskEmail('john@example.com'), 'j***@example.com');
      expect(_maskEmail('ab@test.org'), 'a***@test.org');
    });

    test('handles short local part', () {
      expect(_maskEmail('a@b.com'), 'a***@b.com');
    });
  });

  group('Verification code validation', () {
    test('valid 6-digit codes', () {
      expect(_isValidCode('123456'), true);
      expect(_isValidCode('000000'), true);
      expect(_isValidCode('999999'), true);
    });

    test('invalid codes', () {
      expect(_isValidCode('12345'), false);
      expect(_isValidCode('1234567'), false);
      expect(_isValidCode('abcdef'), false);
      expect(_isValidCode(''), false);
    });
  });
}

bool _isValidMemberNumber(String input) {
  if (input.trim().isEmpty) return false;
  return int.tryParse(input.trim()) != null;
}

String _maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) return email;
  final local = parts[0];
  return '${local[0]}***@${parts[1]}';
}

bool _isValidCode(String code) {
  return code.length == 6 && RegExp(r'^\d{6}$').hasMatch(code);
}
