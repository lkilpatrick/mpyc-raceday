import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to create a demo race event with sample boats and check-ins
/// for testing features without affecting real data or sending notifications.
class DemoModeService {
  static final _fs = FirebaseFirestore.instance;

  static const _demoPrefix = 'DEMO_';

  /// Sample boats for the demo fleet
  static const _sampleBoats = [
    _SampleBoat('Shields', '101', 'Salty Dog', 'John Smith', null),
    _SampleBoat('Shields', '107', 'Sea Breeze', 'Jane Doe', null),
    _SampleBoat('Shields', '112', 'Windward', 'Bob Wilson', null),
    _SampleBoat('Santana 22', '22', 'Tequila Sunrise', 'Mike Johnson', 204),
    _SampleBoat('Santana 22', '44', 'Margarita', 'Sarah Lee', 204),
    _SampleBoat('PHRF A', '747', 'Fast Forward', 'Tom Brown', 84),
    _SampleBoat('PHRF A', '1234', 'Velocity', 'Lisa Chen', 72),
    _SampleBoat('PHRF B', '55', 'Easy Rider', 'Dave Miller', 150),
    _SampleBoat('PHRF B', '88', 'Lazy Days', 'Amy Taylor', 168),
    _SampleBoat('PHRF B', '333', 'Wind Dancer', 'Chris Davis', 144),
  ];

  /// Check if a demo race already exists for today.
  /// Avoids composite index by querying date range then filtering client-side.
  static Future<String?> getTodaysDemoEventId() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final snap = await _fs
        .collection('race_events')
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('date', isLessThan: Timestamp.fromDate(todayEnd))
        .get();

