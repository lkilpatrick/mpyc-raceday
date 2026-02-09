import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/timing_repository.dart';
import 'models/timing_models.dart';

class TimingRepositoryImpl implements TimingRepository {
  TimingRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _startsCol =>
      _firestore.collection('race_starts');

  CollectionReference<Map<String, dynamic>> get _finishesCol =>
      _firestore.collection('finish_records');

  CollectionReference<Map<String, dynamic>> get _ratingsCol =>
      _firestore.collection('handicap_ratings');

  // ── Helpers ──

  static const _letterScoreMap = {
    'dns': LetterScore.dns,
    'dnf': LetterScore.dnf,
    'dsq': LetterScore.dsq,
    'ocs': LetterScore.ocs,
    'raf': LetterScore.raf,
    'ret': LetterScore.ret,
    'finished': LetterScore.finished,
  };

  static String _letterToStr(LetterScore s) =>
      _letterScoreMap.entries.firstWhere((e) => e.value == s).key;

  static LetterScore _letterFromStr(String s) =>
      _letterScoreMap[s] ?? LetterScore.finished;

  RaceStart _startFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return RaceStart(
      id: doc.id,
      eventId: d['eventId'] as String? ?? '',
      raceNumber: d['raceNumber'] as int? ?? 0,
      className: d['className'] as String? ?? '',
      warningSignalTime: (d['warningSignalTime'] as Timestamp?)?.toDate(),
      prepSignalTime: (d['prepSignalTime'] as Timestamp?)?.toDate(),
      startTime: (d['startTime'] as Timestamp?)?.toDate(),
      isGeneralRecall: d['isGeneralRecall'] as bool? ?? false,
      isPostponed: d['isPostponed'] as bool? ?? false,
      notes: d['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> _startToMap(RaceStart s) => {
        'eventId': s.eventId,
        'raceNumber': s.raceNumber,
        'className': s.className,
        'warningSignalTime': s.warningSignalTime != null
            ? Timestamp.fromDate(s.warningSignalTime!)
            : null,
        'prepSignalTime': s.prepSignalTime != null
            ? Timestamp.fromDate(s.prepSignalTime!)
            : null,
        'startTime':
            s.startTime != null ? Timestamp.fromDate(s.startTime!) : null,
        'isGeneralRecall': s.isGeneralRecall,
        'isPostponed': s.isPostponed,
        'notes': s.notes,
      };

  FinishRecord _finishFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return FinishRecord(
      id: doc.id,
      raceStartId: d['raceStartId'] as String? ?? '',
      boatCheckinId: d['boatCheckinId'] as String?,
      sailNumber: d['sailNumber'] as String? ?? '',
      boatName: d['boatName'] as String? ?? '',
      finishTimestamp:
          (d['finishTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      elapsedSeconds: (d['elapsedSeconds'] as num?)?.toDouble() ?? 0,
      correctedSeconds: (d['correctedSeconds'] as num?)?.toDouble(),
      letterScore: _letterFromStr(d['letterScore'] as String? ?? 'finished'),
      position: d['position'] as int? ?? 0,
      adjustmentNote: d['adjustmentNote'] as String?,
    );
  }

  Map<String, dynamic> _finishToMap(FinishRecord r) => {
        'raceStartId': r.raceStartId,
        'boatCheckinId': r.boatCheckinId,
        'sailNumber': r.sailNumber,
        'boatName': r.boatName,
        'finishTimestamp': Timestamp.fromDate(r.finishTimestamp),
        'elapsedSeconds': r.elapsedSeconds,
        'correctedSeconds': r.correctedSeconds,
        'letterScore': _letterToStr(r.letterScore),
        'position': r.position,
        'adjustmentNote': r.adjustmentNote,
      };

  // ── Race Starts ──

  @override
  Stream<List<RaceStart>> watchRaceStarts(String eventId) {
    return _startsCol
        .where('eventId', isEqualTo: eventId)
        .orderBy('raceNumber')
        .snapshots()
        .map((snap) => snap.docs.map(_startFromDoc).toList());
  }

  @override
  Stream<RaceStart?> watchRaceStartById(String raceStartId) {
    return _startsCol.doc(raceStartId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return _startFromDoc(snap);
    });
  }

  @override
  Future<RaceStart> createRaceStart(RaceStart start) async {
    final ref = await _startsCol.add(_startToMap(start));
    return start.copyWith(id: ref.id);
  }

  @override
  Future<void> updateRaceStart(RaceStart start) async {
    await _startsCol.doc(start.id).set(_startToMap(start), SetOptions(merge: true));
  }

  // ── Finish Records ──

  @override
  Stream<List<FinishRecord>> watchFinishRecords(String raceStartId) {
    return _finishesCol
        .where('raceStartId', isEqualTo: raceStartId)
        .orderBy('position')
        .snapshots()
        .map((snap) => snap.docs.map(_finishFromDoc).toList());
  }

  @override
  Future<FinishRecord> recordFinish(FinishRecord record) async {
    final ref = await _finishesCol.add(_finishToMap(record));
    return record.copyWith(id: ref.id);
  }

  @override
  Future<void> updateFinishRecord(FinishRecord record) async {
    await _finishesCol
        .doc(record.id)
        .set(_finishToMap(record), SetOptions(merge: true));
  }

  @override
  Future<void> deleteFinishRecord(String id) async {
    await _finishesCol.doc(id).delete();
  }

  // ── Handicap Ratings ──

  @override
  Future<List<HandicapRating>> getHandicapRatings() async {
    final snap = await _ratingsCol.get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return HandicapRating(
        sailNumber: d['sailNumber'] as String? ?? '',
        phrfRating: d['phrfRating'] as int? ?? 0,
        boatClass: d['boatClass'] as String? ?? '',
      );
    }).toList();
  }

  // ── Publish Results ──

  @override
  Future<void> publishResults(
      String raceStartId, List<FinishRecord> results) async {
    final batch = _firestore.batch();
    for (final r in results) {
      batch.set(
        _finishesCol.doc(r.id),
        _finishToMap(r),
        SetOptions(merge: true),
      );
    }
    // Mark race as published
    batch.update(_startsCol.doc(raceStartId), {'published': true});
    await batch.commit();
  }
}
