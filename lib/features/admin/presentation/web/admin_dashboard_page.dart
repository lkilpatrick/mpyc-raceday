import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mpyc_raceday/features/weather/data/models/live_weather.dart';
import 'package:mpyc_raceday/features/weather/presentation/live_weather_providers.dart';
import 'package:mpyc_raceday/features/weather/presentation/widgets/wind_compass_widget.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          // ── Row 1: Metric cards ──
          const _MetricCardsRow(),
          const SizedBox(height: 16),

          // ── Row 2: Upcoming Events + Weather ──
          const _UpcomingAndWeatherRow(),
          const SizedBox(height: 16),

          // ── Row 3: Activity Feed + Open Issues ──
          const _ActivityAndIssuesRow(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Row 1 — Top metric cards
// ═══════════════════════════════════════════════════════

class _MetricCardsRow extends StatelessWidget {
  const _MetricCardsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _NextRaceCard()),
        const SizedBox(width: 12),
        Expanded(child: _MaintenanceMetricCard()),
        const SizedBox(width: 12),
        Expanded(child: _SeasonProgressCard()),
        const SizedBox(width: 12),
        Expanded(child: _MembersSyncedCard()),
      ],
    );
  }
}

class _NextRaceCard extends StatelessWidget {
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
        String name = 'No upcoming';
        String dateStr = '';
        String countdown = '';

        if (docs.isNotEmpty) {
          final d = docs.first.data() as Map<String, dynamic>;
          name = d['name'] as String? ?? 'Race Day';
          final ts = d['date'] as Timestamp?;
          if (ts != null) {
            final dt = ts.toDate();
            dateStr = DateFormat.yMMMd().format(dt);
            final diff = dt.difference(DateTime.now());
            if (diff.inDays == 0) {
              countdown = 'TODAY';
            } else if (diff.inDays == 1) {
              countdown = 'Tomorrow';
            } else {
              countdown = '${diff.inDays} days';
            }
          }
        }

        return _DashCard(
          icon: Icons.sailing,
          iconColor: Colors.blue,
          title: 'Next Race',
          value: name,
          subtitle: '$dateStr${countdown.isNotEmpty ? ' • $countdown' : ''}',
          onTap: () => context.go('/race-events'),
        );
      },
    );
  }
}

class _MaintenanceMetricCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maintenance_requests')
          .where('status', whereIn: ['open', 'in_progress'])
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        int critical = 0, high = 0, normal = 0;
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final p = d['priority'] as String? ?? '';
          if (p == 'critical') critical++;
          else if (p == 'high') high++;
          else normal++;
        }

        return _DashCard(
          icon: Icons.build,
          iconColor: critical > 0 ? Colors.red : Colors.orange,
          title: 'Active Maintenance',
          value: '${docs.length}',
          subtitle: '$critical critical • $high high • $normal normal',
          onTap: () => context.go('/maintenance'),
        );
      },
    );
  }
}

class _SeasonProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final now = DateTime.now();
        int completed = 0;
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final ts = d['date'] as Timestamp?;
          if (ts != null && ts.toDate().isBefore(now)) completed++;
        }
        final total = docs.length;
        final pct = total > 0 ? completed / total : 0.0;

        return _DashCard(
          icon: Icons.emoji_events,
          iconColor: Colors.amber,
          title: 'Season Progress',
          value: '$completed / $total',
          subtitle: '${(pct * 100).toStringAsFixed(0)}% complete',
          onTap: () => context.go('/season-calendar'),
          trailing: SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        );
      },
    );
  }
}

class _MembersSyncedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('members').snapshots(),
      builder: (context, membersSnap) {
        final memberCount = membersSnap.data?.docs.length ?? 0;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('memberSyncLogs')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, syncSnap) {
            String lastSync = 'Never';
            if (syncSnap.data != null && syncSnap.data!.docs.isNotEmpty) {
              final ts = syncSnap.data!.docs.first.data()
                  as Map<String, dynamic>;
              final t = ts['timestamp'] as Timestamp?;
              if (t != null) {
                lastSync = DateFormat.yMMMd().add_Hm().format(t.toDate());
              }
            }
            return _DashCard(
              icon: Icons.people,
              iconColor: Colors.green,
              title: 'Members Synced',
              value: '$memberCount',
              subtitle: 'Last: $lastSync',
              onTap: () => context.go('/sync-dashboard'),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Row 2 — Upcoming Events + Weather
// ═══════════════════════════════════════════════════════

class _UpcomingAndWeatherRow extends StatelessWidget {
  const _UpcomingAndWeatherRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _UpcomingEventsCard()),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _WeatherCard()),
      ],
    );
  }
}

