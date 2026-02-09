import 'dart:async';

import 'package:flutter/material.dart';

/// Session timeout wrapper for web admin.
/// Shows a warning dialog before auto-logout after inactivity.
class SessionTimeout extends StatefulWidget {
  const SessionTimeout({
    super.key,
    required this.child,
    this.timeoutDuration = const Duration(minutes: 30),
    this.warningDuration = const Duration(minutes: 2),
    required this.onTimeout,
  });

  final Widget child;
  final Duration timeoutDuration;
  final Duration warningDuration;
  final VoidCallback onTimeout;

  @override
  State<SessionTimeout> createState() => _SessionTimeoutState();
}

class _SessionTimeoutState extends State<SessionTimeout> {
  Timer? _inactivityTimer;
  Timer? _warningTimer;
  bool _showingWarning = false;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    _showingWarning = false;

    final warningAt =
        widget.timeoutDuration - widget.warningDuration;

    _warningTimer = Timer(warningAt, _showWarning);
    _inactivityTimer = Timer(widget.timeoutDuration, _handleTimeout);
  }

  void _showWarning() {
    if (!mounted || _showingWarning) return;
    _showingWarning = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session Expiring'),
        content: Text(
          'Your session will expire in ${widget.warningDuration.inMinutes} minutes due to inactivity.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
            },
            child: const Text('Stay Signed In'),
          ),
        ],
      ),
    );
  }

  void _handleTimeout() {
    if (!mounted) return;
    // Dismiss warning dialog if showing
    if (_showingWarning) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    widget.onTimeout();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
