import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/weather_header.dart';

/// Skipper Race tab — embedded in MobileShell (no Scaffold).
/// Shows weather header, race status with timer, and contextual actions.
class SkipperRaceTab extends ConsumerWidget {
  const SkipperRaceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Column(
      children: [
        const WeatherHeader(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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
                return _noRace(context);
              }

              final doc = docs.first;
              final d = doc.data() as Map<String, dynamic>;
              final eventId = doc.id;
              final name = d['name'] as String? ?? 'Race Day';
              final status = d['status'] as String? ?? 'setup';
              final startTime = (d['startTime'] as Timestamp?)?.toDate();
              final courseName = d['courseName'] as String?;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('boat_checkins')
                    .where('eventId', isEqualTo: eventId)
                    .where('memberId', isEqualTo: uid)
                    .limit(1)
                    .snapshots(),
                builder: (context, checkinSnap) {
                  final isCheckedIn =
                      (checkinSnap.data?.docs ?? []).isNotEmpty;
                  final checkinData = isCheckedIn
                      ? checkinSnap.data!.docs.first.data()
                          as Map<String, dynamic>
                      : null;
                  final boatStatus =
                      checkinData?['status'] as String? ?? 'checked_in';

                  return _raceContent(
                    context: context,
                    eventId: eventId,
                    name: name,
                    status: status,
                    startTime: startTime,
                    courseName: courseName,
                    isCheckedIn: isCheckedIn,
                    boatStatus: boatStatus,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _noRace(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sailing, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No race today',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 4),
          Text('Check back on race day',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/skipper-results'),
            icon: const Icon(Icons.leaderboard),
            label: const Text('View Past Results'),
          ),
        ],
      ),
    );
  }

  Widget _raceContent({
    required BuildContext context,
    required String eventId,
    required String name,
    required String status,
    required DateTime? startTime,
    required String? courseName,
    required bool isCheckedIn,
    required String boatStatus,
  }) {
    final isActive = ['running', 'scoring'].contains(status);
    final isPreStart =
        ['setup', 'checkin_open', 'start_pending'].contains(status);
    final isFinished = ['review', 'finalized'].contains(status);
    final isAbandoned = status == 'abandoned';
    final hasFinishedRace =
        boatStatus == 'finished' || boatStatus == 'dnf';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Race name + course
          Text(name,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          if (courseName != null)
            Text('Course: $courseName',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 16),

          // Timer section
          if (isActive && startTime != null) ...[
            _LiveTimer(startTime: startTime),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

          if (isPreStart) ...[
            const Text('00:00',
                style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                  Text(
                    status == 'checkin_open'
                        ? 'Check-In Open'
                        : status == 'start_pending'
                            ? 'Start Pending'
                            : 'Setting Up',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ],

          if (isAbandoned) ...[
            Icon(Icons.cancel, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 8),
            const Text('Race Abandoned',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
          ],

          if (isFinished) ...[
            Icon(Icons.check_circle,
                size: 56, color: Colors.green.shade300),
            const SizedBox(height: 8),
            const Text('Race Complete',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
          ],

          // Check-in status
          if (isCheckedIn && !hasFinishedRace) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gps_fixed, size: 14, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text('Checked in — GPS transmitting',
                    style: TextStyle(
                        fontSize: 12, color: Colors.green.shade700)),
              ],
            ),
          ],

          if (hasFinishedRace) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  boatStatus == 'dnf' ? Icons.cancel : Icons.flag,
                  size: 14,
                  color: boatStatus == 'dnf' ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  boatStatus == 'dnf' ? 'Did Not Finish' : 'Finished',
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          boatStatus == 'dnf' ? Colors.red : Colors.blue),
                ),
              ],
            ),
          ],

          const Spacer(),

          // Action buttons
          if (!isCheckedIn && !isFinished && !isAbandoned)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () =>
                    context.push('/skipper-checkin/$eventId'),
                icon: const Icon(Icons.how_to_reg, size: 24),
                label: const Text('Check In',
                    style: TextStyle(fontSize: 18)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

          if (isCheckedIn && isActive && !hasFinishedRace)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () =>
                    context.push('/skipper-race/$eventId'),
                icon: const Icon(Icons.sailing, size: 24),
                label: const Text('Open Race Mode',
                    style: TextStyle(fontSize: 18)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

          if (isFinished || hasFinishedRace) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/skipper-results'),
                icon: const Icon(Icons.leaderboard),
                label: const Text('View Results'),
              ),
            ),
          ],

          // Quick actions row
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/skipper-incident'),
                  icon: const Icon(Icons.warning_amber, size: 18),
                  label: const Text('Protest'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/rules/reference'),
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: const Text('Rules'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: const BorderSide(color: Colors.indigo),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LiveTimer extends StatefulWidget {
  const _LiveTimer({required this.startTime});
  final DateTime startTime;

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

    return Text(
      timeStr,
      style: const TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
        letterSpacing: 2,
      ),
    );
  }
}