class _UpcomingEventsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event, size: 20),
                const SizedBox(width: 8),
                Text('Upcoming Events',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/season-calendar'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(),
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
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No upcoming events'),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final name = d['name'] as String? ?? '';
                    final ts = d['date'] as Timestamp?;
                    final dateStr = ts != null
                        ? DateFormat.yMMMd().format(ts.toDate())
                        : '';
                    final crewConfirmed =
                        d['crewConfirmedCount'] as int? ?? 0;
                    final crewNeeded = d['crewNeededCount'] as int? ?? 0;

                    return ListTile(
                      dense: true,
                      title: Text(name),
                      subtitle: Text(dateStr),
                      trailing: crewNeeded > 0
                          ? Chip(
                              label: Text(
                                  '$crewConfirmed/$crewNeeded crew',
                                  style: const TextStyle(fontSize: 10)),
                              backgroundColor: crewConfirmed >= crewNeeded
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                      onTap: () =>
                          context.go('/schedule/event/${doc.id}'),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(liveWeatherProvider);
    final unit = ref.watch(windSpeedUnitProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.air, size: 20),
                const SizedBox(width: 8),
                Text('MPYC Live Wind',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                // Unit toggle
                SegmentedButton<WindSpeedUnit>(
                  segments: const [
                    ButtonSegment(value: WindSpeedUnit.kts, label: Text('kts')),
                    ButtonSegment(value: WindSpeedUnit.mph, label: Text('mph')),
                  ],
                  selected: {unit},
                  onSelectionChanged: (v) =>
                      ref.read(windSpeedUnitProvider.notifier).state = v.first,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            weatherAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Error: $e'),
              ),
              data: (weather) {
                if (weather == null) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No weather data available from NOAA. Check network connectivity.'),
                  );
                }

                final speed = unit == WindSpeedUnit.kts
                    ? weather.speedKts
                    : weather.speedMph;
                final gust = unit == WindSpeedUnit.kts
                    ? weather.gustKts
                    : weather.gustMph;

                return Column(
                  children: [
                    // Stale warning
                    if (weather.isStale)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text(
                              'Data is ${weather.staleness.inSeconds}s old',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                    // Error banner
                    if (weather.error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Fetch error: ${weather.error}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.red),
                        ),
                      ),
                    WindCompassWidget(
                      dirDeg: weather.dirDeg,
                      speed: speed,
                      unit: unit,
                      gust: gust,
                      size: 160,
                    ),
                    const SizedBox(height: 8),
                    // Extra info row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (weather.tempF != null) ...[
                          Text('${weather.tempF!.toStringAsFixed(0)}°F',
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 12),
                        ],
                        if (weather.humidity != null) ...[
                          Text('${weather.humidity!.toStringAsFixed(0)}% RH',
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 12),
                        ],
                        if (weather.pressureInHg != null)
                          Text('${weather.pressureInHg!.toStringAsFixed(2)}" Hg',
                              style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Updated ${_timeAgo(weather.fetchedAt)}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ═══════════════════════════════════════════════════════
// Row 3 — Activity Feed + Open Issues
// ═══════════════════════════════════════════════════════

class _ActivityAndIssuesRow extends StatelessWidget {
  const _ActivityAndIssuesRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _RecentActivityCard()),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _OpenIssuesCard()),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            // Check-ins
            _ActivitySection(
              icon: Icons.how_to_reg,
              color: Colors.blue,
              title: 'Check-Ins',
              collection: 'boat_checkins',
              orderField: 'checkedInAt',
              labelBuilder: (d) =>
                  '${d['boatName'] ?? ''} (${d['sailNumber'] ?? ''})',
              timeField: 'checkedInAt',
            ),
            // Incidents
            _ActivitySection(
              icon: Icons.report,
              color: Colors.red,
              title: 'Incidents',
              collection: 'incidents',
              orderField: 'reportedAt',
              labelBuilder: (d) => d['description'] as String? ?? '',
              timeField: 'reportedAt',
            ),
            // Maintenance
            _ActivitySection(
              icon: Icons.build,
              color: Colors.orange,
              title: 'Maintenance',
              collection: 'maintenance_requests',
              orderField: 'createdAt',
              labelBuilder: (d) => d['title'] as String? ?? '',
              timeField: 'createdAt',
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.icon,
    required this.color,
    required this.title,
    required this.collection,
    required this.orderField,
    required this.labelBuilder,
    required this.timeField,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String collection;
  final String orderField;
  final String Function(Map<String, dynamic>) labelBuilder;
  final String timeField;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .orderBy(orderField, descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: color)),
                ],
              ),
            ),
            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final label = labelBuilder(d);
              final ts = d[timeField] as Timestamp?;
              final timeStr = ts != null
                  ? DateFormat.Hm().format(ts.toDate())
                  : '';
              return Padding(
                padding: const EdgeInsets.only(left: 22, bottom: 2),
                child: Text(
                  '$timeStr — ${label.length > 50 ? '${label.substring(0, 50)}...' : label}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }
}

class _OpenIssuesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attention Needed',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),

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
                return _IssueTile(
                  icon: Icons.warning,
                  color: Colors.red,
                  label: '$count critical maintenance item${count > 1 ? 's' : ''}',
                  onTap: () => context.go('/maintenance'),
                );
              },
            ),

            // Unresolved incidents
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('incidents')
                  .where('status', whereIn: ['reported', 'protestFiled'])
                  .snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return _IssueTile(
                  icon: Icons.report,
                  color: Colors.orange,
                  label: '$count unresolved incident${count > 1 ? 's' : ''}',
                  onTap: () => context.go('/incidents'),
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
                  .limit(10)
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
                return _IssueTile(
                  icon: Icons.group_off,
                  color: Colors.purple,
                  label: '$needsCrew event${needsCrew > 1 ? 's' : ''} need crew',
                  onTap: () => context.go('/crew-management'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════
// Shared metric card
// ═══════════════════════════════════════════════════════

class _DashCard extends StatelessWidget {
  const _DashCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(title,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              if (trailing != null) trailing!,
              if (trailing == null)
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
