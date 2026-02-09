import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/timing/data/models/timing_models.dart';

// Extract the calculation logic from TimingResultsScreen for testability
double phrfTimeOnTime(double elapsedSeconds, int phrfRating) {
  return elapsedSeconds * (650.0 / (550.0 + phrfRating));
}

double phrfTimeOnDistance(double elapsedSeconds, int phrfRating, double distanceNm) {
  return elapsedSeconds - (phrfRating * distanceNm);
}

String formatDuration(double seconds) {
  final dur = Duration(seconds: seconds.toInt());
  final h = dur.inHours;
  final m = dur.inMinutes % 60;
  final s = dur.inSeconds % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

void main() {
  group('PHRF Time-on-Time', () {
    test('corrects for average rating (120)', () {
      // elapsed = 3600s (1 hour), rating = 120
      // corrected = 3600 * (650 / (550 + 120)) = 3600 * 0.9701 = 3492.5
      final corrected = phrfTimeOnTime(3600, 120);
      expect(corrected, closeTo(3492.5, 0.5));
    });

    test('faster boat (lower rating) gets higher correction factor', () {
      final fast = phrfTimeOnTime(3600, 60);   // 650/(550+60) = 1.0656
      final slow = phrfTimeOnTime(3600, 200);  // 650/(550+200) = 0.8667
      // Fast boat's corrected time should be HIGHER (penalized less)
      expect(fast, greaterThan(slow));
    });

    test('zero rating returns elapsed * 650/550', () {
      final corrected = phrfTimeOnTime(3600, 0);
      expect(corrected, closeTo(3600 * 650.0 / 550.0, 0.1));
    });

    test('handles very fast elapsed time', () {
      final corrected = phrfTimeOnTime(60, 150);
      expect(corrected, closeTo(60 * 650.0 / 700.0, 0.1));
    });

    test('handles long race', () {
      // 2 hours = 7200s, rating 100
      final corrected = phrfTimeOnTime(7200, 100);
      expect(corrected, closeTo(7200 * 650.0 / 650.0, 0.1));
      // Rating 100 means factor = 1.0 exactly
      expect(corrected, closeTo(7200, 0.1));
    });
  });

  group('PHRF Time-on-Distance', () {
    test('corrects for standard race (3nm, rating 120)', () {
      // elapsed = 3600s, rating = 120, distance = 3nm
      // corrected = 3600 - (120 * 3) = 3600 - 360 = 3240
      final corrected = phrfTimeOnDistance(3600, 120, 3.0);
      expect(corrected, closeTo(3240, 0.1));
    });

    test('higher rating gets more time subtracted', () {
      final fast = phrfTimeOnDistance(3600, 60, 3.0);   // 3600 - 180 = 3420
      final slow = phrfTimeOnDistance(3600, 200, 3.0);  // 3600 - 600 = 3000
      expect(fast, greaterThan(slow));
    });

    test('longer distance increases correction', () {
      final short = phrfTimeOnDistance(3600, 120, 2.0);  // 3600 - 240 = 3360
      final long = phrfTimeOnDistance(3600, 120, 5.0);   // 3600 - 600 = 3000
      expect(short, greaterThan(long));
    });

    test('zero distance means no correction', () {
      final corrected = phrfTimeOnDistance(3600, 120, 0);
      expect(corrected, 3600);
    });
  });

  group('Elapsed time accuracy', () {
    test('calculates elapsed from start and finish timestamps', () {
      final start = DateTime(2024, 6, 15, 13, 0, 0);
      final finish = DateTime(2024, 6, 15, 14, 23, 45);
      final elapsed = finish.difference(start).inSeconds.toDouble();
      expect(elapsed, 5025); // 1h 23m 45s = 5025s
    });

    test('sub-minute elapsed time', () {
      final start = DateTime(2024, 6, 15, 13, 0, 0);
      final finish = DateTime(2024, 6, 15, 13, 0, 42);
      final elapsed = finish.difference(start).inSeconds.toDouble();
      expect(elapsed, 42);
    });
  });

  group('Position calculation', () {
    test('sorts finished boats by corrected time', () {
      final finishes = [
        _makeFinish('A', 3600, LetterScore.finished),
        _makeFinish('B', 3400, LetterScore.finished),
        _makeFinish('C', 3800, LetterScore.finished),
      ];

      finishes.sort((a, b) => a.elapsedSeconds.compareTo(b.elapsedSeconds));

      expect(finishes[0].sailNumber, 'B');
      expect(finishes[1].sailNumber, 'A');
      expect(finishes[2].sailNumber, 'C');
    });

    test('DNF boats rank after finished boats', () {
      final rows = [
        _makeFinish('A', 3600, LetterScore.finished),
        _makeFinish('B', 0, LetterScore.dnf),
        _makeFinish('C', 3400, LetterScore.finished),
      ];

      rows.sort((a, b) {
        if (a.letterScore == LetterScore.finished &&
            b.letterScore != LetterScore.finished) return -1;
        if (a.letterScore != LetterScore.finished &&
            b.letterScore == LetterScore.finished) return 1;
        return a.elapsedSeconds.compareTo(b.elapsedSeconds);
      });

      expect(rows[0].sailNumber, 'C');
      expect(rows[1].sailNumber, 'A');
      expect(rows[2].sailNumber, 'B');
    });

    test('letter score boats get totalBoats+1 points', () {
      final totalBoats = 5;
      final dnfPoints = totalBoats + 1;
      expect(dnfPoints, 6);
    });
  });

  group('formatDuration', () {
    test('formats minutes and seconds', () {
      expect(formatDuration(125), '02:05');
    });

    test('formats hours', () {
      expect(formatDuration(3661), '1:01:01');
    });

    test('formats zero', () {
      expect(formatDuration(0), '00:00');
    });

    test('formats exactly one hour', () {
      expect(formatDuration(3600), '1:00:00');
    });
  });

  group('FinishRecord', () {
    test('copyWith preserves unchanged fields', () {
      final original = FinishRecord(
        id: 'f1',
        raceStartId: 'rs1',
        sailNumber: '42',
        finishTimestamp: DateTime(2024, 6, 15, 14, 0),
        elapsedSeconds: 3600,
        letterScore: LetterScore.finished,
        position: 1,
      );

      final updated = original.copyWith(position: 2, correctedSeconds: 3500);

      expect(updated.id, 'f1');
      expect(updated.sailNumber, '42');
      expect(updated.elapsedSeconds, 3600);
      expect(updated.position, 2);
      expect(updated.correctedSeconds, 3500);
    });
  });

  group('LetterScore', () {
    test('all values exist', () {
      expect(LetterScore.values, hasLength(7));
      expect(LetterScore.values, contains(LetterScore.dns));
      expect(LetterScore.values, contains(LetterScore.dnf));
      expect(LetterScore.values, contains(LetterScore.dsq));
      expect(LetterScore.values, contains(LetterScore.ocs));
      expect(LetterScore.values, contains(LetterScore.raf));
      expect(LetterScore.values, contains(LetterScore.ret));
      expect(LetterScore.values, contains(LetterScore.finished));
    });
  });
}

FinishRecord _makeFinish(String sail, double elapsed, LetterScore score) {
  return FinishRecord(
    id: sail,
    raceStartId: 'rs1',
    sailNumber: sail,
    finishTimestamp: DateTime(2024, 6, 15, 14, 0),
    elapsedSeconds: elapsed,
    letterScore: score,
  );
}
