import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/incidents_repository.dart';
import 'models/race_incident.dart';

class IncidentsRepositoryImpl implements IncidentsRepository {
  IncidentsRepositoryImpl({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _fs;

  CollectionReference<Map<String, dynamic>> get _incidentsCol =>
      _fs.collection('incidents');

  // ── Firestore mapping ──

  RaceIncident _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return RaceIncident(
      id: doc.id,
      eventId: d['eventId'] as String? ?? '',
      raceNumber: d['raceNumber'] as int? ?? 0,
      reportedAt: (d['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportedBy: d['reportedBy'] as String? ?? '',
      incidentTime:
          (d['incidentTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: d['description'] as String? ?? '',
      locationOnCourse: CourseLocationOnIncident.values.firstWhere(
        (v) => v.name == (d['locationOnCourse'] as String? ?? ''),
        orElse: () => CourseLocationOnIncident.openWater,
      ),
      involvedBoats: (d['involvedBoats'] as List<dynamic>?)
              ?.map((b) {
                final bd = b as Map<String, dynamic>;
                return BoatInvolved(
                  boatId: bd['boatId'] as String? ?? '',
                  sailNumber: bd['sailNumber'] as String? ?? '',
                  boatName: bd['boatName'] as String? ?? '',
                  skipperName: bd['skipperName'] as String? ?? '',
                  role: BoatInvolvedRole.values.firstWhere(
                    (r) => r.name == (bd['role'] as String? ?? ''),
                    orElse: () => BoatInvolvedRole.witness,
                  ),
                );
              })
              .toList() ??
          [],
      rulesAlleged: List<String>.from(d['rulesAlleged'] ?? []),
      status: RaceIncidentStatus.values.firstWhere(
        (s) => s.name == (d['status'] as String? ?? ''),
        orElse: () => RaceIncidentStatus.reported,
      ),
      hearing: d['hearing'] != null
          ? _hearingFromMap(d['hearing'] as Map<String, dynamic>)
          : null,
      resolution: d['resolution'] as String? ?? '',
      penaltyApplied: d['penaltyApplied'] as String? ?? '',
      witnesses: List<String>.from(d['witnesses'] ?? []),
      attachments: List<String>.from(d['attachments'] ?? []),
      comments: (d['comments'] as List<dynamic>?)
              ?.map((c) {
                final cd = c as Map<String, dynamic>;
                return IncidentComment(
                  id: cd['id'] as String? ?? '',
                  authorId: cd['authorId'] as String? ?? '',
                  authorName: cd['authorName'] as String? ?? '',
                  text: cd['text'] as String? ?? '',
                  createdAt:
                      (cd['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                );
              })
              .toList() ??
          [],
    );
  }

  HearingInfo _hearingFromMap(Map<String, dynamic> d) => HearingInfo(
        scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate(),
        location: d['location'] as String?,
        juryMembers: List<String>.from(d['juryMembers'] ?? []),
        findingOfFact: d['findingOfFact'] as String? ?? '',
        rulesBroken: List<String>.from(d['rulesBroken'] ?? []),
        penalty: d['penalty'] as String? ?? '',
        decisionNotes: d['decisionNotes'] as String? ?? '',
      );

  Map<String, dynamic> _toMap(RaceIncident i) => {
        'eventId': i.eventId,
        'raceNumber': i.raceNumber,
        'reportedAt': Timestamp.fromDate(i.reportedAt),
        'reportedBy': i.reportedBy,
        'incidentTime': Timestamp.fromDate(i.incidentTime),
        'description': i.description,
        'locationOnCourse': i.locationOnCourse.name,
        'involvedBoats': i.involvedBoats
            .map((b) => {
                  'boatId': b.boatId,
                  'sailNumber': b.sailNumber,
                  'boatName': b.boatName,
                  'skipperName': b.skipperName,
                  'role': b.role.name,
                })
            .toList(),
        'rulesAlleged': i.rulesAlleged,
        'status': i.status.name,
        'hearing': i.hearing != null
            ? {
                'scheduledAt': i.hearing!.scheduledAt != null
                    ? Timestamp.fromDate(i.hearing!.scheduledAt!)
                    : null,
                'location': i.hearing!.location,
                'juryMembers': i.hearing!.juryMembers,
                'findingOfFact': i.hearing!.findingOfFact,
                'rulesBroken': i.hearing!.rulesBroken,
                'penalty': i.hearing!.penalty,
                'decisionNotes': i.hearing!.decisionNotes,
              }
            : null,
        'resolution': i.resolution,
        'penaltyApplied': i.penaltyApplied,
        'witnesses': i.witnesses,
        'attachments': i.attachments,
        'comments': i.comments
            .map((c) => {
                  'id': c.id,
                  'authorId': c.authorId,
                  'authorName': c.authorName,
                  'text': c.text,
                  'createdAt': Timestamp.fromDate(c.createdAt),
                })
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  // ── Incidents ──

  @override
  Stream<List<RaceIncident>> watchIncidents({String? eventId}) {
    Query<Map<String, dynamic>> query =
        _incidentsCol.orderBy('reportedAt', descending: true);
    if (eventId != null) {
      query = _incidentsCol
          .where('eventId', isEqualTo: eventId)
          .orderBy('reportedAt', descending: true);
    }
    return query.snapshots().map(
        (snap) => snap.docs.map((d) => _fromDoc(d)).toList());
  }

  @override
  Future<RaceIncident?> getIncident(String id) async {
    final doc = await _incidentsCol.doc(id).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  @override
  Future<String> createIncident(RaceIncident incident) async {
    final map = _toMap(incident);
    map['createdAt'] = FieldValue.serverTimestamp();
    final docRef = await _incidentsCol.add(map);
    return docRef.id;
  }

  @override
  Future<void> updateIncident(RaceIncident incident) async {
    await _incidentsCol.doc(incident.id).set(_toMap(incident), SetOptions(merge: true));
  }

  @override
  Future<void> updateStatus(String id, RaceIncidentStatus status) async {
    await _incidentsCol.doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Comments ──

  @override
  Future<void> addComment(String incidentId, IncidentComment comment) async {
    await _incidentsCol.doc(incidentId).update({
      'comments': FieldValue.arrayUnion([
        {
          'id': comment.id,
          'authorId': comment.authorId,
          'authorName': comment.authorName,
          'text': comment.text,
          'createdAt': Timestamp.fromDate(comment.createdAt),
        }
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Hearing ──

  @override
  Future<void> updateHearing(String incidentId, HearingInfo hearing) async {
    await _incidentsCol.doc(incidentId).update({
      'hearing': {
        'scheduledAt': hearing.scheduledAt != null
            ? Timestamp.fromDate(hearing.scheduledAt!)
            : null,
        'location': hearing.location,
        'juryMembers': hearing.juryMembers,
        'findingOfFact': hearing.findingOfFact,
        'rulesBroken': hearing.rulesBroken,
        'penalty': hearing.penalty,
        'decisionNotes': hearing.decisionNotes,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Attachments ──

  @override
  Future<void> addAttachment(String incidentId, String attachmentUrl) async {
    await _incidentsCol.doc(incidentId).update({
      'attachments': FieldValue.arrayUnion([attachmentUrl]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
