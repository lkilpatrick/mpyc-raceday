import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/boat_checkin/data/models/boat.dart';
import 'package:mpyc_raceday/features/boat_checkin/data/models/boat_checkin.dart';

void main() {
  group('Boat model', () {
    test('creates boat with all fields', () {
      final boat = Boat(
        id: 'b1',
        sailNumber: '42',
        boatName: 'Wind Dancer',
        ownerName: 'John Doe',
        boatClass: 'J/105',
        phrfRating: 84,
      );
      expect(boat.sailNumber, '42');
      expect(boat.boatName, 'Wind Dancer');
      expect(boat.ownerName, 'John Doe');
      expect(boat.boatClass, 'J/105');
      expect(boat.phrfRating, 84);
    });

    test('boat with null PHRF rating', () {
      final boat = Boat(
        id: 'b2',
        sailNumber: '100',
        boatName: 'Sea Breeze',
        ownerName: 'Jane Smith',
        boatClass: 'One Design',
      );
      expect(boat.phrfRating, isNull);
    });
  });

  group('BoatCheckin model', () {
    test('creates check-in with all fields', () {
      final checkin = BoatCheckin(
        id: 'c1',
        eventId: 'e1',
        boatId: 'b1',
        sailNumber: '42',
        boatName: 'Wind Dancer',
        skipperName: 'John Doe',
        boatClass: 'J/105',
        checkedInAt: DateTime(2024, 6, 15, 9, 30),
        checkedInBy: 'PRO',
        crewCount: 5,
        safetyEquipmentVerified: true,
        phrfRating: 84,
      );
      expect(checkin.sailNumber, '42');
      expect(checkin.safetyEquipmentVerified, true);
      expect(checkin.crewCount, 5);
      expect(checkin.phrfRating, 84);
    });

    test('check-in without safety verification', () {
      final checkin = BoatCheckin(
        id: 'c2',
        eventId: 'e1',
        boatId: 'b2',
        sailNumber: '100',
        boatName: 'Sea Breeze',
        skipperName: 'Jane Smith',
        boatClass: 'One Design',
        checkedInAt: DateTime(2024, 6, 15, 9, 45),
        checkedInBy: 'RC',
        crewCount: 3,
        safetyEquipmentVerified: false,
      );
      expect(checkin.safetyEquipmentVerified, false);
      expect(checkin.phrfRating, isNull);
    });
  });

  group('Search filtering', () {
    final checkins = [
      BoatCheckin(
        id: 'c1', eventId: 'e1', boatId: 'b1',
        sailNumber: '42', boatName: 'Wind Dancer',
        skipperName: 'John Doe', boatClass: 'J/105',
        checkedInAt: DateTime.now(), checkedInBy: 'PRO',
        crewCount: 5, safetyEquipmentVerified: true,
      ),
      BoatCheckin(
        id: 'c2', eventId: 'e1', boatId: 'b2',
        sailNumber: '100', boatName: 'Sea Breeze',
        skipperName: 'Jane Smith', boatClass: 'Catalina 30',
        checkedInAt: DateTime.now(), checkedInBy: 'RC',
        crewCount: 3, safetyEquipmentVerified: true,
      ),
      BoatCheckin(
        id: 'c3', eventId: 'e1', boatId: 'b3',
        sailNumber: '777', boatName: 'Lucky Seven',
        skipperName: 'Bob Wilson', boatClass: 'J/105',
        checkedInAt: DateTime.now(), checkedInBy: 'PRO',
        crewCount: 4, safetyEquipmentVerified: false,
      ),
    ];

    test('search by sail number', () {
      final query = '42';
      final filtered = checkins.where((c) =>
          c.sailNumber.toLowerCase().contains(query) ||
          c.boatName.toLowerCase().contains(query) ||
          c.skipperName.toLowerCase().contains(query)).toList();
      expect(filtered, hasLength(1));
      expect(filtered.first.boatName, 'Wind Dancer');
    });

    test('search by boat name', () {
      final query = 'sea';
      final filtered = checkins.where((c) =>
          c.sailNumber.toLowerCase().contains(query) ||
          c.boatName.toLowerCase().contains(query) ||
          c.skipperName.toLowerCase().contains(query)).toList();
      expect(filtered, hasLength(1));
      expect(filtered.first.sailNumber, '100');
    });

    test('search by skipper name', () {
      final query = 'bob';
      final filtered = checkins.where((c) =>
          c.sailNumber.toLowerCase().contains(query) ||
          c.boatName.toLowerCase().contains(query) ||
          c.skipperName.toLowerCase().contains(query)).toList();
      expect(filtered, hasLength(1));
      expect(filtered.first.sailNumber, '777');
    });

    test('empty search returns all', () {
      final query = '';
      final filtered = query.isEmpty
          ? checkins
          : checkins.where((c) =>
              c.sailNumber.toLowerCase().contains(query)).toList();
      expect(filtered, hasLength(3));
    });

    test('no match returns empty', () {
      final query = 'xyz';
      final filtered = checkins.where((c) =>
          c.sailNumber.toLowerCase().contains(query) ||
          c.boatName.toLowerCase().contains(query) ||
          c.skipperName.toLowerCase().contains(query)).toList();
      expect(filtered, isEmpty);
    });
  });

  group('Form validation', () {
    test('sail number required', () {
      final validator = (String? v) =>
          v == null || v.isEmpty ? 'Required' : null;
      expect(validator(''), 'Required');
      expect(validator(null), 'Required');
      expect(validator('42'), isNull);
    });

    test('boat name required', () {
      final validator = (String? v) =>
          v == null || v.isEmpty ? 'Required' : null;
      expect(validator(''), 'Required');
      expect(validator('Wind Dancer'), isNull);
    });

    test('skipper required', () {
      final validator = (String? v) =>
          v == null || v.isEmpty ? 'Required' : null;
      expect(validator(''), 'Required');
      expect(validator('John Doe'), isNull);
    });
  });
}
