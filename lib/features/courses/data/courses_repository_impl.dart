import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/courses_repository.dart';
import 'models/course_config.dart';
import 'models/fleet_broadcast.dart';
import 'models/mark.dart';
import 'models/mark_distance.dart';

class CoursesRepositoryImpl implements CoursesRepository {
  CoursesRepositoryImpl({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _fs;

  CollectionReference<Map<String, dynamic>> get _coursesCol =>
      _fs.collection('courses');
  CollectionReference<Map<String, dynamic>> get _marksCol =>
      _fs.collection('marks');
  CollectionReference<Map<String, dynamic>> get _distCol =>
      _fs.collection('mark_distances');
  CollectionReference<Map<String, dynamic>> get _broadcastsCol =>
      _fs.collection('fleet_broadcasts');

  // ── Mark abbreviation mapping ──
  static const _markAbbrevMap = {
    'X': 'X', 'C': 'C', 'P': 'P', 'M': 'MY2', 'LV': 'LV',
    '1': 'MY1', '3': 'MY3', '4': 'MY4',
    'W': 'W', 'R': 'R', 'L': 'L',
  };

  static String _resolveMarkId(String abbrev) =>
      _markAbbrevMap[abbrev] ?? abbrev;

  static String _resolveMarkName(String abbrev) {
    const nameMap = {
      'X': 'X', 'C': 'C', 'P': 'P', 'M': 'M', 'LV': 'LV',
      '1': 'MY 1', '3': 'MY 3', '4': 'MY 4',
      'W': 'W', 'R': 'R', 'L': 'L',
    };
    return nameMap[abbrev] ?? abbrev;
  }

  /// Parse "Xp-1p-4s-Finish" into List<CourseMark>
  static List<CourseMark> _parseMarks(String seq) {
    final parts = seq.split('-');
    final marks = <CourseMark>[];
    int order = 1;
    for (final part in parts) {
      final p = part.trim();
      if (p == 'Finish') {
        // Tag previous mark as finish if exists, or add a finish marker
        if (marks.isNotEmpty) {
          final last = marks.removeLast();
          marks.add(CourseMark(
            markId: last.markId,
            markName: last.markName,
            order: last.order,
            rounding: last.rounding,
            isFinish: true,
          ));
        }
        continue;
      }
      // Last char is p or s for rounding
      final rChar = p[p.length - 1];
      final rounding =
          rChar == 's' ? MarkRounding.starboard : MarkRounding.port;
      final abbrev = p.substring(0, p.length - 1);
      marks.add(CourseMark(
        markId: _resolveMarkId(abbrev),
        markName: _resolveMarkName(abbrev),
        order: order++,
        rounding: rounding,
        isFinish: false,
      ));
    }
    // If last mark in sequence and no Finish token, mark last as finish
    // (for sequences like "Cp-Xp" that end at X)
    if (marks.isNotEmpty && !marks.any((m) => m.isFinish)) {
      final last = marks.removeLast();
      marks.add(CourseMark(
        markId: last.markId,
        markName: last.markName,
        order: last.order,
        rounding: last.rounding,
        isFinish: true,
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
      await _coursesCol.add(_courseToMap(course));
    } else {
      await _coursesCol.doc(course.id).set(_courseToMap(course), SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteCourse(String id) async {
    await _coursesCol.doc(id).delete();
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
      'latitude': mark.latitude,
      'longitude': mark.longitude,
      'description': mark.description,
    };
    if (mark.id.isEmpty) {
      await _marksCol.add(data);
    } else {
      await _marksCol.doc(mark.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteMark(String id) async {
    await _marksCol.doc(id).delete();
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
    });
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
          );
        }).toList());
  }

  // ── Seed ──

  @override
  Future<void> seedFromJson(String jsonString) async {
    final data = json.decode(jsonString) as Map<String, dynamic>;

    // Seed marks
    final marks = data['marks'] as List<dynamic>;
    for (final m in marks) {
      final md = m as Map<String, dynamic>;
      await _marksCol.doc(md['id'] as String).set({
        'name': md['name'],
        'type': md['type'],
        'latitude': md['latitude'],
        'longitude': md['longitude'],
        'description': md['description'],
      });
    }

    // Seed mark distances
    final distances = data['mark_distances'] as List<dynamic>;
    for (final d in distances) {
      final dd = d as Map<String, dynamic>;
      final from = dd['from'] as String;
      final to = dd['to'] as String;
      await _distCol.doc('${from}_$to').set({
        'fromMarkId': from,
        'toMarkId': to,
        'distanceNm': dd['distance'],
        'headingMagnetic': dd['heading'],
      });
    }

    // Seed courses
    final courses = data['courses'] as List<dynamic>;
    for (final c in courses) {
      final cd = c as Map<String, dynamic>;
      final num = cd['num'] as String;
      final markSeq = cd['marks'] as String;
      final parsedMarks = _parseMarks(markSeq);
      final courseName = 'Course $num — $markSeq';

      await _coursesCol.doc('course_$num').set({
        'courseNumber': num,
        'courseName': courseName,
        'marks': parsedMarks
            .map((m) => {
                  'markId': m.markId,
                  'markName': m.markName,
                  'order': m.order,
                  'rounding': m.rounding == MarkRounding.starboard
                      ? 'starboard'
                      : 'port',
                  'isFinish': m.isFinish,
                })
            .toList(),
        'distanceNm': cd['dist'],
        'windDirectionBand': cd['band'],
        'windDirMin': cd['dirMin'],
        'windDirMax': cd['dirMax'],
        'finishLocation': cd['finish'],
        'canMultiply': cd['x2'] ?? false,
        'requiresInflatable': cd['inflatable'] ?? false,
        'inflatableType': cd['infType'],
        'isActive': true,
        'notes': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
