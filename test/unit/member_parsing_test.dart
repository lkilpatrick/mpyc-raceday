import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';

void main() {
  group('MemberRole parsing', () {
    // Mirrors the logic in auth_repository_impl.dart _parseRole

    const roleStringMap = {
      'web_admin': MemberRole.webAdmin,
      'webAdmin': MemberRole.webAdmin,
      'club_board': MemberRole.clubBoard,
      'clubBoard': MemberRole.clubBoard,
      'rc_chair': MemberRole.rcChair,
      'rcChair': MemberRole.rcChair,
      'skipper': MemberRole.skipper,
      'crew': MemberRole.crew,
      // Legacy mappings
      'admin': MemberRole.webAdmin,
      'pro': MemberRole.rcChair,
      'rc_crew': MemberRole.crew,
      'member': MemberRole.crew,
    };

    MemberRole? parseRole(String roleStr) => roleStringMap[roleStr];

    test('parses new role names', () {
      expect(parseRole('web_admin'), MemberRole.webAdmin);
      expect(parseRole('club_board'), MemberRole.clubBoard);
      expect(parseRole('rc_chair'), MemberRole.rcChair);
      expect(parseRole('skipper'), MemberRole.skipper);
      expect(parseRole('crew'), MemberRole.crew);
    });

    test('parses camelCase variants', () {
      expect(parseRole('webAdmin'), MemberRole.webAdmin);
      expect(parseRole('clubBoard'), MemberRole.clubBoard);
      expect(parseRole('rcChair'), MemberRole.rcChair);
    });

    test('legacy role names map to new roles', () {
      expect(parseRole('admin'), MemberRole.webAdmin);
      expect(parseRole('pro'), MemberRole.rcChair);
      expect(parseRole('rc_crew'), MemberRole.crew);
      expect(parseRole('member'), MemberRole.crew);
    });

    test('unknown role returns null', () {
      expect(parseRole('unknown'), isNull);
      expect(parseRole(''), isNull);
      expect(parseRole('superadmin'), isNull);
    });
  });

  group('Emergency contact defaults', () {
    test('missing emergencyContact uses defaults', () {
      final data = <String, dynamic>{};
      final emergencyData =
          data['emergencyContact'] as Map<String, dynamic>? ??
              {'name': 'Unknown', 'phone': ''};

      final contact = EmergencyContact(
        name: emergencyData['name'] as String? ?? 'Unknown',
        phone: emergencyData['phone'] as String? ?? '',
      );

      expect(contact.name, 'Unknown');
      expect(contact.phone, '');
    });

    test('partial emergencyContact fills missing fields', () {
      final data = <String, dynamic>{
        'emergencyContact': {'name': 'Jane Doe'},
      };
      final emergencyData =
          data['emergencyContact'] as Map<String, dynamic>? ??
              {'name': 'Unknown', 'phone': ''};

      final contact = EmergencyContact(
        name: emergencyData['name'] as String? ?? 'Unknown',
        phone: emergencyData['phone'] as String? ?? '',
      );

      expect(contact.name, 'Jane Doe');
      expect(contact.phone, '');
    });

    test('full emergencyContact is preserved', () {
      final data = <String, dynamic>{
        'emergencyContact': {'name': 'Jane Doe', 'phone': '555-1234'},
      };
      final emergencyData =
          data['emergencyContact'] as Map<String, dynamic>? ??
              {'name': 'Unknown', 'phone': ''};

      final contact = EmergencyContact(
        name: emergencyData['name'] as String? ?? 'Unknown',
        phone: emergencyData['phone'] as String? ?? '',
      );

      expect(contact.name, 'Jane Doe');
      expect(contact.phone, '555-1234');
    });
  });

  group('lastSynced timestamp handling', () {
    // Mirrors the logic in auth_repository_impl.dart _memberFromSnapshot

    DateTime parseLastSynced(dynamic raw) {
      if (raw is DateTime) {
        return raw;
      } else if (raw is String) {
        return DateTime.tryParse(raw) ?? DateTime(2000);
      } else {
        return DateTime(2000);
      }
    }

    test('parses DateTime directly', () {
      final dt = DateTime(2024, 6, 15, 10, 30);
      expect(parseLastSynced(dt), dt);
    });

    test('parses ISO 8601 string', () {
      final result = parseLastSynced('2024-06-15T10:30:00.000');
      expect(result.year, 2024);
      expect(result.month, 6);
      expect(result.day, 15);
    });

    test('invalid string falls back to default', () {
      final result = parseLastSynced('not-a-date');
      expect(result.year, 2000);
    });

    test('null falls back to default', () {
      final result = parseLastSynced(null);
      expect(result.year, 2000);
    });

    test('integer falls back to default', () {
      final result = parseLastSynced(1234567890);
      expect(result.year, 2000);
    });
  });

  group('Member model', () {
    test('creates Member with all required fields', () {
      final member = Member(
        id: 'm1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        mobileNumber: '555-0100',
        memberNumber: '1234',
        membershipStatus: 'active',
        membershipCategory: 'Full',
        memberTags: ['racer', 'volunteer'],
        clubspotId: 'cs1',
        roles: [MemberRole.rcChair, MemberRole.skipper],
        lastSynced: DateTime(2024, 6, 15),
        emergencyContact:
            const EmergencyContact(name: 'Jane', phone: '555-0200'),
      );

      expect(member.firstName, 'John');
      expect(member.roles, contains(MemberRole.rcChair));
      expect(member.roles, contains(MemberRole.skipper));
      expect(member.isRCChair, true);
      expect(member.isSkipperOrAbove, true);
      expect(member.memberTags, hasLength(2));
      expect(member.profilePhotoUrl, isNull);
      expect(member.isActive, true);
      expect(member.displayName, 'John Doe');
    });

    test('Member.fromJson roundtrip', () {
      final json = <String, dynamic>{
        'id': 'm1',
        'firstName': 'Alice',
        'lastName': 'Smith',
        'email': 'alice@example.com',
        'mobileNumber': '555-0300',
        'memberNumber': '5678',
        'membershipStatus': 'active',
        'membershipCategory': 'Associate',
        'memberTags': <String>[],
        'clubspotId': 'cs2',
        'roles': ['web_admin', 'club_board'],
        'lastSynced': '2024-01-01T00:00:00.000',
        'profilePhotoUrl': null,
        'emergencyContact': {'name': 'Bob', 'phone': '555-0400'},
        'signalNumber': '247',
        'boatName': 'Pegasus',
        'sailNumber': '34127',
        'boatClass': 'CHB 34',
        'phrfRating': 228,
        'isActive': true,
      };

      final restored = Member.fromJson(json);
      expect(restored.firstName, 'Alice');
      expect(restored.roles, contains(MemberRole.webAdmin));
      expect(restored.roles, contains(MemberRole.clubBoard));
      expect(restored.isWebAdmin, true);
      expect(restored.isClubBoard, true);
      expect(restored.canAccessWebDashboard, true);
      expect(restored.emergencyContact.name, 'Bob');
      expect(restored.emergencyContact.phone, '555-0400');
      expect(restored.memberTags, isEmpty);
      expect(restored.signalNumber, '247');
      expect(restored.boatName, 'Pegasus');
      expect(restored.sailNumber, '34127');
      expect(restored.boatClass, 'CHB 34');
      expect(restored.phrfRating, 228);
      expect(restored.isActive, true);
    });

    test('new fields default correctly', () {
      final member = Member(
        id: 'm2',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@test.com',
        mobileNumber: '',
        memberNumber: '1',
        membershipStatus: 'active',
        membershipCategory: 'Full',
        memberTags: [],
        clubspotId: '',
        roles: [MemberRole.crew],
        lastSynced: DateTime(2024),
        emergencyContact:
            const EmergencyContact(name: '', phone: ''),
      );

      expect(member.signalNumber, isNull);
      expect(member.boatName, isNull);
      expect(member.sailNumber, isNull);
      expect(member.boatClass, isNull);
      expect(member.phrfRating, isNull);
      expect(member.firebaseUid, isNull);
      expect(member.lastLogin, isNull);
      expect(member.isActive, true);
    });
  });

  group('Email masking', () {
    // Mirrors the maskEmail logic in Cloud Functions

    String maskEmail(String? email) {
      if (email == null || !email.contains('@')) return '***';
      final parts = email.split('@');
      final local = parts[0];
      final domain = parts[1];
      final visible = local.length <= 2 ? local[0] : local.substring(0, 2);
      return '$visible***@$domain';
    }

    test('masks standard email', () {
      expect(maskEmail('john.doe@example.com'), 'jo***@example.com');
    });

    test('masks short local part', () {
      expect(maskEmail('ab@example.com'), 'a***@example.com');
    });

    test('masks single char local part', () {
      expect(maskEmail('a@example.com'), 'a***@example.com');
    });

    test('null email returns ***', () {
      expect(maskEmail(null), '***');
    });

    test('email without @ returns ***', () {
      expect(maskEmail('notanemail'), '***');
    });
  });
}
