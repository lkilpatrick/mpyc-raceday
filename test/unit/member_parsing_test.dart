import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';

void main() {
  group('MemberRole parsing', () {
    // Mirrors the logic in auth_repository_impl.dart _memberFromSnapshot

    MemberRole parseRole(String roleStr) {
      return MemberRole.values.firstWhere(
        (r) =>
            r.name == roleStr ||
            (roleStr == 'rc_crew' && r == MemberRole.rcCrew),
        orElse: () => MemberRole.member,
      );
    }

    test('parses "admin" role', () {
      expect(parseRole('admin'), MemberRole.admin);
    });

    test('parses "pro" role', () {
      expect(parseRole('pro'), MemberRole.pro);
    });

    test('parses "rcCrew" role (Dart enum name)', () {
      expect(parseRole('rcCrew'), MemberRole.rcCrew);
    });

    test('parses "rc_crew" role (Firestore snake_case)', () {
      expect(parseRole('rc_crew'), MemberRole.rcCrew);
    });

    test('parses "member" role', () {
      expect(parseRole('member'), MemberRole.member);
    });

    test('unknown role defaults to member', () {
      expect(parseRole('unknown'), MemberRole.member);
      expect(parseRole(''), MemberRole.member);
      expect(parseRole('superadmin'), MemberRole.member);
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
        role: MemberRole.rcCrew,
        lastSynced: DateTime(2024, 6, 15),
        emergencyContact:
            const EmergencyContact(name: 'Jane', phone: '555-0200'),
      );

      expect(member.firstName, 'John');
      expect(member.role, MemberRole.rcCrew);
      expect(member.memberTags, hasLength(2));
      expect(member.profilePhotoUrl, isNull);
    });

    test('Member.fromJson roundtrip', () {
      // Build JSON manually to match what Firestore/generated code expects
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
        'role': 'admin',
        'lastSynced': '2024-01-01T00:00:00.000',
        'profilePhotoUrl': null,
        'emergencyContact': {'name': 'Bob', 'phone': '555-0400'},
      };

      final restored = Member.fromJson(json);
      expect(restored.firstName, 'Alice');
      expect(restored.role, MemberRole.admin);
      expect(restored.emergencyContact.name, 'Bob');
      expect(restored.emergencyContact.phone, '555-0400');
      expect(restored.memberTags, isEmpty);
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
