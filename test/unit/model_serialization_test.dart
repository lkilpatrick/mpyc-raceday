import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/boat_checkin/data/models/boat.dart';
import 'package:mpyc_raceday/features/boat_checkin/data/models/boat_checkin.dart';
import 'package:mpyc_raceday/features/timing/data/models/timing_models.dart';
import 'package:mpyc_raceday/features/courses/data/models/course_config.dart';

void main() {
  group('Boat model', () {
    test('creates with all fields', () {
      final boat = Boat(
        id: 'b1',
        sailNumber: '42',
        boatName: 'Wind Dancer',
        ownerName: 'John Doe',
        boatClass: 'J/105',
        phrfRating: 84,
        lastRacedAt: DateTime(2024, 6, 15),
        raceCount: 12,
        isActive: true,
        phone: '555-0100',
        email: 'john@example.com',
      );

      expect(boat.sailNumber, '42');
      expect(boat.phrfRating, 84);
      expect(boat.raceCount, 12);
      expect(boat.isActive, true);
    });

    test('defaults are correct', () {
      final boat = Boat(
        id: 'b2',
        sailNumber: '100',
        boatName: 'Sea Breeze',
        ownerName: 'Jane Smith',
        boatClass: 'Catalina 30',
      );

      expect(boat.phrfRating, isNull);
      expect(boat.lastRacedAt, isNull);
      expect(boat.raceCount, 0);
      expect(boat.isActive, true);
      expect(boat.phone, isNull);
      expect(boat.email, isNull);
    });
  });

  group('BoatCheckin model', () {
    test('creates with all fields', () {
      final checkin = BoatCheckin(
        id: 'c1',
        eventId: 'e1',
        boatId: 'b1',
        sailNumber: '42',
        boatName: 'Wind Dancer',
        skipperName: 'John Doe',
        boatClass: 'J/105',
        checkedInAt: DateTime(2024, 6, 15, 9, 0),
        checkedInBy: 'admin1',
        crewCount: 3,
        crewNames: ['Alice', 'Bob', 'Charlie'],
        safetyEquipmentVerified: true,
        phrfRating: 84,
        notes: 'New jib',
      );

      expect(checkin.sailNumber, '42');
      expect(checkin.crewCount, 3);
      expect(checkin.crewNames, hasLength(3));
      expect(checkin.safetyEquipmentVerified, true);
      expect(checkin.phrfRating, 84);
    });

    test('defaults are correct', () {
      final checkin = BoatCheckin(
        id: 'c2',
        eventId: 'e1',
        boatId: 'b2',
        sailNumber: '100',
        boatName: 'Sea Breeze',
        skipperName: 'Jane Smith',
        boatClass: 'Catalina 30',
        checkedInAt: DateTime.now(),
        checkedInBy: 'admin1',
        crewCount: 1,
        safetyEquipmentVerified: false,
      );

      expect(checkin.crewNames, isEmpty);
      expect(checkin.phrfRating, isNull);
      expect(checkin.notes, '');
    });
  });

  group('RaceStart model', () {
    test('creates with required fields', () {
      final start = RaceStart(
        id: 'rs1',
        eventId: 'e1',
        raceNumber: 1,
        className: 'Fleet A',
      );

      expect(start.warningSignalTime, isNull);
      expect(start.prepSignalTime, isNull);
      expect(start.startTime, isNull);
      expect(start.isGeneralRecall, false);
      expect(start.isPostponed, false);
      expect(start.notes, '');
    });

    test('copyWith preserves unmodified fields', () {
      final start = RaceStart(
        id: 'rs1',
        eventId: 'e1',
        raceNumber: 1,
        className: 'Fleet A',
        notes: 'Good conditions',
      );

      final updated = start.copyWith(isGeneralRecall: true);
      expect(updated.id, 'rs1');
      expect(updated.eventId, 'e1');
      expect(updated.raceNumber, 1);
      expect(updated.className, 'Fleet A');
      expect(updated.notes, 'Good conditions');
      expect(updated.isGeneralRecall, true);
    });

    test('copyWith can set all signal times', () {
      final start = RaceStart(
        id: 'rs1',
        eventId: 'e1',
        raceNumber: 1,
        className: 'Fleet A',
      );

      final warning = DateTime(2024, 6, 15, 13, 0);
      final prep = DateTime(2024, 6, 15, 13, 1);
      final go = DateTime(2024, 6, 15, 13, 5);

      final updated = start.copyWith(
        warningSignalTime: warning,
        prepSignalTime: prep,
        startTime: go,
      );

      expect(updated.warningSignalTime, warning);
      expect(updated.prepSignalTime, prep);
      expect(updated.startTime, go);
    });
  });

  group('FinishRecord model', () {
    test('creates finished record', () {
      final record = FinishRecord(
        id: 'f1',
        raceStartId: 'rs1',
        sailNumber: '42',
        finishTimestamp: DateTime(2024, 6, 15, 14, 30),
        elapsedSeconds: 5400,
        letterScore: LetterScore.finished,
        position: 1,
      );

      expect(record.letterScore, LetterScore.finished);
      expect(record.elapsedSeconds, 5400);
      expect(record.position, 1);
      expect(record.boatName, '');
      expect(record.correctedSeconds, isNull);
    });

    test('creates DNF record', () {
      final record = FinishRecord(
        id: 'f2',
        raceStartId: 'rs1',
        sailNumber: '100',
        finishTimestamp: DateTime.now(),
        elapsedSeconds: 0,
        letterScore: LetterScore.dnf,
        position: 0,
      );

      expect(record.letterScore, LetterScore.dnf);
      expect(record.position, 0);
    });

    test('copyWith updates corrected time and position', () {
      final record = FinishRecord(
        id: 'f1',
        raceStartId: 'rs1',
        sailNumber: '42',
        finishTimestamp: DateTime(2024, 6, 15, 14, 30),
        elapsedSeconds: 5400,
        letterScore: LetterScore.finished,
        position: 3,
      );

      final corrected = record.copyWith(
        correctedSeconds: 5200.0,
        position: 1,
      );

      expect(corrected.correctedSeconds, 5200.0);
      expect(corrected.position, 1);
      expect(corrected.sailNumber, '42'); // unchanged
      expect(corrected.elapsedSeconds, 5400); // unchanged
    });

    test('all LetterScore values are distinct', () {
      final scores = LetterScore.values;
      expect(scores, hasLength(7));
      expect(scores.toSet(), hasLength(7));
      expect(scores, contains(LetterScore.dns));
      expect(scores, contains(LetterScore.dnf));
      expect(scores, contains(LetterScore.dsq));
      expect(scores, contains(LetterScore.ocs));
      expect(scores, contains(LetterScore.raf));
      expect(scores, contains(LetterScore.ret));
      expect(scores, contains(LetterScore.finished));
    });
  });

  group('HandicapRating model', () {
    test('creates with all fields', () {
      final rating = HandicapRating(
        sailNumber: '42',
        phrfRating: 84,
        boatClass: 'J/105',
      );

      expect(rating.sailNumber, '42');
      expect(rating.phrfRating, 84);
      expect(rating.boatClass, 'J/105');
    });

    test('default boatClass is empty', () {
      final rating = HandicapRating(
        sailNumber: '100',
        phrfRating: 168,
      );

      expect(rating.boatClass, '');
    });
  });

  group('CourseConfig model', () {
    test('creates with all fields', () {
      final course = CourseConfig(
        id: 'c1',
        courseNumber: '1A',
        courseName: 'Short Windward-Leeward',
        marks: [
          CourseMark(
            markId: 'm1',
            markName: 'W',
            order: 1,
            rounding: MarkRounding.port,
          ),
          CourseMark(
            markId: 'm2',
            markName: 'L',
            order: 2,
            rounding: MarkRounding.starboard,
            isFinish: true,
          ),
        ],
        distanceNm: 2.5,
        windDirectionBand: 'NW',
        windDirMin: 280,
        windDirMax: 340,
        finishLocation: 'committee_boat',
      );

      expect(course.courseNumber, '1A');
      expect(course.marks, hasLength(2));
      expect(course.distanceNm, 2.5);
      expect(course.canMultiply, false);
      expect(course.requiresInflatable, false);
      expect(course.isActive, true);
      expect(course.createdAt, isNull);
      expect(course.updatedAt, isNull);
    });

    test('markSequenceDisplay formats correctly', () {
      final course = CourseConfig(
        id: 'c1',
        courseNumber: '1A',
        courseName: 'Test',
        marks: [
          CourseMark(
            markId: 'm1',
            markName: 'W',
            order: 1,
            rounding: MarkRounding.port,
          ),
          CourseMark(
            markId: 'm2',
            markName: 'L',
            order: 2,
            rounding: MarkRounding.starboard,
          ),
          CourseMark(
            markId: 'm3',
            markName: 'X',
            order: 3,
            rounding: MarkRounding.port,
            isFinish: true,
          ),
        ],
        distanceNm: 3.0,
        windDirectionBand: 'NW',
        windDirMin: 280,
        windDirMax: 340,
        finishLocation: 'mark_x',
      );

      expect(course.markSequenceDisplay, 'START \u2192 Wp \u2192 Ls \u2192 FINISH');
    });

    test('empty marks produces empty display', () {
      final course = CourseConfig(
        id: 'c2',
        courseNumber: '2',
        courseName: 'Empty',
        marks: [],
        distanceNm: 0,
        windDirectionBand: 'ANY',
        windDirMin: 0,
        windDirMax: 360,
        finishLocation: 'committee_boat',
      );

      expect(course.markSequenceDisplay, 'START \u2192 FINISH');
    });
  });
}
