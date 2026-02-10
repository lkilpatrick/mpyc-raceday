import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/data/auth_providers.dart';
import '../../../auth/data/models/member.dart';
import '../../../boat_checkin/presentation/boat_checkin_providers.dart';
import '../../../maintenance/presentation/maintenance_providers.dart';
import '../../../crew_assignment/presentation/crew_assignment_providers.dart';
import '../../../crew_assignment/presentation/crew_assignment_formatters.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentUserProvider);
    final member = memberAsync.value;
    final isRCChair = member?.isRCChair ?? false;
    final isProOrAdmin = isRCChair;
    final isRcCrew = isRCChair;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentUserProvider);
        ref.invalidate(criticalMaintenanceCountProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ── For ALL: Today's Race hero card ──
          const _TodaysRaceCard(),
          const SizedBox(height: 8),

          // ── For RC CREW: Your Role Today / Next Duty ──
          if (isRcCrew) ...[
            _YourRoleCard(ref: ref),
            const SizedBox(height: 8),
          ],

          // ── For PRO/ADMIN: Race Control ──
          if (isProOrAdmin) ...[
            const _RaceControlCard(),
            const SizedBox(height: 8),
            const _AttentionNeededCard(),
            const SizedBox(height: 8),
          ],

          // ── For ALL: Weather compact ──
          const _WeatherCompactCard(),
          const SizedBox(height: 8),

          // ── For ALL: Maintenance alerts ──
          const _MaintenanceAlertCard(),
          const SizedBox(height: 8),

          // ── For ALL: Recent results ──
          const _RecentResultsCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Today's Race hero card
// ═══════════════════════════════════════════════════════

class _TodaysRaceCard extends StatelessWidget {
  const _TodaysRaceCard();

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
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.sailing,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  const Text('No race today',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 4),
                  const _NextRaceMini(),
                ],
              ),
            ),
          );
        }

        final d = docs.first.data() as Map<String, dynamic>;
        final eventId = docs.first.id;
        final name = d['name'] as String? ?? 'Race Day';
        final status = d['status'] as String? ?? 'setup';
        final courseId = d['courseId'] as String? ?? '';

        final (statusLabel, statusColor) = switch (status) {
          'setup' => ('Setup', Colors.orange),
          'racing' => ('Racing', Colors.green),
          'complete' => ('Complete', Colors.blue),
          _ => ('—', Colors.grey),
        };

        return Card(
          color: statusColor.withValues(alpha: 0.08),
          child: InkWell(
            onTap: () => context.push('/schedule/event/$eventId'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sailing, color: statusColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(statusLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Course
                      _MiniStat(
                        icon: Icons.map,
                        label: courseId.isNotEmpty ? 'Course $courseId' : 'No course',
                      ),
                      const SizedBox(width: 16),
                      // Fleet size
                      _FleetSizeStat(eventId: eventId),
                      const SizedBox(width: 16),
                      // Weather mini
                      const _WeatherMiniStat(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NextRaceMini extends StatelessWidget {
  const _NextRaceMini();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('date')
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        final d = docs.first.data() as Map<String, dynamic>;
        final name = d['name'] as String? ?? '';
        final ts = d['date'] as Timestamp?;
        final dateStr =
            ts != null ? DateFormat.yMMMd().format(ts.toDate()) : '';
        return Text('Next: $name — $dateStr',
            style: const TextStyle(fontSize: 12, color: Colors.grey));
      },
    );
  }
}

class _FleetSizeStat extends ConsumerWidget {
  const _FleetSizeStat({required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(checkinCountProvider(eventId));
    return _MiniStat(icon: Icons.directions_boat, label: '$count boats');
  }
}

class _WeatherMiniStat extends StatelessWidget {
  const _WeatherMiniStat();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('weather')
          .doc('mpyc_station')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const _MiniStat(icon: Icons.cloud, label: '—');
        }
        final d = snap.data!.data() as Map<String, dynamic>? ?? {};
        final wind = (d['speedKts'] as num?)?.toDouble() ?? 0;
        return _MiniStat(
            icon: Icons.air, label: '${wind.toStringAsFixed(0)} kts');
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// Your Role Today / Next Duty
// ═══════════════════════════════════════════════════════

class _YourRoleCard extends StatelessWidget {
  const _YourRoleCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final nextDutyAsync = ref.watch(nextDutyProvider);

    return nextDutyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (assignment) {
        if (assignment == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.event_available, color: Colors.green),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('No upcoming RC duty assigned'),
                  ),
                  TextButton(
                    onPressed: () => context.push('/schedule'),
                    child: const Text('Schedule'),
                  ),
                ],
              ),
            ),
          );
        }

        final isToday = _isToday(assignment.event.date);

        return Card(
          color: isToday ? Colors.blue.shade50 : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isToday ? Icons.person_pin : Icons.event_note,
                        color: isToday ? Colors.blue : Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      isToday ? 'Your Role Today' : 'Your Next RC Duty',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(assignment.event.name),
                Text(
                    '${DateFormat.yMMMd().format(assignment.event.date)} • ${roleLabel(assignment.role)}'),
                if (!isToday) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${assignment.event.date.difference(DateTime.now()).inDays} days away',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (isToday)
                      FilledButton.icon(
                        onPressed: () => context.push('/checklists'),
                        icon: const Icon(Icons.checklist, size: 18),
                        label: const Text('Pre-Race Checklist'),
                      ),
                    if (isToday)
                      OutlinedButton.icon(
                        onPressed: () => context.push(
                            '/checkin/${assignment.event.id}'),
                        icon: const Icon(Icons.how_to_reg, size: 18),
                        label: const Text('Open Check-In'),
                      ),
                    if (!isToday)
                      FilledButton(
                        onPressed: () => context.push(
                            '/schedule/event/${assignment.event.id}'),
                        child: const Text('View Assignment'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

// ═══════════════════════════════════════════════════════
// Race Control (PRO/Admin during active event)
// ═══════════════════════════════════════════════════════

class _RaceControlCard extends StatelessWidget {
  const _RaceControlCard();

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
        if (docs.isEmpty) return const SizedBox.shrink();

        final eventId = docs.first.id;

        return Card(
          color: Colors.indigo.shade50,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Race Control',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickAction(
                      icon: Icons.map,
                      label: 'Select Course',
                      onTap: () =>
                          context.push('/courses/select/$eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.timer,
                      label: 'Start Sequence',
                      onTap: () =>
                          context.push('/timing/start/$eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.sports_score,
                      label: 'Record Finishes',
                      onTap: () =>
                          context.push('/timing/$eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.campaign,
                      label: 'Broadcast',
                      onTap: () =>
                          context.push('/courses/broadcast/$eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.how_to_reg,
                      label: 'Check-In',
                      onTap: () =>
                          context.push('/checkin/$eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.report,
                      label: 'Incident',
                      onTap: () =>
                          context.push('/incidents/report/$eventId'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.indigo.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.indigo),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Attention Needed (PRO/Admin)
// ═══════════════════════════════════════════════════════

class _AttentionNeededCard extends StatelessWidget {
  const _AttentionNeededCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notification_important, color: Colors.amber),
                SizedBox(width: 8),
                Text('Attention Needed',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),

            // Unresolved incidents
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('incidents')
                  .where('status', whereIn: ['reported', 'protestFiled'])
                  .snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return _AttentionItem(
                  icon: Icons.report,
                  color: Colors.red,
                  text: '$count unresolved incident${count > 1 ? 's' : ''}',
                );
              },
            ),

            // Critical maintenance
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('maintenance_requests')
                  .where('priority', isEqualTo: 'critical')
                  .where('status', whereIn: ['open', 'in_progress'])
                  .snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return _AttentionItem(
                  icon: Icons.build,
                  color: Colors.orange,
                  text:
                      '$count critical maintenance item${count > 1 ? 's' : ''}',
                );
              },
            ),

            // Upcoming events needing crew
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('race_events')
                  .where('date',
                      isGreaterThanOrEqualTo: Timestamp.now())
                  .orderBy('date')
                  .limit(5)
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                int needsCrew = 0;
                for (final doc in docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  final confirmed = d['crewConfirmedCount'] as int? ?? 0;
                  final needed = d['crewNeededCount'] as int? ?? 0;
                  if (needed > 0 && confirmed < needed) needsCrew++;
                }
                if (needsCrew == 0) return const SizedBox.shrink();
                return _AttentionItem(
                  icon: Icons.group_off,
                  color: Colors.purple,
                  text:
                      '$needsCrew event${needsCrew > 1 ? 's' : ''} need crew confirmation',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionItem extends StatelessWidget {
  const _AttentionItem({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Weather compact card
// ═══════════════════════════════════════════════════════

class _WeatherCompactCard extends StatelessWidget {
  const _WeatherCompactCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('weather')
          .doc('mpyc_station')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }
        final d = snap.data!.data() as Map<String, dynamic>? ?? {};
        final wind = (d['speedKts'] as num?)?.toDouble() ?? 0;
        final dir = (d['dirDeg'] as num?)?.toDouble() ?? 0;
        final temp = (d['tempF'] as num?)?.toDouble();
        final source = d['source'] as String? ?? '';

        final tempStr = temp != null ? '${temp.toStringAsFixed(0)}°F' : '';
        final subtitle = [tempStr, if (source.isNotEmpty) source.toUpperCase()]
            .where((s) => s.isNotEmpty)
            .join(' • ');

        return Card(
          child: InkWell(
            onTap: () => context.push('/live-wind'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.air,
                      color: wind > 20 ? Colors.red : Colors.blue,
                      size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${wind.toStringAsFixed(0)} kts from ${dir.toStringAsFixed(0)}°',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Maintenance alert badge card
// ═══════════════════════════════════════════════════════

class _MaintenanceAlertCard extends ConsumerWidget {
  const _MaintenanceAlertCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(criticalMaintenanceCountProvider);
    final count = countAsync.value ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Card(
      color: Colors.red.shade50,
      child: InkWell(
        onTap: () => context.push('/maintenance/feed'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count critical maintenance issue${count > 1 ? 's' : ''}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Recent results card
// ═══════════════════════════════════════════════════════

class _RecentResultsCard extends StatelessWidget {
  const _RecentResultsCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .where('date', isLessThan: Timestamp.now())
          .orderBy('date', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final d = docs.first.data() as Map<String, dynamic>;
        final name = d['name'] as String? ?? '';
        final ts = d['date'] as Timestamp?;
        final dateStr =
            ts != null ? DateFormat.yMMMd().format(ts.toDate()) : '';

        return Card(
          child: InkWell(
            onTap: () =>
                context.push('/schedule/event/${docs.first.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recent Results',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('$name — $dateStr',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
