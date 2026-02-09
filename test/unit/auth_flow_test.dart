import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';

void main() {
  group('MemberRole', () {
    test('all roles exist', () {
      expect(MemberRole.values, hasLength(5));
      expect(MemberRole.values, contains(MemberRole.webAdmin));
      expect(MemberRole.values, contains(MemberRole.clubBoard));
      expect(MemberRole.values, contains(MemberRole.rcChair));
      expect(MemberRole.values, contains(MemberRole.skipper));
      expect(MemberRole.values, contains(MemberRole.crew));
    });

    test('role-based access helpers on Member', () {
      Member makeMember(List<MemberRole> roles) => Member(
            id: 'test',
            firstName: 'Test',
            lastName: 'User',
            email: 'test@test.com',
            mobileNumber: '',
            memberNumber: '1',
            membershipStatus: 'active',
            membershipCategory: 'Full',
            memberTags: [],
            clubspotId: '',
            roles: roles,
            lastSynced: DateTime.now(),
            emergencyContact:
                const EmergencyContact(name: '', phone: ''),
          );

      // web_admin has all access
      final admin = makeMember([MemberRole.webAdmin]);
      expect(admin.isWebAdmin, true);
      expect(admin.isClubBoard, true);
      expect(admin.isRCChair, true);
      expect(admin.canAccessWebDashboard, true);

      // club_board has board + web dashboard access
      final board = makeMember([MemberRole.clubBoard]);
      expect(board.isWebAdmin, false);
      expect(board.isClubBoard, true);
      expect(board.isRCChair, false);
      expect(board.canAccessWebDashboard, true);

      // rc_chair has RC + web dashboard access
      final rc = makeMember([MemberRole.rcChair]);
      expect(rc.isWebAdmin, false);
      expect(rc.isRCChair, true);
      expect(rc.canAccessWebDashboard, true);

      // skipper has no web dashboard access
      final skipper = makeMember([MemberRole.skipper]);
      expect(skipper.isSkipperOrAbove, true);
      expect(skipper.canAccessWebDashboard, false);

      // crew has minimal access
      final crew = makeMember([MemberRole.crew]);
      expect(crew.isSkipperOrAbove, false);
      expect(crew.canAccessWebDashboard, false);

      // multi-role: skipper + club_board
      final multi = makeMember([MemberRole.skipper, MemberRole.clubBoard]);
      expect(multi.isClubBoard, true);
      expect(multi.isSkipperOrAbove, true);
      expect(multi.canAccessWebDashboard, true);
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
