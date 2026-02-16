import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/core/retry.dart';

void main() {
  group('retryWithBackoff', () {
    test('succeeds on first attempt', () async {
      var attempts = 0;
      final result = await retryWithBackoff(() async {
        attempts++;
        return 42;
      });
      expect(result, 42);
      expect(attempts, 1);
    });

    test('retries on failure and succeeds', () async {
      var attempts = 0;
      final result = await retryWithBackoff(() async {
        attempts++;
        if (attempts < 3) throw Exception('fail');
        return 'ok';
      });
      expect(result, 'ok');
    });

    test('throws after max attempts exhausted', () async {
      expect(
        () => retryWithBackoff(
          () async {
            throw Exception('always fails');
          },
          maxAttempts: 2,
          initialDelay: const Duration(milliseconds: 10),
        ),
        throwsException,
      );
    });

    test('respects retryIf predicate — retries matching errors', () async {
      var attempts = 0;
      final result = await retryWithBackoff(
        () async {
          attempts++;
          if (attempts < 2) throw StateError('retryable');
          return 'done';
        },
        retryIf: (e) => e is StateError,
        initialDelay: const Duration(milliseconds: 10),
      );
      expect(result, 'done');
      expect(attempts, 2);
    });

    test('does not retry when retryIf returns false', () async {
      expect(
        () => retryWithBackoff(
          () async {
            throw ArgumentError('not retryable');
          },
          retryIf: (e) => e is StateError,
          initialDelay: const Duration(milliseconds: 10),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws TimeoutException when action exceeds timeout', () async {
      expect(
        () => retryWithBackoff(
          () async {
            await Future.delayed(const Duration(milliseconds: 500));
            return 'late';
          },
          maxAttempts: 1,
          timeout: const Duration(milliseconds: 100),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('custom timeout is respected', () async {
      var attempts = 0;
      // Action takes 50ms, timeout is 200ms — should succeed
      final result = await retryWithBackoff(
        () async {
          attempts++;
          await Future.delayed(const Duration(milliseconds: 50));
          return 'ok';
        },
        timeout: const Duration(milliseconds: 200),
      );
      expect(result, 'ok');
      expect(attempts, 1);
    });

    test('exponential backoff increases delay', () async {
      final timestamps = <DateTime>[];
      var attempts = 0;
      try {
        await retryWithBackoff(
          () async {
            timestamps.add(DateTime.now());
            attempts++;
            throw Exception('fail');
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 100),
        );
      } catch (_) {}

      expect(attempts, 3);
      if (timestamps.length >= 3) {
        final gap1 = timestamps[1].difference(timestamps[0]).inMilliseconds;
        final gap2 = timestamps[2].difference(timestamps[1]).inMilliseconds;
        
        // Gap1 should be around 100ms. Expect >= 50ms.
        expect(gap1, greaterThanOrEqualTo(50), reason: 'Gap1 too small: $gap1');
        
        // Gap2 should be around 200ms. Expect >= 100ms.
        expect(gap2, greaterThanOrEqualTo(100), reason: 'Gap2 too small: $gap2');
        
        // Ensure gap2 is larger than gap1 (exponential)
        // Relaxed check: gap2 should be at least gap1
        expect(gap2, greaterThanOrEqualTo(gap1), reason: 'Gap2 ($gap2) not >= Gap1 ($gap1)');
      }
    });
  });

  group('retryUpload', () {
    test('succeeds on first attempt', () async {
      final result = await retryUpload(() async => 'uploaded');
      expect(result, 'uploaded');
    });

    test('retries on failure', () async {
      var attempts = 0;
      final result = await retryUpload(() async {
        attempts++;
        if (attempts < 2) throw Exception('network error');
        return 'uploaded';
      });
      expect(result, 'uploaded');
      expect(attempts, 2);
    });
  });
}
