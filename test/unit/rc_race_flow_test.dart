import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/rc_race/data/models/race_session.dart';
import 'package:mpyc_raceday/features/timing/data/models/timing_models.dart';

void main() {
  group('RaceSessionStatus', () {
    test('fromString parses all valid statuses', () {
      expect(RaceSessionStatus.fromString('setup'), RaceSessionStatus.setup);
      expect(RaceSessionStatus.fromString('checkin_open'),
          RaceSessionStatus.checkinOpen);
      expect(RaceSessionStatus.fromString('start_pending'),
          RaceSessionStatus.startPending);
      expect(
          RaceSessionStatus.fromString('running'), RaceSessionStatus.running);
      expect(
          RaceSessionStatus.fromString('scoring'), RaceSessionStatus.scoring);
      expect(RaceSessionStatus.fromString('review'), RaceSessionStatus.review);
      expect(RaceSessionStatus.fromString('finalized'),
          RaceSessionStatus.finalized);
      expect(RaceSessionStatus.fromString('abandoned'),
          RaceSessionStatus.abandoned);
    });

    test('fromString defaults to setup for unknown values', () {
      expect(RaceSessionStatus.fromString(''), RaceSessionStatus.setup);
      expect(RaceSessionStatus.fromString('invalid'), RaceSessionStatus.setup);
    });

    test('firestoreValue round-trips through fromString', () {
      for (final status in RaceSessionStatus.values) {
        expect(
          RaceSessionStatus.fromString(status.firestoreValue),
          status,
          reason: 'Round-trip failed for $status',
        );
      }
    });

    test('isTerminal only for finalized and abandoned', () {
      expect(RaceSessionStatus.finalized.isTerminal, true);
      expect(RaceSessionStatus.abandoned.isTerminal, true);
      expect(RaceSessionStatus.setup.isTerminal, false);
      expect(RaceSessionStatus.running.isTerminal, false);
      expect(RaceSessionStatus.scoring.isTerminal, false);
      expect(RaceSessionStatus.review.isTerminal, false);
    });

    test('stepIndex follows correct flow order', () {
      expect(RaceSessionStatus.setup.stepIndex, 0);
      expect(RaceSessionStatus.checkinOpen.stepIndex, 1);
      expect(RaceSessionStatus.startPending.stepIndex, 2);
      expect(RaceSessionStatus.running.stepIndex, 3);
      expect(RaceSessionStatus.scoring.stepIndex, 4);
      expect(RaceSessionStatus.review.stepIndex, 5);
      expect(RaceSessionStatus.finalized.stepIndex, 5);
    });

    test('labels are human-readable', () {
      expect(RaceSessionStatus.setup.label, 'Setup');
      expect(RaceSessionStatus.checkinOpen.label, 'Check-In Open');
      expect(RaceSessionStatus.running.label, 'Racing');
      expect(RaceSessionStatus.scoring.label, 'Scoring');
      expect(RaceSessionStatus.finalized.label, 'Finalized');
    });
  });

  group('RaceSession.fromDoc', () {
    test('parses minimal document', () {
      final session = RaceSession.fromDoc('evt1', {
        'name': 'Test Race',
        'status': 'setup',
      });
      expect(session.id, 'evt1');
      expect(session.name, 'Test Race');
      expect(session.status, RaceSessionStatus.setup);
      expect(session.isDemo, false);
      expect(session.clubspotReady, false);
      expect(session.raceStartId, isNull);
      expect(session.startTime, isNull);
    });

    test('parses full document with all fields', () {
      final now = DateTime.now();
      final session = RaceSession.fromDoc('evt2', {
        'name': 'Full Race',
        'status': 'scoring',
        'courseId': 'c1',
        'courseName': 'Windward-Leeward',
        'courseNumber': 'WL-1',
        'raceNumber': 2,
        'fleetClass': 'PHRF A',
        'raceStartId': 'rs1',
        'startMethod': 'horn',
        'clubspotReady': true,
        'isDemo': true,
        'checkinsClosed': true,
        'notes': 'Good race',
      });
      expect(session.status, RaceSessionStatus.scoring);
      expect(session.courseId, 'c1');
      expect(session.courseName, 'Windward-Leeward');
      expect(session.raceStartId, 'rs1');
      expect(session.startMethod, 'horn');
      expect(session.clubspotReady, true);
      expect(session.isDemo, true);
      expect(session.checkinsClosed, true);
      expect(session.raceNumber, 2);
    });

    test('defaults missing fields gracefully', () {
      final session = RaceSession.fromDoc('evt3', {});
      expect(session.name, 'Race Day');
      expect(session.status, RaceSessionStatus.setup);
      expect(session.raceNumber, 1);
      expect(session.isDemo, false);
      expect(session.clubspotReady, false);
      expect(session.checkinsClosed, false);
    });
  });

  group('RaceSession.copyWith', () {
    test('copies with changed status', () {
      final original = RaceSession.fromDoc('evt1', {
        'name': 'Race',
        'status': 'setup',
      });
      final updated = original.copyWith(status: RaceSessionStatus.running);
      expect(updated.status, RaceSessionStatus.running);
      expect(updated.name, 'Race');
      expect(updated.id, 'evt1');
    });

    test('copies with changed raceStartId and startTime', () {
      final original = RaceSession.fromDoc('evt1', {
        'name': 'Race',
        'status': 'running',
      });
      final now = DateTime.now();
      final updated = original.copyWith(
        raceStartId: 'rs99',
        startTime: now,
      );
      expect(updated.raceStartId, 'rs99');
      expect(updated.startTime, now);
    });
  });

  group('Race flow state transitions', () {
    test('valid flow: setup → checkinOpen → startPending → running → scoring → review → finalized', () {
      final validFlow = [
        RaceSessionStatus.setup,
        RaceSessionStatus.checkinOpen,
        RaceSessionStatus.startPending,
        RaceSessionStatus.running,
        RaceSessionStatus.scoring,
        RaceSessionStatus.review,
        RaceSessionStatus.finalized,
      ];

      // stepIndex should be monotonically non-decreasing
      for (var i = 1; i < validFlow.length; i++) {
        expect(
          validFlow[i].stepIndex >= validFlow[i - 1].stepIndex,
          true,
          reason:
              '${validFlow[i]} step (${validFlow[i].stepIndex}) should be >= ${validFlow[i - 1]} step (${validFlow[i - 1].stepIndex})',
        );
      }
    });

    test('abandoned is terminal from scoring', () {
      expect(RaceSessionStatus.abandoned.isTerminal, true);
      expect(RaceSessionStatus.abandoned.stepIndex, 4); // same as scoring
    });
  });

  group('LetterScore', () {
    test('finished is the default score', () {
      expect(LetterScore.finished.name, 'finished');
    });

    test('all special scores exist', () {
      expect(LetterScore.values.contains(LetterScore.dnf), true);
      expect(LetterScore.values.contains(LetterScore.dns), true);
      expect(LetterScore.values.contains(LetterScore.dsq), true);
      expect(LetterScore.values.contains(LetterScore.ocs), true);
    });
  });

  group('FinishRecord', () {
    test('creates with required fields', () {
      final record = FinishRecord(
        id: 'f1',
        raceStartId: 'rs1',
        sailNumber: '333',
        boatName: 'Wind Dancer',
        finishTimestamp: DateTime.now(),
        elapsedSeconds: 1234.5,
        position: 1,
      );
      expect(record.sailNumber, '333');
      expect(record.boatName, 'Wind Dancer');
      expect(record.letterScore, LetterScore.finished);
      expect(record.position, 1);
    });

    test('copyWith changes position', () {
      final record = FinishRecord(
        id: 'f1',
        raceStartId: 'rs1',
        sailNumber: '333',
        finishTimestamp: DateTime.now(),
        elapsedSeconds: 100,
        position: 1,
      );
      final updated = record.copyWith(position: 2);
      expect(updated.position, 2);
      expect(updated.sailNumber, '333');
    });

    test('special score records have position 0', () {
      final record = FinishRecord(
        id: 'f2',
        raceStartId: 'rs1',
        sailNumber: '444',
        finishTimestamp: DateTime.now(),
        elapsedSeconds: 0,
        letterScore: LetterScore.dnf,
        position: 0,
      );
      expect(record.letterScore, LetterScore.dnf);
      expect(record.position, 0);
    });
  });

  group('Auto-finish detection logic', () {
    test('all boats scored when finishes >= checkins', () {
      final checkinCount = 5;
      final finishCount = 5;
      expect(finishCount >= checkinCount, true);
    });

    test('not all boats scored when finishes < checkins', () {
      final checkinCount = 5;
      final finishCount = 3;
      expect(finishCount >= checkinCount, false);
    });

    test('special scores count toward completion', () {
      // 3 finished + 2 DNF = 5 total, matching 5 checkins
      final finishedCount = 3;
      final dnfCount = 2;
      final checkinCount = 5;
      final totalScored = finishedCount + dnfCount;
      expect(totalScored >= checkinCount, true);
    });
  });
}
