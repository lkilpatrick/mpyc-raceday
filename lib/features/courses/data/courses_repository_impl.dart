import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/services/audit_service.dart';
import '../domain/courses_repository.dart';
import 'models/course_config.dart';
import 'models/fleet_broadcast.dart';
import 'models/mark.dart';
import 'models/mark_distance.dart';

class CoursesRepositoryImpl implements CoursesRepository {
  CoursesRepositoryImpl({FirebaseFirestore? firestore, AuditService? audit})
      : _fs = firestore ?? FirebaseFirestore.instance,
        _audit = audit ?? AuditService();

  final FirebaseFirestore _fs;
  final AuditService _audit;

  CollectionReference<Map<String, dynamic>> get _coursesCol =>
      _fs.collection('courses');
  CollectionReference<Map<String, dynamic>> get _marksCol =>
      _fs.collection('marks');
  CollectionReference<Map<String, dynamic>> get _distCol =>
      _fs.collection('mark_distances');
  CollectionReference<Map<String, dynamic>> get _broadcastsCol =>
      _fs.collection('fleet_broadcasts');

  // ── Mark name mapping (code → display name) ──
  static const _markNameMap = {
    'X': 'X', 'C': 'C', 'P': 'P', 'M': 'M', 'LV': 'LV',
    '1': '1', '3': '3', '4': '4',
    'W': 'W', 'R': 'R', 'L': 'L',
    'A': 'A', 'B': 'B',
  };

  static String _resolveMarkName(String code) =>
      _markNameMap[code] ?? code;

  /// Parse sequence array ["START","Xp","4s","FINISH"] into List<CourseMark>
  static List<CourseMark> _parseSequence(List<String> sequence) {
    final marks = <CourseMark>[];
    int order = 1;
    for (final entry in sequence) {
      if (entry == 'START') {
        marks.add(CourseMark(
          markId: '1',
          markName: '1',
          order: order++,
          rounding: MarkRounding.port,
          isStart: true,
        ));
        continue;
      }
      if (entry == 'FINISH') {
        marks.add(CourseMark(
          markId: '1',
          markName: '1',
          order: order++,
          rounding: MarkRounding.port,
          isFinish: true,
        ));
        continue;
      }
      if (entry == 'FINISH_X') {
        marks.add(CourseMark(
          markId: 'X',
          markName: 'X',
          order: order++,
          rounding: MarkRounding.starboard,
          isFinish: true,
        ));
        continue;
      }
      // Parse "Xp", "4s", "LVp", "Mp", etc.
      final match = RegExp(r'^(.+?)(p|s)$').firstMatch(entry);
      if (match == null) continue;
      final code = match.group(1)!;
      final rounding =
          match.group(2) == 's' ? MarkRounding.starboard : MarkRounding.port;
      marks.add(CourseMark(
        markId: code,
        markName: _resolveMarkName(code),
        order: order++,
        rounding: rounding,
      ));
    }
    return marks;
  }

  // ── Firestore mapping ──

  CourseConfig _courseFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final marksList = (d['marks'] as List<dynamic>?)?.map((m) {
      final md = m as Map<String, dynamic>;
      return CourseMark(
        markId: md['markId'] as String? ?? '',
        markName: md['markName'] as String? ?? '',
        order: md['order'] as int? ?? 0,
        rounding: md['rounding'] == 'starboard'
            ? MarkRounding.starboard
            : MarkRounding.port,
        isStart: md['isStart'] as bool? ?? false,
        isFinish: md['isFinish'] as bool? ?? false,
      );
    }).toList() ?? [];

