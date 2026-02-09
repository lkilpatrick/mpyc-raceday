import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralized haptic feedback utilities for mobile.
class AppHaptics {
  const AppHaptics._();

  /// Light tap — button presses, check-offs.
  static void tap() {
    if (!kIsWeb) HapticFeedback.lightImpact();
  }

  /// Medium impact — timer minute marks, important actions.
  static void medium() {
    if (!kIsWeb) HapticFeedback.mediumImpact();
  }

  /// Heavy impact — timer signals, start/finish, critical alerts.
  static void heavy() {
    if (!kIsWeb) HapticFeedback.heavyImpact();
  }

  /// Selection click — toggle switches, chip selection.
  static void selection() {
    if (!kIsWeb) HapticFeedback.selectionClick();
  }

  /// Vibrate pattern — general recall, emergency.
  static void vibrate() {
    if (!kIsWeb) HapticFeedback.vibrate();
  }
}