    // Filter for demo events client-side to avoid composite index
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['isDemo'] == true) return doc.id;
    }
    return null;
  }

  /// Create a full demo race: event + boats + check-ins
  static Future<String> createDemoRace() async {
    // Check if demo already exists today
    final existing = await getTodaysDemoEventId();
    if (existing != null) return existing;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10, 0); // 10 AM

    // 1. Create demo race event
    final eventRef = await _fs.collection('race_events').add({
      'name': 'Demo Race Day',
      'date': Timestamp.fromDate(today),
      'seriesId': 'demo_series',
      'seriesName': 'Demo Series',
      'status': 'setup',
      'courseId': '',
      'isDemo': true,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'notes': 'Auto-generated demo race for testing. Safe to delete.',
      'crewSlots': [],
    });
    final eventId = eventRef.id;

    // 2. Ensure sample boats exist in fleet
    final batch = _fs.batch();
    final boatIds = <String>[];

    for (final boat in _sampleBoats) {
      final boatId = '$_demoPrefix${boat.sailNumber}';
      boatIds.add(boatId);
      batch.set(
        _fs.collection('boats').doc(boatId),
        {
          'sailNumber': boat.sailNumber,
          'boatName': boat.boatName,
          'ownerName': boat.ownerName,
          'boatClass': boat.boatClass,
          'phrfRating': boat.phrfRating,
          'isActive': true,
          'isRCFleet': false,
          'raceCount': 0,
          'isDemo': true,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();

    // 3. Check in some boats (first 6 of 10)
    final checkinBatch = _fs.batch();
    for (var i = 0; i < 6 && i < _sampleBoats.length; i++) {
      final boat = _sampleBoats[i];
      final checkinRef = _fs.collection('boat_checkins').doc();
      checkinBatch.set(checkinRef, {
        'eventId': eventId,
        'boatId': boatIds[i],
        'sailNumber': boat.sailNumber,
        'boatName': boat.boatName,
        'skipperName': boat.ownerName,
        'boatClass': boat.boatClass,
        'checkedInAt': Timestamp.fromDate(
            now.subtract(Duration(minutes: 30 - i * 5))),
        'checkedInBy': uid,
        'crewCount': 2 + (i % 3),
        'crewNames': ['Crew ${i * 2 + 1}', 'Crew ${i * 2 + 2}'],
        'safetyEquipmentVerified': true,
        'phrfRating': boat.phrfRating,
        'notes': '',
        'isDemo': true,
      });
    }
    await checkinBatch.commit();

    return eventId;
  }

  /// Reset a demo race back to setup state (keeps event + boats, clears runtime data).
  static Future<void> resetDemoRace(String eventId) async {
    // Reset the event doc back to setup
    await _fs.collection('race_events').doc(eventId).update({
      'status': 'setup',
      'courseId': '',
      'courseName': FieldValue.delete(),
      'courseNumber': FieldValue.delete(),
      'raceStartId': FieldValue.delete(),
      'startTime': FieldValue.delete(),
      'startMethod': FieldValue.delete(),
      'abandonedAt': FieldValue.delete(),
      'abandonedReason': FieldValue.delete(),
      'finalizedAt': FieldValue.delete(),
      'clubspotReady': false,
      'checkinsClosed': false,
      'notes': 'Demo race reset at ${DateTime.now()}',
    });

    // Delete check-ins for this event
    final checkins = await _fs
        .collection('boat_checkins')
        .where('eventId', isEqualTo: eventId)
        .get();
    for (final doc in checkins.docs) {
      await doc.reference.delete();
    }

    // Delete race starts for this event
    final starts = await _fs
        .collection('race_starts')
        .where('eventId', isEqualTo: eventId)
        .get();
    for (final doc in starts.docs) {
      // Delete finish records for each race start
      final finishes = await _fs
          .collection('finish_records')
          .where('raceStartId', isEqualTo: doc.id)
          .get();
      for (final f in finishes.docs) {
        await f.reference.delete();
      }
      await doc.reference.delete();
    }

    // Delete fleet broadcasts for this event
    final broadcasts = await _fs
        .collection('fleet_broadcasts')
        .where('eventId', isEqualTo: eventId)
        .get();
    for (final doc in broadcasts.docs) {
      await doc.reference.delete();
    }

    // Re-create sample check-ins
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo';
    final now = DateTime.now();
    final checkinBatch = _fs.batch();
    for (var i = 0; i < 6 && i < _sampleBoats.length; i++) {
      final boat = _sampleBoats[i];
      final boatId = '$_demoPrefix${boat.sailNumber}';
      final checkinRef = _fs.collection('boat_checkins').doc();
      checkinBatch.set(checkinRef, {
        'eventId': eventId,
        'boatId': boatId,
        'sailNumber': boat.sailNumber,
        'boatName': boat.boatName,
        'skipperName': boat.ownerName,
        'boatClass': boat.boatClass,
        'checkedInAt': Timestamp.fromDate(
            now.subtract(Duration(minutes: 30 - i * 5))),
        'checkedInBy': uid,
        'crewCount': 2 + (i % 3),
        'crewNames': ['Crew ${i * 2 + 1}', 'Crew ${i * 2 + 2}'],
        'safetyEquipmentVerified': true,
        'phrfRating': boat.phrfRating,
        'notes': '',
        'isDemo': true,
      });
    }
    await checkinBatch.commit();
  }

  /// Clean up all demo data
  static Future<void> cleanupDemoData() async {
    // Delete demo events
    final events = await _fs
        .collection('race_events')
        .where('isDemo', isEqualTo: true)
        .get();

    // Delete finish records and broadcasts for each demo event
    for (final doc in events.docs) {
      final starts = await _fs
          .collection('race_starts')
          .where('eventId', isEqualTo: doc.id)
          .get();
      for (final s in starts.docs) {
        final finishes = await _fs
            .collection('finish_records')
            .where('raceStartId', isEqualTo: s.id)
            .get();
        for (final f in finishes.docs) {
          await f.reference.delete();
        }
      }
      final broadcasts = await _fs
          .collection('fleet_broadcasts')
          .where('eventId', isEqualTo: doc.id)
          .get();
      for (final b in broadcasts.docs) {
        await b.reference.delete();
      }
      await doc.reference.delete();
    }

    // Delete demo boats
    final boats = await _fs
        .collection('boats')
        .where('isDemo', isEqualTo: true)
        .get();
    for (final doc in boats.docs) {
      await doc.reference.delete();
    }

    // Delete demo check-ins
    final checkins = await _fs
        .collection('boat_checkins')
        .where('isDemo', isEqualTo: true)
        .get();
    for (final doc in checkins.docs) {
      await doc.reference.delete();
    }

    // Delete demo race starts
    final starts = await _fs
        .collection('race_starts')
        .where('isDemo', isEqualTo: true)
        .get();
    for (final doc in starts.docs) {
      await doc.reference.delete();
    }
  }
}

class _SampleBoat {
  const _SampleBoat(
      this.boatClass, this.sailNumber, this.boatName, this.ownerName, this.phrfRating);
  final String boatClass;
  final String sailNumber;
  final String boatName;
  final String ownerName;
  final int? phrfRating;
}
