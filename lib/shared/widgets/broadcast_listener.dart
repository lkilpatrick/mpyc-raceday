import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/app_mode/data/app_mode.dart';
import '../../features/courses/data/models/fleet_broadcast.dart';

/// Wraps the app to listen for fleet broadcasts and show popup modals.
///
/// Filters broadcasts by [BroadcastTarget] based on the current app mode:
/// - everyone → all modes
/// - skippersOnly → skipper mode only
/// - onshore → onshore + crew modes
class BroadcastListener extends ConsumerStatefulWidget {
  const BroadcastListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BroadcastListener> createState() => _BroadcastListenerState();
}

class _BroadcastListenerState extends ConsumerState<BroadcastListener> {
  StreamSubscription<QuerySnapshot>? _sub;
  final Set<String> _shownIds = {};
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _startListening() {
    // Listen to broadcasts created in the last 30 seconds (avoid replaying old ones)
    final cutoff = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(seconds: 30)));

    _sub = FirebaseFirestore.instance
        .collection('fleet_broadcasts')
        .where('sentAt', isGreaterThan: cutoff)
        .orderBy('sentAt', descending: true)
        .limit(5)
        .snapshots()
        .listen(_onSnapshot);
  }

  void _onSnapshot(QuerySnapshot snap) {
    final mode = currentAppMode();

    for (final change in snap.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      final doc = change.doc;
      final id = doc.id;
      if (_shownIds.contains(id)) continue;
      _shownIds.add(id);

      final d = doc.data() as Map<String, dynamic>? ?? {};
      final targetStr = d['target'] as String? ?? 'everyone';
      final target = BroadcastTarget.values.firstWhere(
        (t) => t.name == targetStr,
        orElse: () => BroadcastTarget.everyone,
      );

      // Filter by target
      if (!_shouldShow(target, mode)) continue;

      final message = d['message'] as String? ?? '';
      final typeStr = d['type'] as String? ?? 'general';
      final requiresAck = d['requiresAck'] as bool? ?? false;

      _showBroadcastModal(
        broadcastId: id,
        message: message,
        typeStr: typeStr,
        requiresAck: requiresAck,
      );
    }
  }

  bool _shouldShow(BroadcastTarget target, AppMode mode) {
    return switch (target) {
      BroadcastTarget.everyone => true,
      BroadcastTarget.skippersOnly => mode == AppMode.skipper,
      BroadcastTarget.onshore =>
        mode == AppMode.onshore || mode == AppMode.crew,
    };
  }

  Future<void> _showBroadcastModal({
    required String broadcastId,
    required String message,
    required String typeStr,
    required bool requiresAck,
  }) async {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;

    final typeLabel = _friendlyType(typeStr);
    final color = _typeColor(typeStr);

    await showDialog<void>(
      context: context,
      barrierDismissible: !requiresAck,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.campaign, color: color, size: 36),
        title: Text(typeLabel,
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          if (requiresAck)
            FilledButton(
              onPressed: () {
                _acknowledge(broadcastId);
                Navigator.pop(dialogContext);
              },
              child: const Text('ACKNOWLEDGE'),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
        ],
      ),
    );

    _dialogOpen = false;
  }

  Future<void> _acknowledge(String broadcastId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Record ack
    await FirebaseFirestore.instance
        .collection('fleet_broadcasts')
        .doc(broadcastId)
        .collection('acks')
        .doc(uid)
        .set({
      'ackedAt': FieldValue.serverTimestamp(),
      'uid': uid,
    });

    // Increment ack count
    await FirebaseFirestore.instance
        .collection('fleet_broadcasts')
        .doc(broadcastId)
        .update({'ackCount': FieldValue.increment(1)});
  }

  static String _friendlyType(String type) {
    return switch (type) {
      'courseSelection' => 'Course Selection',
      'postponement' => 'Race Postponed',
      'abandonment' => 'Race Abandoned',
      'courseChange' => 'Course Change',
      'generalRecall' => 'General Recall',
      'shortenedCourse' => 'Shortened Course',
      'shortenCourse' => 'Shortened Course',
      'cancellation' => 'Race Cancelled',
      'vhfChannelChange' => 'VHF Channel Change',
      'abandonTooMuchWind' => 'Abandoned — Too Much Wind',
      'abandonTooLittleWind' => 'Abandoned — Too Little Wind',
      _ => 'Fleet Broadcast',
    };
  }

  static Color _typeColor(String type) {
    return switch (type) {
      'postponement' => Colors.orange,
      'abandonment' || 'abandonTooMuchWind' || 'cancellation' => Colors.red,
      'abandonTooLittleWind' => Colors.amber.shade800,
      'generalRecall' => Colors.purple,
      'shortenedCourse' || 'shortenCourse' => Colors.teal,
      'vhfChannelChange' => Colors.indigo,
      'courseSelection' || 'courseChange' => Colors.blue,
      _ => Colors.grey.shade700,
    };
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
