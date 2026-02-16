import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/data/auth_providers.dart';

class CrewDashboardScreen extends ConsumerStatefulWidget {
  const CrewDashboardScreen({super.key});

  @override
  ConsumerState<CrewDashboardScreen> createState() =>
      _CrewDashboardScreenState();
}

class _CrewDashboardScreenState extends ConsumerState<CrewDashboardScreen> {
  String? _assignedRole;
  String? _boatName;
  String? _skipperName;
  bool _signedOff = false;

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  Future<void> _loadAssignment() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('crew_assignments')
          .where('crewUid', isEqualTo: uid)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(DateTime.now().year, DateTime.now().month,
                      DateTime.now().day)))
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        final d = snap.docs.first.data();
        setState(() {
          _assignedRole = d['role'] as String? ?? 'Crew';
          _boatName = d['boatName'] as String?;
          _skipperName = d['skipperName'] as String?;
        });
      }
    } catch (_) {}
  }

  Future<void> _postRaceSignOff() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Post-Race Sign Off'),
        content: const Text(
          'Confirm you are safely off the vessel and done for the day.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign Off'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('crew_signoffs').add({
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
      if (mounted) {
        setState(() => _signedOff = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed off for the day')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(currentUserProvider);
    final member = memberAsync.value;

    return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Your assignment
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment_ind,
                          color: Colors.orange.shade800, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _assignedRole ?? 'No role assigned',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            if (_boatName != null)
                              Text('on $_boatName',
                                  style: const TextStyle(fontSize: 14)),
                            if (_skipperName != null)
                              Text('Skipper: $_skipperName',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Race timer (synced)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('race_state')
                    .doc('current')
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || !snap.data!.exists) {
                    return Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('No active race',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    );
                  }
                  final d = snap.data!.data() as Map<String, dynamic>? ?? {};
                  final startTs = d['raceStartTime'] as Timestamp?;
                  final leg = d['currentLeg'] as String? ?? '';
                  if (startTs == null) {
                    return Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Race starting soon...',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
                      ],
                    );
                  }
                  return _SyncedTimer(
                      startTime: startTs.toDate(), currentLeg: leg);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Your boat info
          if (member != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.sailing, color: Colors.indigo),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.boatName ?? 'No boat assigned',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          if (member.sailNumber != null)
                            Text('Sail #${member.sailNumber}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Post-race sign off
          if (!_signedOff)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _postRaceSignOff,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Post-Race Sign Off'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('Signed off for the day',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  ],
                ),
              ),
            ),
        ],
    );
  }
}

class _SyncedTimer extends StatefulWidget {
  const _SyncedTimer({required this.startTime, required this.currentLeg});
  final DateTime startTime;
  final String currentLeg;

  @override
  State<_SyncedTimer> createState() => _SyncedTimerState();
}

class _SyncedTimerState extends State<_SyncedTimer> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60);
    final s = _elapsed.inSeconds.remainder(60);
    final timeStr = h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '$m:${s.toString().padLeft(2, '0')}';

    return Row(
      children: [
        const Icon(Icons.timer, color: Colors.green),
        const SizedBox(width: 8),
        Text(timeStr,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
        const Spacer(),
        if (widget.currentLeg.isNotEmpty)
          Chip(label: Text(widget.currentLeg)),
      ],
    );
  }
}
