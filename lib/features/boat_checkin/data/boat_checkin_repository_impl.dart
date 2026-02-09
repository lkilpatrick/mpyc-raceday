import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/boat_checkin_repository.dart';
import 'models/boat.dart';
import 'models/boat_checkin.dart';

class BoatCheckinRepositoryImpl implements BoatCheckinRepository {
  BoatCheckinRepositoryImpl({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _fs;

  CollectionReference<Map<String, dynamic>> get _checkinsCol =>
      _fs.collection('boat_checkins');
  CollectionReference<Map<String, dynamic>> get _fleetCol =>
      _fs.collection('boats');

  // ── Firestore mapping ──

  BoatCheckin _checkinFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BoatCheckin(
      id: doc.id,
      eventId: d['eventId'] as String? ?? '',
      boatId: d['boatId'] as String? ?? '',
      sailNumber: d['sailNumber'] as String? ?? '',
      boatName: d['boatName'] as String? ?? '',
      skipperName: d['skipperName'] as String? ?? '',
      boatClass: d['boatClass'] as String? ?? '',
      checkedInAt: (d['checkedInAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkedInBy: d['checkedInBy'] as String? ?? '',
      crewCount: d['crewCount'] as int? ?? 0,
      crewNames: List<String>.from(d['crewNames'] ?? []),
      safetyEquipmentVerified: d['safetyEquipmentVerified'] as bool? ?? false,
      phrfRating: d['phrfRating'] as int?,
      notes: d['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> _checkinToMap(BoatCheckin c) => {
        'eventId': c.eventId,
        'boatId': c.boatId,
        'sailNumber': c.sailNumber,
        'boatName': c.boatName,
        'skipperName': c.skipperName,
        'boatClass': c.boatClass,
        'checkedInAt': Timestamp.fromDate(c.checkedInAt),
        'checkedInBy': c.checkedInBy,
        'crewCount': c.crewCount,
        'crewNames': c.crewNames,
        'safetyEquipmentVerified': c.safetyEquipmentVerified,
        'phrfRating': c.phrfRating,
        'notes': c.notes,
      };

  Boat _boatFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Boat(
      id: doc.id,
      sailNumber: d['sailNumber'] as String? ?? '',
      boatName: d['boatName'] as String? ?? '',
      ownerName: d['ownerName'] as String? ?? '',
      boatClass: d['boatClass'] as String? ?? '',
      phrfRating: d['phrfRating'] as int?,
      lastRacedAt: (d['lastRacedAt'] as Timestamp?)?.toDate(),
      raceCount: d['raceCount'] as int? ?? 0,
      isActive: d['isActive'] as bool? ?? true,
      phone: d['phone'] as String?,
      email: d['email'] as String?,
    );
  }

  Map<String, dynamic> _boatToMap(Boat b) => {
        'sailNumber': b.sailNumber,
        'boatName': b.boatName,
        'ownerName': b.ownerName,
        'boatClass': b.boatClass,
        'phrfRating': b.phrfRating,
        'lastRacedAt':
            b.lastRacedAt != null ? Timestamp.fromDate(b.lastRacedAt!) : null,
        'raceCount': b.raceCount,
        'isActive': b.isActive,
        'phone': b.phone,
        'email': b.email,
      };

  // ── Check-ins ──

  @override
  Stream<List<BoatCheckin>> watchCheckins(String eventId) {
    return _checkinsCol
        .where('eventId', isEqualTo: eventId)
        .orderBy('checkedInAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(_checkinFromDoc).toList());
  }

  @override
  Future<void> checkInBoat(BoatCheckin checkin) async {
    final docRef = checkin.id.isEmpty
        ? _checkinsCol.doc()
        : _checkinsCol.doc(checkin.id);
    await docRef.set(_checkinToMap(checkin));

    // Update boat's lastRacedAt and raceCount
    if (checkin.boatId.isNotEmpty) {
      final boatDoc = await _fleetCol.doc(checkin.boatId).get();
      if (boatDoc.exists) {
        await _fleetCol.doc(checkin.boatId).update({
          'lastRacedAt': FieldValue.serverTimestamp(),
          'raceCount': FieldValue.increment(1),
        });
      }
    }
  }

  @override
  Future<void> removeCheckin(String checkinId) async {
    await _checkinsCol.doc(checkinId).delete();
  }

  @override
  Future<void> closeCheckins(String eventId) async {
    await _fs.collection('race_events').doc(eventId).update({
      'checkinsClosed': true,
      'checkinsClosedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<bool> watchCheckinsClosed(String eventId) {
    return _fs
        .collection('race_events')
        .doc(eventId)
        .snapshots()
        .map((snap) => snap.data()?['checkinsClosed'] as bool? ?? false);
  }

  // ── Fleet ──

  @override
  Stream<List<Boat>> watchFleet() {
    return _fleetCol
        .where('isActive', isEqualTo: true)
        .orderBy('sailNumber')
        .snapshots()
        .map((snap) => snap.docs.map(_boatFromDoc).toList());
  }

  @override
  Future<Boat?> getBoat(String boatId) async {
    final doc = await _fleetCol.doc(boatId).get();
    return doc.exists ? _boatFromDoc(doc) : null;
  }

  @override
  Future<void> saveBoat(Boat boat) async {
    if (boat.id.isEmpty) {
      await _fleetCol.add(_boatToMap(boat));
    } else {
      await _fleetCol.doc(boat.id).set(_boatToMap(boat), SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteBoat(String boatId) async {
    await _fleetCol.doc(boatId).update({'isActive': false});
  }

  @override
  Future<void> importFleetFromCsv(String csvContent) async {
    final lines = csvContent.split('\n');
    if (lines.length < 2) return;

    // Parse header
    final headers =
        lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
    final sailIdx = headers.indexOf('sail');
    final nameIdx = headers.indexOf('boat name');
    final ownerIdx = headers.indexOf('owner');
    final classIdx = headers.indexOf('class');
    final phrfIdx = headers.indexOf('phrf');

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = line.split(',').map((c) => c.trim()).toList();

      final sail = sailIdx >= 0 && sailIdx < cols.length ? cols[sailIdx] : '';
      final name = nameIdx >= 0 && nameIdx < cols.length ? cols[nameIdx] : '';
      final owner =
          ownerIdx >= 0 && ownerIdx < cols.length ? cols[ownerIdx] : '';
      final cls =
          classIdx >= 0 && classIdx < cols.length ? cols[classIdx] : '';
      final phrf = phrfIdx >= 0 && phrfIdx < cols.length
          ? int.tryParse(cols[phrfIdx])
          : null;

      if (sail.isEmpty) continue;

      // Check if boat already exists by sail number
      final existing = await _fleetCol
          .where('sailNumber', isEqualTo: sail)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        await _fleetCol.doc(existing.docs.first.id).update({
          'boatName': name,
          'ownerName': owner,
          'boatClass': cls,
          if (phrf != null) 'phrfRating': phrf,
          'isActive': true,
        });
      } else {
        await _fleetCol.add({
          'sailNumber': sail,
          'boatName': name,
          'ownerName': owner,
          'boatClass': cls,
          'phrfRating': phrf,
          'raceCount': 0,
          'isActive': true,
        });
      }
    }
  }

  @override
  Future<List<Boat>> getBoatsNotCheckedIn(String eventId) async {
    // Get all checked-in boat IDs for this event
    final checkinsSnap =
        await _checkinsCol.where('eventId', isEqualTo: eventId).get();
    final checkedInBoatIds =
        checkinsSnap.docs.map((d) => d.data()['boatId'] as String? ?? '').toSet();

    // Get all active boats
    final fleetSnap =
        await _fleetCol.where('isActive', isEqualTo: true).get();
    return fleetSnap.docs
        .map(_boatFromDoc)
        .where((b) => !checkedInBoatIds.contains(b.id))
        .toList();
  }
}
