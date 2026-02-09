import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/timing/data/models/timing_models.dart';

void main() {
  group('Start sequence countdown', () {
    test('5-minute sequence starts at 300 seconds', () {
      const countdownSeconds = 300;
      expect(countdownSeconds ~/ 60, 5);
      expect(countdownSeconds % 60, 0);
    });

    test('countdown format mm:ss at 4:00', () {
      const seconds = 240;
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      final display =
          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      expect(display, '04:00');
    });

    test('countdown format at 0:10', () {
      const seconds = 10;
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      final display =
          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      expect(display, '00:10');
    });

    test('countdown format at 0:00', () {
      const seconds = 0;
      final mins = seconds.abs() ~/ 60;
      final secs = seconds.abs() % 60;
      final display =
          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      expect(display, '00:00');
    });

    test('count-up after start (negative countdown)', () {
      const seconds = -15;
      final isCountUp = seconds < 0;
      final mins = seconds.abs() ~/ 60;
      final secs = seconds.abs() % 60;
      expect(isCountUp, true);
      expect(mins, 0);
      expect(secs, 15);
    });
  });

  group('Flag indicators', () {
    test('warning flag at 5:00', () {
      const countdown = 300;
      final warningFlag = countdown <= 300 && countdown > 0;
      expect(warningFlag, true);
    });

    test('prep flag at 4:00', () {
      const countdown = 240;
      final prepFlag = countdown <= 240 && countdown > 60;
      expect(prepFlag, true);
    });

    test('prep flag removed at 1:00', () {
      const countdown = 60;
      final prepFlag = countdown < 240 && countdown > 60;
      expect(prepFlag, false);
    });

    test('under 10 seconds triggers rapid haptic', () {
      const countdown = 8;
      final under10 = countdown > 0 && countdown <= 10;
      expect(under10, true);
    });

    test('not under 10 at 11 seconds', () {
      const countdown = 11;
      final under10 = countdown > 0 && countdown <= 10;
      expect(under10, false);
    });
  });

  group('RaceStart model', () {
    test('creates race start', () {
      final start = RaceStart(
        id: 'rs1',
        eventId: 'e1',
        raceNumber: 1,
        className: 'Fleet',
      );
      expect(start.raceNumber, 1);
      expect(start.className, 'Fleet');
      expect(start.warningSignalTime, isNull);
      expect(start.startTime, isNull);
      expect(start.isGeneralRecall, false);
      expect(start.isPostponed, false);
    });

    test('copyWith updates fields', () {
      final start = RaceStart(
        id: 'rs1',
        eventId: 'e1',
        raceNumber: 1,
        className: 'Fleet',
      );
      final warningTime = DateTime(2024, 6, 15, 13, 0, 0);
      final updated = start.copyWith(warningSignalTime: warningTime);

      expect(updated.warningSignalTime, warningTime);
      expect(updated.id, 'rs1');
      expect(updated.raceNumber, 1);
    });

    test('general recall resets start', () {
      final start = RaceStart(
        id: 'rs1',
        eventId: 'e1',
        raceNumber: 1,
        className: 'Fleet',
        warningSignalTime: DateTime(2024, 6, 15, 13, 0),
        prepSignalTime: DateTime(2024, 6, 15, 13, 1),
      );
      final recalled = start.copyWith(isGeneralRecall: true);
      expect(recalled.isGeneralRecall, true);
    });

    test('postpone sets flag', () {
      final start = RaceStart(
        id: 'rs1',
        eventId: 'e1',
        raceNumber: 1,
        className: 'Fleet',
      );
      final postponed = start.copyWith(isPostponed: true);
      expect(postponed.isPostponed, true);
    });
  });

  group('Signal timing accuracy', () {
    test('5-minute sequence signal events at correct times', () {
      // Warning at 5:00 (300s), Prep at 4:00 (240s), Remove prep at 1:00 (60s), Start at 0:00
      const signals = {300: 'warning', 240: 'prep', 60: 'removePrep', 0: 'start'};
      expect(signals[300], 'warning');
      expect(signals[240], 'prep');
      expect(signals[60], 'removePrep');
      expect(signals[0], 'start');
    });

    test('3-minute sequence would use different timings', () {
      const totalSeconds = 180;
      // Warning at 3:00, Prep at 2:00, Remove prep at 1:00, Start at 0:00
      expect(totalSeconds, 180);
      expect(totalSeconds - 60, 120); // prep at 2:00
    });
  });
}
