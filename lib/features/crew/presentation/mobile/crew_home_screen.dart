import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../skipper/presentation/widgets/weather_header.dart';

/// Crew Home — ultra-minimal: weather header, huge race timer,
/// Report Incident + Rules buttons. Nothing else.
class CrewHomeScreen extends ConsumerWidget {
  const CrewHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const WeatherHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // Crew profile badge
                const _CrewBadge(),
                const SizedBox(height: 8),

                // Race timer — dominant element
                const Expanded(child: _RaceTimerSection()),

                // Two action buttons only
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/crew-incident'),
                    icon: const Icon(Icons.warning_amber, size: 26),
                    label: const Text('Report Incident / Protest',
                        style: TextStyle(fontSize: 17)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/rules/reference'),
                    icon: const Icon(Icons.menu_book, size: 24),
                    label: const Text('Racing Rules',
                        style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      side: const BorderSide(color: Colors.indigo),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Crew badge — shows name, boat, position
// ─────────────────────────────────────────────────────────────────

class _CrewBadge extends StatelessWidget {
  const _CrewBadge();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('crew_profiles')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return Card(
            color: Colors.orange.shade50,
            child: InkWell(
              onTap: () => context.push('/crew-profile'),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Set up your crew profile',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ),
                    Icon(Icons.chevron_right, color: Colors.orange),
                  ],
                ),
              ),
            ),
          );
        }

        final d = snap.data!.data() as Map<String, dynamic>;
        final name = d['displayName'] as String? ?? '';
        final boat = d['boatLabel'] as String? ?? '';
        final position = d['boatPosition'] as String? ?? '';

        return Card(
          child: InkWell(
            onTap: () => context.push('/crew-profile'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        if (boat.isNotEmpty || position.isNotEmpty)
                          Text(
                            [if (position.isNotEmpty) position, if (boat.isNotEmpty) boat]
                                .join(' • '),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Race Timer Section — huge, binds to RC start time
// ─────────────────────────────────────────────────────────────────

class _RaceTimerSection extends StatelessWidget {
  const _RaceTimerSection();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _noRaceState();
        }

        final d = docs.first.data() as Map<String, dynamic>;
        final status = d['status'] as String? ?? 'setup';
        final startTime = (d['startTime'] as Timestamp?)?.toDate();
        final name = d['name'] as String? ?? 'Race Day';

        if (status == 'abandoned') {
          return _abandonedState(name);
        }

        if (['finalized', 'review'].contains(status)) {
          return _finishedState(name);
        }

        if (startTime != null &&
            ['running', 'scoring'].contains(status)) {
          return _activeTimer(startTime, name);
        }

        // Pre-start states
        return _waitingState(name, status);
      },
    );
  }

  Widget _noRaceState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sailing, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No active race',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 4),
          Text('Check back on race day',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _waitingState(String name, String status) {
    final statusLabel = switch (status) {
      'setup' => 'Setting up',
      'checkin_open' => 'Check-in open',
      'start_pending' => 'Start pending',
      _ => status,
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          const Text('00:00',
              style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_empty,
                    size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Text(statusLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeTimer(DateTime startTime, String name) {
    return _LiveTimer(startTime: startTime, name: name);
  }

  Widget _abandonedState(String name) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Icon(Icons.cancel, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 8),
          const Text('Race Abandoned',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red)),
        ],
      ),
    );
  }

  Widget _finishedState(String name) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Icon(Icons.check_circle, size: 64, color: Colors.green.shade300),
          const SizedBox(height: 8),
          const Text('Race Complete',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
        ],
      ),
    );
  }
}

class _LiveTimer extends StatefulWidget {
  const _LiveTimer({required this.startTime, required this.name});
  final DateTime startTime;
  final String name;

  @override
  State<_LiveTimer> createState() => _LiveTimerState();
}

class _LiveTimerState extends State<_LiveTimer> {
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
  void didUpdateWidget(covariant _LiveTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startTime != widget.startTime) {
      _elapsed = DateTime.now().difference(widget.startTime);
    }
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
        ? '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.name,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: Colors.green),
                SizedBox(width: 6),
                Text('RACING',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
