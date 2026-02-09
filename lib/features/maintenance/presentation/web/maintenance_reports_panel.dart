import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/maintenance_request.dart';
import '../maintenance_providers.dart';

class MaintenanceReportsPanel extends ConsumerWidget {
  const MaintenanceReportsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(maintenanceRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (requests) {
        // By boat
        final byBoat = <String, int>{};
        for (final r in requests) {
          byBoat.update(r.boatName, (v) => v + 1, ifAbsent: () => 1);
        }

        // By category
        final byCategory = <String, int>{};
        for (final r in requests) {
          byCategory.update(r.category.name, (v) => v + 1,
              ifAbsent: () => 1);
        }

        // By month
        final byMonth = <String, int>{};
        for (final r in requests) {
          final key = DateFormat('yyyy-MM').format(r.reportedAt);
          byMonth.update(key, (v) => v + 1, ifAbsent: () => 1);
        }

        // Average resolution time
        final completed = requests.where(
            (r) => r.status == MaintenanceStatus.completed && r.completedAt != null);
        final avgResolution = completed.isNotEmpty
            ? completed
                    .map((r) =>
                        r.completedAt!.difference(r.reportedAt).inHours)
                    .reduce((a, b) => a + b) /
                completed.length
            : 0;

        // Cost tracking
        final totalCost = requests
            .where((r) => r.estimatedCost != null)
            .fold<double>(0, (sum, r) => sum + r.estimatedCost!);

        // Open vs resolved
        final openCount = requests
            .where((r) =>
                r.status != MaintenanceStatus.completed &&
                r.status != MaintenanceStatus.deferred)
            .length;
        final resolvedCount = requests
            .where((r) => r.status == MaintenanceStatus.completed)
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Maintenance Reports',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _exportCsv(requests),
                    icon: const Icon(Icons.download),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary cards
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    title: 'Total Requests',
                    value: '${requests.length}',
                    icon: Icons.build,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Open',
                    value: '$openCount',
                    icon: Icons.pending,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Resolved',
                    value: '$resolvedCount',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: 'Avg Resolution',
                    value: '${avgResolution.toStringAsFixed(0)}h',
                    icon: Icons.timer,
                    color: Colors.purple,
                  ),
                  _StatCard(
                    title: 'Total Est. Cost',
                    value: '\$${totalCost.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    color: Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // By boat
              Text('Requests by Boat',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: byBoat.entries.map((e) {
                    final pct = requests.isNotEmpty
                        ? e.value / requests.length
                        : 0.0;
                    return ListTile(
                      title: Text(e.key),
                      trailing: Text('${e.value}'),
                      subtitle: LinearProgressIndicator(value: pct),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // By category
              Text('Requests by Category',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: byCategory.entries.map((e) {
                    final pct = requests.isNotEmpty
                        ? e.value / requests.length
                        : 0.0;
                    return ListTile(
                      title: Text(e.key[0].toUpperCase() + e.key.substring(1)),
                      trailing: Text('${e.value}'),
                      subtitle: LinearProgressIndicator(value: pct),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // By month (trend)
              Text('Monthly Trend',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: (byMonth.entries.toList()
                          ..sort((a, b) => a.key.compareTo(b.key)))
                        .map((e) {
                      final maxVal = byMonth.values
                          .reduce((a, b) => a > b ? a : b);
                      final pct = maxVal > 0 ? e.value / maxVal : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(width: 80, child: Text(e.key)),
                            Expanded(
                              child: LinearProgressIndicator(value: pct),
                            ),
                            const SizedBox(width: 8),
                            Text('${e.value}'),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportCsv(List<MaintenanceRequest> requests) {
    final buffer = StringBuffer();
    buffer.writeln(
        'ID,Boat,Title,Category,Priority,Status,Reported By,Date,Assigned To,Estimated Cost,Completed At');
    for (final r in requests) {
      final statusLabel = switch (r.status) {
        MaintenanceStatus.reported => 'Reported',
        MaintenanceStatus.acknowledged => 'Acknowledged',
        MaintenanceStatus.inProgress => 'In Progress',
        MaintenanceStatus.awaitingParts => 'Awaiting Parts',
        MaintenanceStatus.completed => 'Completed',
        MaintenanceStatus.deferred => 'Deferred',
      };
      buffer.writeln(
        '${r.id},"${r.boatName}","${r.title}",${r.category.name},${r.priority.name},$statusLabel,${r.reportedBy},${DateFormat('yyyy-MM-dd').format(r.reportedAt)},${r.assignedTo ?? ''},${r.estimatedCost ?? ''},${r.completedAt != null ? DateFormat('yyyy-MM-dd').format(r.completedAt!) : ''}',
      );
    }
    final csvData = buffer.toString();
    final uri = Uri.dataFromString(csvData,
        mimeType: 'text/csv', encoding: utf8);
    launchUrl(uri);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
