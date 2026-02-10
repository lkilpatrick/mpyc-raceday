import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/maintenance_request.dart';
import '../../domain/maintenance_repository.dart';
import '../maintenance_providers.dart';

class MaintenanceDashboardPage extends ConsumerWidget {
  const MaintenanceDashboardPage({super.key});

  static const _boats = [
    "Duncan's Watch",
    'Signal Boat',
    'Mark Boat',
    'Safety Boat',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(maintenanceRequestsProvider);
    final scheduleAsync = ref.watch(scheduledMaintenanceProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (requests) {
        final open = requests.where((r) =>
            r.status != MaintenanceStatus.completed &&
            r.status != MaintenanceStatus.deferred);
        final criticals = open
            .where((r) => r.priority == MaintenancePriority.critical)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Critical alert banner
              if (criticals.isNotEmpty)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${criticals.length} CRITICAL issue${criticals.length > 1 ? 's' : ''} require immediate attention',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (criticals.isNotEmpty) const SizedBox(height: 16),

              // Per-boat overview cards
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _boats.map((boat) {
                  final boatRequests =
                      open.where((r) => r.boatName == boat).toList();
                  final critical = boatRequests
                      .where(
                          (r) => r.priority == MaintenancePriority.critical)
                      .length;
                  final high = boatRequests
                      .where((r) => r.priority == MaintenancePriority.high)
                      .length;
                  final medium = boatRequests
                      .where(
                          (r) => r.priority == MaintenancePriority.medium)
                      .length;
                  final low = boatRequests
                      .where((r) => r.priority == MaintenancePriority.low)
                      .length;

                  // Last completed for this boat
                  final completed = requests
                      .where((r) =>
                          r.boatName == boat &&
                          r.status == MaintenanceStatus.completed)
                      .toList();
                  final lastCompleted = completed.isNotEmpty
                      ? completed
                          .reduce((a, b) => (a.completedAt ?? a.reportedAt)
                                  .isAfter(b.completedAt ?? b.reportedAt)
                              ? a
                              : b)
                      : null;

                  // Upcoming scheduled
                  final scheduled = scheduleAsync.value
                          ?.where((s) => s.boatName == boat)
                          .toList() ??
                      [];

                  return SizedBox(
                    width: 280,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sailing),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    boat,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Text('Open Issues:'),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _PriorityBadge(
                                    count: critical,
                                    color: Colors.red,
                                    label: 'Crit'),
                                const SizedBox(width: 6),
                                _PriorityBadge(
                                    count: high,
                                    color: Colors.deepOrange,
                                    label: 'High'),
                                const SizedBox(width: 6),
                                _PriorityBadge(
                                    count: medium,
                                    color: Colors.orange,
                                    label: 'Med'),
                                const SizedBox(width: 6),
                                _PriorityBadge(
                                    count: low,
                                    color: Colors.green,
                                    label: 'Low'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lastCompleted?.completedAt != null
                                  ? 'Last completed: ${DateFormat.MMMd().format(lastCompleted!.completedAt!)}'
                                  : 'No completed work',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (scheduled.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Next scheduled: ${scheduled.first.title}',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                              if (scheduled.first.nextDueAt != null)
                                Text(
                                  'Due: ${DateFormat.MMMd().format(scheduled.first.nextDueAt!)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheduled.first.nextDueAt!
                                                .isBefore(DateTime.now())
                                            ? Colors.red
                                            : null,
                                      ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── Checklist History Per Boat ──
              Text('Checklist History',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              ..._boats.map((boat) => _BoatChecklistHistory(boatName: boat)),
            ],
          ),
        );
      },
    );
  }
}

class _BoatChecklistHistory extends StatelessWidget {
  const _BoatChecklistHistory({required this.boatName});
  final String boatName;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('checklist_completions')
          .where('boatName', isEqualTo: boatName)
          .orderBy('startedAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty && !snapshot.hasError) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sailing, size: 20),
                    const SizedBox(width: 8),
                    Text(boatName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${docs.length} checklist${docs.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const Divider(height: 16),
                if (snapshot.hasError)
                  Text('Error loading checklists',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12))
                else if (docs.isEmpty)
                  Text('No completed checklists',
                      style: Theme.of(context).textTheme.bodySmall)
                else
                  ...docs.map((doc) {
                    final d = doc.data();
                    final checklistName =
                        d['checklistName'] as String? ?? d['checklistId'] as String? ?? 'Checklist';
                    final status = d['status'] as String? ?? '';
                    final items = d['items'] as List<dynamic>? ?? [];
                    final checked = items.where((i) => (i as Map)['checked'] == true).length;
                    final total = items.length;
                    final pct = total > 0 ? (checked / total * 100).round() : 0;

                    DateTime? startedAt;
                    final startRaw = d['startedAt'];
                    if (startRaw is Timestamp) {
                      startedAt = startRaw.toDate();
                    } else if (startRaw is String) {
                      startedAt = DateTime.tryParse(startRaw);
                    }

                    DateTime? completedAt;
                    final compRaw = d['completedAt'];
                    if (compRaw is Timestamp) {
                      completedAt = compRaw.toDate();
                    } else if (compRaw is String) {
                      completedAt = DateTime.tryParse(compRaw);
                    }

                    final (statusLabel, statusColor) = switch (status) {
                      'signedOff' => ('Signed Off', Colors.green),
                      'completedPendingSignoff' => ('Pending Sign-off', Colors.orange),
                      'inProgress' => ('In Progress', Colors.blue),
                      _ => (status, Colors.grey),
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(checklistName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13)),
                                if (startedAt != null)
                                  Text(
                                    DateFormat.yMMMd().add_jm().format(startedAt),
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: Column(
                              children: [
                                Text('$checked/$total',
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                LinearProgressIndicator(
                                  value: total > 0 ? checked / total : 0,
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(statusLabel,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({
    required this.count,
    required this.color,
    required this.label,
  });

  final int count;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: count > 0 ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: count > 0 ? color : Colors.grey,
        ),
      ),
    );
  }
}
