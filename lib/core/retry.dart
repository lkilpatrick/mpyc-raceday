import 'dart:async';
import 'dart:math';

/// Retry a future with exponential backoff.
/// [maxAttempts] defaults to 3, [initialDelay] defaults to 1 second.
Future<T> retryWithBackoff<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  Duration maxDelay = const Duration(seconds: 30),
  Duration timeout = const Duration(seconds: 10),
  bool Function(Object error)? retryIf,
}) async {
  var attempt = 0;
  Object? lastError;

  while (attempt < maxAttempts) {
    attempt++;
    try {
      return await action().timeout(timeout);
    } catch (error) {
      lastError = error;
      if (retryIf != null && !retryIf(error)) rethrow;
      if (attempt >= maxAttempts) rethrow;

      final delay = Duration(
        milliseconds: min(
          initialDelay.inMilliseconds * pow(2, attempt - 1).toInt(),
          maxDelay.inMilliseconds,
        ),
      );
      await Future<void>.delayed(delay);
    }
  }

  throw lastError ?? StateError('Retry exhausted with no error');
}

/// Retry for file uploads with a longer timeout.
Future<T> retryUpload<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
}) {
  return retryWithBackoff(
    action,
    maxAttempts: maxAttempts,
    initialDelay: const Duration(seconds: 2),
    timeout: const Duration(seconds: 30),
  );
}
