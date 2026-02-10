import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/courses/data/models/course_config.dart';
import 'package:mpyc_raceday/features/courses/presentation/courses_providers.dart';

void main() {
  final courses = [
    CourseConfig(
      id: 'c1', courseNumber: '1', courseName: 'Course 1',
      marks: const [], distanceNm: 2.5, windDirectionBand: 'NW',
      windDirMin: 295, windDirMax: 320, finishLocation: 'committee_boat',
    ),
    CourseConfig(
      id: 'c2', courseNumber: '2', courseName: 'Course 2',
      marks: const [], distanceNm: 3.0, windDirectionBand: 'NW',
      windDirMin: 295, windDirMax: 320, finishLocation: 'mark_x',
      canMultiply: true,
    ),
    CourseConfig(
      id: 'c3', courseNumber: '3', courseName: 'Course 3',
      marks: const [], distanceNm: 4.0, windDirectionBand: 'S_SW',
      windDirMin: 200, windDirMax: 260, finishLocation: 'committee_boat',
    ),
    CourseConfig(
      id: 'c4', courseNumber: 'I1', courseName: 'Inflatable 1',
      marks: const [], distanceNm: 1.5, windDirectionBand: 'INFLATABLE',
      windDirMin: 0, windDirMax: 0, finishLocation: 'committee_boat',
      requiresInflatable: true, inflatableType: 'windward',
    ),
  ];

  group('Recommendation badges match conditions', () {
    test('NW course recommended for 300° wind', () {
      final rec = getCourseRecommendation(courses[0], 300);
      expect(rec, 'RECOMMENDED');
    });

    test('NW course not recommended for 180° wind', () {
      final rec = getCourseRecommendation(courses[0], 180);
      expect(rec, 'NOT RECOMMENDED');
    });

    test('S_SW course recommended for 220° wind', () {
      final rec = getCourseRecommendation(courses[2], 220);
      expect(rec, 'RECOMMENDED');
    });

    test('inflatable course always AVAILABLE', () {
      final rec = getCourseRecommendation(courses[3], 180);
      expect(rec, 'AVAILABLE');
    });

    test('NW course POSSIBLE for 285° wind (within 15° margin)', () {
      final rec = getCourseRecommendation(courses[0], 285);
      expect(rec, 'POSSIBLE');
    });
  });

  group('Course filtering by wind band', () {
    test('filter NW courses', () {
      final nw = courses.where((c) => c.windDirectionBand == 'NW').toList();
      expect(nw, hasLength(2));
    });

    test('filter S_SW courses', () {
      final ssw = courses.where((c) => c.windDirectionBand == 'S_SW').toList();
      expect(ssw, hasLength(1));
    });

    test('filter INFLATABLE courses', () {
      final inf = courses.where((c) => c.windDirectionBand == 'INFLATABLE').toList();
      expect(inf, hasLength(1));
      expect(inf.first.requiresInflatable, true);
    });
  });

  group('Course sorting', () {
    test('sort by distance ascending', () {
      final sorted = List<CourseConfig>.from(courses)
        ..sort((a, b) => a.distanceNm.compareTo(b.distanceNm));
      expect(sorted.first.distanceNm, 1.5);
      expect(sorted.last.distanceNm, 4.0);
    });

    test('sort by course number', () {
      final sorted = List<CourseConfig>.from(courses)
        ..sort((a, b) {
          final aNum = int.tryParse(a.courseNumber) ?? 999;
          final bNum = int.tryParse(b.courseNumber) ?? 999;
          return aNum.compareTo(bNum);
        });
      expect(sorted.first.courseNumber, '1');
      expect(sorted.last.courseNumber, 'I1'); // non-numeric sorts last
    });
  });

  group('Wind band auto-selection', () {
    String bandForWind(double dir) {
      if (dir >= 200 && dir < 260) return 'S_SW';
      if (dir >= 260 && dir < 295) return 'W';
      if (dir >= 295 && dir < 320) return 'NW';
      if (dir >= 320 || dir < 35) return 'N';
      return 'NW';
    }

    test('200° selects S_SW', () => expect(bandForWind(200), 'S_SW'));
    test('270° selects W', () => expect(bandForWind(270), 'W'));
    test('300° selects NW', () => expect(bandForWind(300), 'NW'));
    test('350° selects N', () => expect(bandForWind(350), 'N'));
    test('10° selects N', () => expect(bandForWind(10), 'N'));
  });

  group('Course properties', () {
    test('canMultiply flag', () {
      expect(courses[1].canMultiply, true);
      expect(courses[0].canMultiply, false);
    });

    test('requiresInflatable flag', () {
      expect(courses[3].requiresInflatable, true);
      expect(courses[3].inflatableType, 'windward');
    });

    test('finish location types', () {
      expect(courses[0].finishLocation, 'committee_boat');
      expect(courses[1].finishLocation, 'mark_x');
    });

    test('mark sequence display', () {
      final course = CourseConfig(
        id: 'test', courseNumber: '1', courseName: 'Test',
        marks: const [
          CourseMark(markId: 'm1', markName: 'A', order: 1, rounding: MarkRounding.port),
          CourseMark(markId: 'm2', markName: 'B', order: 2, rounding: MarkRounding.starboard, isFinish: true),
        ],
        distanceNm: 2.0, windDirectionBand: 'NW',
        windDirMin: 295, windDirMax: 320, finishLocation: 'committee_boat',
      );
      expect(course.markSequenceDisplay, contains('Ap'));
      expect(course.markSequenceDisplay, contains('FINISH'));
    });
  });
}