    return CourseConfig(
      id: doc.id,
      courseNumber: d['courseNumber'] as String? ?? '',
      courseName: d['courseName'] as String? ?? '',
      marks: marksList,
      distanceNm: (d['distanceNm'] as num?)?.toDouble() ?? 0,
      windDirectionBand: d['windDirectionBand'] as String? ?? '',
      windDirMin: d['windDirMin'] as int? ?? 0,
      windDirMax: d['windDirMax'] as int? ?? 360,
      finishLocation: d['finishLocation'] as String? ?? 'committee_boat',
      canMultiply: d['canMultiply'] as bool? ?? false,
      requiresInflatable: d['requiresInflatable'] as bool? ?? false,
      inflatableType: d['inflatableType'] as String?,
      isActive: d['isActive'] as bool? ?? true,
      notes: d['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> _courseToMap(CourseConfig c) => {
        'courseNumber': c.courseNumber,
        'courseName': c.courseName,
        'marks': c.marks
            .map((m) => {
                  'markId': m.markId,
                  'markName': m.markName,
                  'order': m.order,
                  'rounding':
                      m.rounding == MarkRounding.starboard ? 'starboard' : 'port',
                  'isStart': m.isStart,
                  'isFinish': m.isFinish,
                })
            .toList(),
        'distanceNm': c.distanceNm,
        'windDirectionBand': c.windDirectionBand,
        'windDirMin': c.windDirMin,
        'windDirMax': c.windDirMax,
        'finishLocation': c.finishLocation,
        'canMultiply': c.canMultiply,
        'requiresInflatable': c.requiresInflatable,
        'inflatableType': c.inflatableType,
        'isActive': c.isActive,
        'notes': c.notes,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  // ── Courses ──

  @override
  Stream<List<CourseConfig>> watchAllCourses() {
    return _coursesCol
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(_courseFromDoc).toList()
          ..sort((a, b) {
            final aNum = int.tryParse(a.courseNumber);
            final bNum = int.tryParse(b.courseNumber);
            if (aNum != null && bNum != null) return aNum.compareTo(bNum);
            if (aNum != null) return -1;
            if (bNum != null) return 1;
            return a.courseNumber.compareTo(b.courseNumber);
          }));
  }

  @override
  Future<CourseConfig?> getCourse(String id) async {
    final doc = await _coursesCol.doc(id).get();
    return doc.exists ? _courseFromDoc(doc) : null;
  }

  @override
  Future<void> saveCourse(CourseConfig course) async {
    if (course.id.isEmpty) {
      final ref = await _coursesCol.add(_courseToMap(course));
      _audit.log(
        action: 'create_course',
        entityType: 'course',
        entityId: ref.id,
        category: 'course',
        details: {'courseNumber': course.courseNumber, 'name': course.courseName},
      );
    } else {
      await _coursesCol.doc(course.id).set(_courseToMap(course), SetOptions(merge: true));
      _audit.log(
        action: 'update_course',
        entityType: 'course',
        entityId: course.id,
        category: 'course',
        details: {'courseNumber': course.courseNumber, 'name': course.courseName},
      );
    }
  }

  @override
  Future<void> deleteCourse(String id) async {
    await _coursesCol.doc(id).delete();
    _audit.log(
      action: 'delete_course',
      entityType: 'course',
      entityId: id,
      category: 'course',
    );
  }

  // ── Marks ──

  @override
  Future<List<Mark>> getMarks() async {
    final snap = await _marksCol.get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return Mark(
        id: doc.id,
        name: d['name'] as String? ?? '',
        type: d['type'] as String? ?? 'permanent',
        code: d['code'] as String?,
        latitude: (d['latitude'] as num?)?.toDouble(),
        longitude: (d['longitude'] as num?)?.toDouble(),
        description: d['description'] as String?,
      );
    }).toList();
  }

  @override
  Stream<List<Mark>> watchMarks() {
    return _marksCol.snapshots().map((snap) => snap.docs.map((doc) {
      final d = doc.data();
      return Mark(
        id: doc.id,
        name: d['name'] as String? ?? '',
        type: d['type'] as String? ?? 'permanent',
        code: d['code'] as String?,
        latitude: (d['latitude'] as num?)?.toDouble(),
        longitude: (d['longitude'] as num?)?.toDouble(),
        description: d['description'] as String?,
      );
    }).toList());
  }

  @override
  Future<void> saveMark(Mark mark) async {
    final data = {
      'name': mark.name,
      'type': mark.type,
      'code': mark.code,
      'latitude': mark.latitude,
      'longitude': mark.longitude,
      'description': mark.description,
    };
    if (mark.id.isEmpty) {
      await _marksCol.add(data);
    } else {
      await _marksCol.doc(mark.id).set(data, SetOptions(merge: true));
    }
    _audit.log(
      action: mark.id.isEmpty ? 'create_mark' : 'update_mark',
      entityType: 'mark',
      entityId: mark.id,
      category: 'course',
      details: {'name': mark.name, 'type': mark.type},
    );
  }

  @override
  Future<void> deleteMark(String id) async {
    await _marksCol.doc(id).delete();
    _audit.log(
      action: 'delete_mark',
      entityType: 'mark',
      entityId: id,
      category: 'course',
    );
  }

  @override
  Future<List<MarkDistance>> getMarkDistances() async {
    final snap = await _distCol.get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return MarkDistance(
        fromMarkId: d['fromMarkId'] as String? ?? '',
        toMarkId: d['toMarkId'] as String? ?? '',
        distanceNm: (d['distanceNm'] as num?)?.toDouble() ?? 0,
        headingMagnetic: (d['headingMagnetic'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  // ── Course selection ──

  @override
  Future<void> selectCourseForEvent(String eventId, String courseId) async {
    await _fs.collection('race_events').doc(eventId).update({
      'courseId': courseId,
      'courseSelectedAt': FieldValue.serverTimestamp(),
    });
    _audit.log(
      action: 'select_course',
      entityType: 'race_event',
      entityId: eventId,
      category: 'course',
      details: {'courseId': courseId},
    );
  }

  @override
  Stream<String?> watchSelectedCourse(String eventId) {
    return _fs
        .collection('race_events')
        .doc(eventId)
        .snapshots()
        .map((snap) => snap.data()?['courseId'] as String?);
  }

  // ── Fleet broadcasts ──

  @override
  Future<void> sendBroadcast(FleetBroadcast broadcast) async {
    await _broadcastsCol.add({
      'eventId': broadcast.eventId,
      'sentBy': broadcast.sentBy,
      'message': broadcast.message,
      'type': broadcast.type.name,
      'sentAt': Timestamp.fromDate(broadcast.sentAt),
      'deliveryCount': broadcast.deliveryCount,
      'target': broadcast.target.name,
      'requiresAck': broadcast.requiresAck,
      'ackCount': broadcast.ackCount,
    });
    _audit.log(
      action: 'send_broadcast',
      entityType: 'fleet_broadcast',
      entityId: broadcast.eventId,
      category: 'course',
      details: {
        'type': broadcast.type.name,
        'message': broadcast.message,
        'target': broadcast.target.name,
      },
    );
  }

  @override
  Stream<List<FleetBroadcast>> watchBroadcasts({String? eventId}) {
    var query = _broadcastsCol.orderBy('sentAt', descending: true);
    if (eventId != null) {
      query = _broadcastsCol
          .where('eventId', isEqualTo: eventId)
          .orderBy('sentAt', descending: true);
    }
    return query.snapshots().map((snap) => snap.docs.map((doc) {
          final d = doc.data();
          return FleetBroadcast(
            id: doc.id,
            eventId: d['eventId'] as String? ?? '',
            sentBy: d['sentBy'] as String? ?? '',
            message: d['message'] as String? ?? '',
            type: BroadcastType.values.firstWhere(
              (t) => t.name == (d['type'] as String? ?? ''),
              orElse: () => BroadcastType.general,
            ),
            sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            deliveryCount: d['deliveryCount'] as int? ?? 0,
            target: BroadcastTarget.values.firstWhere(
              (t) => t.name == (d['target'] as String? ?? ''),
              orElse: () => BroadcastTarget.everyone,
            ),
            requiresAck: d['requiresAck'] as bool? ?? false,
            ackCount: d['ackCount'] as int? ?? 0,
          );
        }).toList());
  }

}
