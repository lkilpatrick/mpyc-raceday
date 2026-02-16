import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/courses/data/models/course_config.dart';
import 'package:mpyc_raceday/features/courses/data/models/fleet_broadcast.dart';
import 'package:mpyc_raceday/features/courses/data/models/mark.dart';
import 'package:mpyc_raceday/features/courses/data/models/mark_distance.dart';

void main() {
  group('Mark model', () {
    test('creates with required fields', () {
      const mark = Mark(
        id: 'MY1',
        name: 'MY 1',
        type: 'permanent',
      );

      expect(mark.id, 'MY1');
      expect(mark.name, 'MY 1');
      expect(mark.type, 'permanent');
      expect(mark.code, isNull);
      expect(mark.latitude, isNull);
      expect(mark.longitude, isNull);
      expect(mark.description, isNull);
    });

    test('creates with all optional fields', () {
      const mark = Mark(
        id: '4',
        name: '4',
        type: 'government',
        code: '4',
        latitude: 36.624333,
        longitude: -121.895667,
        description: 'Red can "4" — Fl R 4s, bell',
      );

      expect(mark.code, '4');
      expect(mark.latitude, 36.624333);
      expect(mark.longitude, -121.895667);
      expect(mark.description, contains('Red can'));
    });

    test('all mark types are valid strings', () {
      for (final type in ['permanent', 'temporary', 'government', 'harbor']) {
        final mark = Mark(id: 'test', name: 'test', type: type);
        expect(mark.type, type);
      }
    });
  });

  group('MarkDistance model', () {
    test('creates with all fields', () {
      const dist = MarkDistance(
        fromMarkId: 'X',
        toMarkId: '4',
        distanceNm: 0.85,
        headingMagnetic: 215.0,
      );

      expect(dist.fromMarkId, 'X');
      expect(dist.toMarkId, '4');
      expect(dist.distanceNm, 0.85);
      expect(dist.headingMagnetic, 215.0);
    });

    test('zero distance is valid', () {
      const dist = MarkDistance(
        fromMarkId: 'A',
        toMarkId: 'A',
        distanceNm: 0.0,
        headingMagnetic: 0.0,
      );

      expect(dist.distanceNm, 0.0);
    });
  });

  group('BroadcastType', () {
    test('has all expected values', () {
      expect(BroadcastType.values, hasLength(12));
      expect(BroadcastType.values, contains(BroadcastType.courseSelection));
      expect(BroadcastType.values, contains(BroadcastType.postponement));
      expect(BroadcastType.values, contains(BroadcastType.abandonment));
      expect(BroadcastType.values, contains(BroadcastType.courseChange));
      expect(BroadcastType.values, contains(BroadcastType.generalRecall));
      expect(BroadcastType.values, contains(BroadcastType.shortenedCourse));
      expect(BroadcastType.values, contains(BroadcastType.cancellation));
      expect(BroadcastType.values, contains(BroadcastType.general));
      expect(BroadcastType.values, contains(BroadcastType.vhfChannelChange));
      expect(BroadcastType.values, contains(BroadcastType.shortenCourse));
      expect(BroadcastType.values, contains(BroadcastType.abandonTooMuchWind));
      expect(BroadcastType.values, contains(BroadcastType.abandonTooLittleWind));
    });
  });

  group('FleetBroadcast model', () {
    test('creates with all fields', () {
      final broadcast = FleetBroadcast(
        id: 'fb1',
        eventId: 'e1',
        sentBy: 'PRO',
        message: 'Course 3A selected for all fleets',
        type: BroadcastType.courseSelection,
        sentAt: DateTime(2024, 6, 15, 12, 30),
        deliveryCount: 25,
      );

      expect(broadcast.id, 'fb1');
      expect(broadcast.eventId, 'e1');
      expect(broadcast.sentBy, 'PRO');
      expect(broadcast.message, contains('Course 3A'));
      expect(broadcast.type, BroadcastType.courseSelection);
      expect(broadcast.sentAt, DateTime(2024, 6, 15, 12, 30));
      expect(broadcast.deliveryCount, 25);
    });

    test('all broadcast types can be used', () {
      for (final type in BroadcastType.values) {
        final broadcast = FleetBroadcast(
          id: 'test',
          eventId: 'e1',
          sentBy: 'PRO',
          message: 'Test',
          type: type,
          sentAt: DateTime.now(),
          deliveryCount: 0,
        );
        expect(broadcast.type, type);
      }
    });
  });

  group('MarkRounding', () {
    test('has port and starboard', () {
      expect(MarkRounding.values, hasLength(2));
      expect(MarkRounding.values, contains(MarkRounding.port));
      expect(MarkRounding.values, contains(MarkRounding.starboard));
    });
  });

  group('CourseMark model', () {
    test('creates with required fields and defaults', () {
      const mark = CourseMark(
        markId: 'X',
        markName: 'X',
        order: 1,
        rounding: MarkRounding.port,
      );

      expect(mark.markId, 'X');
      expect(mark.markName, 'X');
      expect(mark.order, 1);
      expect(mark.rounding, MarkRounding.port);
      expect(mark.isStart, false);
      expect(mark.isFinish, false);
    });

    test('creates start mark', () {
      const mark = CourseMark(
        markId: '1',
        markName: '1',
        order: 1,
        rounding: MarkRounding.port,
        isStart: true,
      );

      expect(mark.isStart, true);
      expect(mark.isFinish, false);
    });

    test('creates finish mark', () {
      const mark = CourseMark(
        markId: '1',
        markName: '1',
        order: 5,
        rounding: MarkRounding.port,
        isFinish: true,
      );

      expect(mark.isStart, false);
      expect(mark.isFinish, true);
    });
  });

  group('CourseConfig windGroup getter', () {
    test('returns WindGroup for known band', () {
      final course = CourseConfig(
        id: 'c1',
        courseNumber: '1A',
        courseName: 'Short WL',
        marks: const [],
        distanceNm: 2.5,
        windDirectionBand: 'NW',
        windDirMin: 280,
        windDirMax: 340,
        finishLocation: 'committee_boat',
      );

      expect(course.windGroup, isNotNull);
      expect(course.windGroup!.id, 'NW');
      expect(course.windGroup!.label, 'North Westerly');
    });

    test('returns null for unknown band', () {
      final course = CourseConfig(
        id: 'c1',
        courseNumber: '1A',
        courseName: 'Test',
        marks: const [],
        distanceNm: 2.5,
        windDirectionBand: 'UNKNOWN',
        windDirMin: 0,
        windDirMax: 360,
        finishLocation: 'committee_boat',
      );

      expect(course.windGroup, isNull);
    });
  });

  group('CourseConfig markSequenceDisplay', () {
    test('formats port and starboard roundings with arrow separator', () {
      final course = CourseConfig(
        id: 'c1',
        courseNumber: '1A',
        courseName: 'Test',
        marks: const [
          CourseMark(
            markId: 'X',
            markName: 'X',
            order: 1,
            rounding: MarkRounding.port,
          ),
          CourseMark(
            markId: '4',
            markName: '4',
            order: 2,
            rounding: MarkRounding.starboard,
          ),
        ],
        distanceNm: 3.0,
        windDirectionBand: 'NW',
        windDirMin: 280,
        windDirMax: 340,
        finishLocation: 'committee_boat',
      );

      // Uses arrow separator and p/s suffixes, plus START/FINISH
      expect(course.markSequenceDisplay, 'START \u2192 Xp \u2192 4s \u2192 FINISH');
    });

    test('shows START and FINISH labels for start/finish marks', () {
      final course = CourseConfig(
        id: 'c1',
        courseNumber: '1A',
        courseName: 'Test',
        marks: const [
          CourseMark(
            markId: '1',
            markName: '1',
            order: 1,
            rounding: MarkRounding.port,
            isStart: true,
          ),
          CourseMark(
            markId: 'X',
            markName: 'X',
            order: 2,
            rounding: MarkRounding.port,
          ),
          CourseMark(
            markId: '1',
            markName: '1',
            order: 3,
            rounding: MarkRounding.port,
            isFinish: true,
          ),
        ],
        distanceNm: 2.0,
        windDirectionBand: 'S_SW',
        windDirMin: 180,
        windDirMax: 240,
        finishLocation: 'committee_boat',
      );

      expect(course.markSequenceDisplay, contains('START'));
      expect(course.markSequenceDisplay, contains('FINISH'));
      expect(course.markSequenceDisplay, contains('Xp'));
    });

    test('empty marks returns empty string', () {
      final course = CourseConfig(
        id: 'c1',
        courseNumber: '1A',
        courseName: 'Empty',
        marks: const [],
        distanceNm: 0,
        windDirectionBand: 'ANY',
        windDirMin: 0,
        windDirMax: 360,
        finishLocation: 'committee_boat',
      );

      expect(course.markSequenceDisplay, 'START \u2192 FINISH');
    });
  });

  group('CourseConfig defaults', () {
    test('optional fields default correctly', () {
      final course = CourseConfig(
        id: 'c1',
        courseNumber: '1A',
        courseName: 'Test',
        marks: const [],
        distanceNm: 2.0,
        windDirectionBand: 'NW',
        windDirMin: 280,
        windDirMax: 340,
        finishLocation: 'committee_boat',
      );

      expect(course.canMultiply, false);
      expect(course.requiresInflatable, false);
      expect(course.isActive, true);
      expect(course.inflatableType, isNull);
      expect(course.notes, '');
      expect(course.createdAt, isNull);
      expect(course.updatedAt, isNull);
    });
  });
}
