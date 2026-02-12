import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/data/auth_providers.dart';
import '../widgets/weather_header.dart';

/// Skipper Home — weather header + race status card + check-in / race / results.
class SkipperHomeScreen extends ConsumerWidget {
  const SkipperHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentUserProvider);
    final member = memberAsync.value;

    return Column(
      children: [
        const WeatherHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Greeting
              if (member != null) ...[
                Text(
                  'Hello, ${member.firstName}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (member.sailNumber != null &&
                    member.sailNumber!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${member.boatName ?? ''} • Sail ${member.sailNumber}',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 14),
              ],

              // Active race status card
              const _ActiveRaceCard(),
              const SizedBox(height: 12),

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.gavel,
                      label: 'Protest',
                      color: Colors.red,
                      onTap: () => context.push('/skipper-incident'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.leaderboard,
                      label: 'Results',
                      color: Colors.amber.shade700,
                      onTap: () => context.push('/skipper-results'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.menu_book,
                      label: 'Rules',
                      color: Colors.indigo,
                      onTap: () => context.push('/rules/reference'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recent results preview
              const _RecentResultsPreview(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Active Race Card — shows check-in / race / finished state
// ─────────────────────────────────────────────────────────────────

class _ActiveRaceCard extends ConsumerWidget {
  const _ActiveRaceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          return _noRaceCard(context);
        }

        final doc = docs.first;
        final d = doc.data() as Map<String, dynamic>;
        final eventId = doc.id;
        final name = d['name'] as String? ?? 'Race Day';
        final status = d['status'] as String? ?? 'setup';
        final startTime = (d['startTime'] as Timestamp?)?.toDate();
        final courseName = d['courseName'] as String?;

        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

        // Check if this skipper is checked in
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
            final checkinDoc = isCheckedIn
                ? checkinSnap.data!.docs.first
                : null;
            final checkinData = checkinDoc?.data()
                as Map<String, dynamic>?;
            final boatStatus =
                checkinData?['status'] as String? ?? 'checked_in';

            return _buildRaceCard(
              context: context,
              ref: ref,
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
    );
  }

  Widget _buildRaceCard({
    required BuildContext context,
    required WidgetRef ref,
    required String eventId,
    required String name,
    required String status,
    required DateTime? startTime,
    required String? courseName,
    required bool isCheckedIn,
    required String boatStatus,
  }) {
    final isActive = ['running', 'scoring'].contains(status);
    final isCheckInOpen = ['setup', 'checkin_open', 'start_pending']
        .contains(status);
    final isFinished = ['review', 'finalized'].contains(status);

    final (statusLabel, statusColor, statusIcon) = switch (status) {
      'setup' => ('Setting Up', Colors.orange, Icons.settings),
      'checkin_open' => ('Check-In Open', Colors.teal, Icons.how_to_reg),
      'start_pending' => ('Start Pending', Colors.amber, Icons.timer),
      'running' => ('RACING', Colors.green, Icons.sailing),
      'scoring' => ('Scoring', Colors.blue, Icons.sports_score),
      'review' => ('Results Ready', Colors.purple, Icons.rate_review),
      'finalized' => ('Complete', Colors.indigo, Icons.check_circle),
      _ => ('Upcoming', Colors.blue, Icons.event),
    };

    return Card(
      color: statusColor.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(statusLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (courseName != null) ...[
              const SizedBox(height: 6),
              Text('Course: $courseName',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600)),
            ],

            // Check-in status
            if (isCheckedIn) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      boatStatus == 'finished'
                          ? 'Finished'
                          : boatStatus == 'dnf'
                              ? 'DNF'
                              : 'Checked In — Transmitting',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action button
            if (isCheckInOpen && !isCheckedIn)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push('/skipper-checkin/$eventId'),
                  icon: const Icon(Icons.how_to_reg, size: 24),
                  label: const Text('Check In',
                      style: TextStyle(fontSize: 18)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            if (isActive && isCheckedIn)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push('/skipper-race/$eventId'),
                  icon: const Icon(Icons.sailing, size: 24),
                  label: const Text('View Race',
                      style: TextStyle(fontSize: 18)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            if (isActive && !isCheckedIn)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push('/skipper-checkin/$eventId'),
                  icon: const Icon(Icons.how_to_reg, size: 24),
                  label: const Text('Check In to Join',
                      style: TextStyle(fontSize: 18)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            if (isFinished)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/skipper-results'),
                  icon: const Icon(Icons.leaderboard),
                  label: const Text('View Results'),
                ),
              ),

            // Race timer when running
            if (isActive && startTime != null && isCheckedIn) ...[
              const SizedBox(height: 8),
              _RaceTimerBanner(startTime: startTime),
            ],
          ],
        ),
      ),
    );
  }

  Widget _noRaceCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.sailing, size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            const Text('No race today',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 4),
            const Text('Check back on race day!',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/skipper-results'),
              icon: const Icon(Icons.leaderboard, size: 18),
              label: const Text('View Past Results'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RaceTimerBanner extends StatelessWidget {
  const _RaceTimerBanner({required this.startTime});
  final DateTime startTime;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final elapsed = DateTime.now().difference(startTime);
        final h = elapsed.inHours;
        final m = elapsed.inMinutes % 60;
        final s = elapsed.inSeconds % 60;
        final label = h > 0
            ? '${h}h ${m.toString().padLeft(2, '0')}m'
            : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text('Race Time: $label',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Quick Action Button
// ─────────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Recent Results Preview
// ─────────────────────────────────────────────────────────────────

class _RecentResultsPreview extends StatelessWidget {
  const _RecentResultsPreview();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .where('status', whereIn: ['finalized', 'review'])
          .orderBy('date', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final d = docs.first.data() as Map<String, dynamic>;
        final name = d['name'] as String? ?? 'Race';
        final date = (d['date'] as Timestamp?)?.toDate();
        final raceStartId = d['raceStartId'] as String?;

        if (raceStartId == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Recent Results',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/skipper-results'),
                  child: const Text('See All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (date != null)
                      Text(DateFormat.MMMd().format(date),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    // Top 3 finishes
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('finish_records')
                          .where('raceStartId', isEqualTo: raceStartId)
                          .orderBy('position')
                          .limit(3)
                          .snapshots(),
                      builder: (context, fSnap) {
                        final fDocs = fSnap.data?.docs ?? [];
                        if (fDocs.isEmpty) {
                          return const Text('No finishes recorded',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12));
                        }
                        return Column(
                          children: fDocs.map((fd) {
                            final f =
                                fd.data() as Map<String, dynamic>;
                            final pos = f['position'] as int? ?? 0;
                            final sail =
                                f['sailNumber'] as String? ?? '';
                            final boat =
                                f['boatName'] as String? ?? '';
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text('$pos.',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: pos <= 3
                                                ? Colors.amber.shade800
                                                : Colors.black87)),
                                  ),
                                  Text('$sail',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  if (boat.isNotEmpty)
                                    Text(' — $boat',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors
                                                .grey.shade600)),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
