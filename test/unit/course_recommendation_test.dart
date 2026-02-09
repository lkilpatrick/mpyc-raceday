import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/courses/data/models/course_config.dart';
import 'package:mpyc_raceday/features/courses/presentation/courses_providers.dart';

CourseConfig _makeCourse({
  required String id,
  required String band,
  required int min,
  required int max,
  double distance = 3.0,
}) {
  return CourseConfig(
    id: id,
    courseNumber: id,
    courseName: 'Course $id',
    marks: const [],
    distanceNm: distance,
    windDirectionBand: band,
    windDirMin: min,
    windDirMax: max,
    finishLocation: 'committee_boat',
  );
}

void main() {
  group('getCourseRecommendation', () {
    test('returns RECOMMENDED when wind is in band', () {
      final course = _makeCourse(id: '1', band: 'NW', min: 270, max: 360);
      expect(getCourseRecommendation(course, 300), 'RECOMMENDED');
    });

    test('returns POSSIBLE when wind is within 15° of band', () {
      final course = _makeCourse(id: '1', band: 'NW', min: 270, max: 360);
      // 260 is outside [270,360] but within [255,375]
      expect(getCourseRecommendation(course, 260), 'POSSIBLE');
    });

    test('returns NOT RECOMMENDED when wind is far outside band', () {
      final course = _makeCourse(id: '1', band: 'NW', min: 270, max: 360);
      expect(getCourseRecommendation(course, 90), 'NOT RECOMMENDED');
    });

    test('returns AVAILABLE for INFLATABLE courses regardless of wind', () {
      final course = _makeCourse(id: 'I1', band: 'INFLATABLE', min: 0, max: 0);
      expect(getCourseRecommendation(course, 180), 'AVAILABLE');
      expect(getCourseRecommendation(course, 0), 'AVAILABLE');
      expect(getCourseRecommendation(course, 350), 'AVAILABLE');
    });
  });

  group('360° wraparound', () {
    test('northerly band wrapping 320-020 matches 350', () {
      final course = _makeCourse(id: 'N1', band: 'N', min: 320, max: 20);
      expect(getCourseRecommendation(course, 350), 'RECOMMENDED');
    });

    test('northerly band wrapping 320-020 matches 10', () {
      final course = _makeCourse(id: 'N1', band: 'N', min: 320, max: 20);
      expect(getCourseRecommendation(course, 10), 'RECOMMENDED');
    });

    test('northerly band wrapping 320-020 matches 0', () {
      final course = _makeCourse(id: 'N1', band: 'N', min: 320, max: 20);
      expect(getCourseRecommendation(course, 0), 'RECOMMENDED');
    });

    test('northerly band wrapping 320-020 does NOT match 180', () {
      final course = _makeCourse(id: 'N1', band: 'N', min: 320, max: 20);
      expect(getCourseRecommendation(course, 180), 'NOT RECOMMENDED');
    });

    test('northerly band wrapping 320-020 POSSIBLE at 310', () {
      final course = _makeCourse(id: 'N1', band: 'N', min: 320, max: 20);
      // 310 is within [305, 35] extended band
      expect(getCourseRecommendation(course, 310), 'POSSIBLE');
    });
  });

  group('edge cases', () {
    test('wind exactly at min boundary', () {
      final course = _makeCourse(id: '1', band: 'S', min: 150, max: 210);
      expect(getCourseRecommendation(course, 150), 'RECOMMENDED');
    });

    test('wind exactly at max boundary', () {
      final course = _makeCourse(id: '1', band: 'S', min: 150, max: 210);
      expect(getCourseRecommendation(course, 210), 'RECOMMENDED');
    });

    test('wind at 360 treated same as 0', () {
      final course = _makeCourse(id: 'N1', band: 'N', min: 350, max: 10);
      final rec360 = getCourseRecommendation(course, 360);
      final rec0 = getCourseRecommendation(course, 0);
      expect(rec360, rec0);
    });

    test('negative wind direction normalized', () {
      final course = _makeCourse(id: '1', band: 'W', min: 250, max: 290);
      // -90 normalizes to 270
      expect(getCourseRecommendation(course, -90), 'RECOMMENDED');
    });
  });
}
