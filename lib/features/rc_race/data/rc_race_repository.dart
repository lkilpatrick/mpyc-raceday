import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/race_session.dart';

/// Repository for RC race session operations.
/// Operates on the existing `race_events` collection, adding RC-flow fields.
class RcRaceRepository {
  RcRaceRepository({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _fs;

  CollectionReference<Map<String, dynamic>> get _events =>
      _fs.collection('race_events');

  /// Watch today's race event as a RaceSession.
  Stream<RaceSession?> watchTodaysSession() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _events
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('date', isLessThan: Timestamp.fromDate(todayEnd))
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return RaceSession.fromDoc(doc.id, doc.data());
    });
  }

  /// Watch a specific session by ID.
  Stream<RaceSession?> watchSession(String eventId) {
    return _events.doc(eventId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return RaceSession.fromDoc(snap.id, snap.data()!);
    });
  }

  /// Transition the session status.
  Future<void> updateStatus(
      String eventId, RaceSessionStatus status) async {
    await _events.doc(eventId).update({
      'status': status.firestoreValue,
    });
  }

  /// Set the course on the session.
  Future<void> setCourse(String eventId,
      {required String courseId,
      required String courseName,
      required String courseNumber}) async {
    await _events.doc(eventId).update({
      'courseId': courseId,
      'courseName': courseName,
      'courseNumber': courseNumber,
    });
  }

  /// Record the race start.
  Future<void> recordStart(String eventId,
      {required String raceStartId,
      required DateTime startTime,
      required String method}) async {
    await _events.doc(eventId).update({
      'status': RaceSessionStatus.running.firestoreValue,
      'raceStartId': raceStartId,
      'startTime': Timestamp.fromDate(startTime),
      'startMethod': method,
    });
  }

  /// Transition to scoring.
  Future<void> moveToScoring(String eventId) async {
    await _events.doc(eventId).update({
      'status': RaceSessionStatus.scoring.firestoreValue,
    });
  }

  /// Transition to review.
  Future<void> moveToReview(String eventId) async {
    await _events.doc(eventId).update({
      'status': RaceSessionStatus.review.firestoreValue,
    });
  }

  /// Abandon the race.
  Future<void> abandonRace(String eventId, String reason) async {
    await _events.doc(eventId).update({
      'status': RaceSessionStatus.abandoned.firestoreValue,
      'abandonedAt': FieldValue.serverTimestamp(),
      'abandonedReason': reason,
    });
  }

  /// Finalize results and mark clubspot-ready.
  Future<void> finalizeResults(String eventId, {String? notes}) async {
    await _events.doc(eventId).update({
      'status': RaceSessionStatus.finalized.firestoreValue,
      'finalizedAt': FieldValue.serverTimestamp(),
      'clubspotReady': true,
      if (notes != null) 'notes': notes,
    });
  }

  /// Get all finalized sessions (for history view).
  /// Avoids composite index by sorting client-side.
  Future<List<RaceSession>> getFinalizedSessions() async {
    final snap = await _events
        .where('status', whereIn: ['finalized', 'abandoned'])
        .get();
    final sessions = snap.docs
        .map((d) => RaceSession.fromDoc(d.id, d.data()))
        .toList();
    sessions.sort((a, b) {
      final aDate = a.date;
      final bDate = b.date;
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });
    return sessions.take(50).toList();
  }
}
