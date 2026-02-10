import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global error handler that logs to console (and Crashlytics when available).
class ErrorHandler {
  const ErrorHandler._();

  static void init() {
    // Flutter framework errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack);
    };

    // Async errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack);
      return true;
    };
  }

  static void _logError(Object error, StackTrace? stack) {
    debugPrint('╔══ ERROR ══════════════════════════════');
    debugPrint('║ $error');
    if (stack != null) {
      debugPrint('║ ${stack.toString().split('\n').take(5).join('\n║ ')}');
    }
    debugPrint('╚═══════════════════════════════════════');
    // TODO: FirebaseCrashlytics.instance.recordError(error, stack);
  }

  /// Show a user-friendly snackbar for transient errors.
  static void showTransient(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
      ),
    );
  }

  /// Show a blocking dialog for critical errors.
  static Future<void> showBlocking(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
