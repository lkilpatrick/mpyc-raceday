import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/race_incident.dart';
import '../incidents_providers.dart';

class IncidentListScreen extends ConsumerWidget {
  const IncidentListScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(eventIncidentsProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/incidents/report/$eventId'),
          ),
        ],
      ),
      body: incidentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incidents) {
          if (incidents.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green.shade200),
                  const SizedBox(height: 12),
                  const Text('No incidents reported'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () =>
                        context.push('/incidents/report/$eventId'),
                    icon: const Icon(Icons.add),
                    label: const Text('Report Incident'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: incidents.length,
            itemBuilder: (_, i) {
              final inc = incidents[i];
              return _IncidentCard(
                incident: inc,
                onTap: () =>
                    context.push('/incidents/detail/${inc.id}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/incidents/report/$eventId'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident, required this.onTap});

  final RaceIncident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusInfo(incident.status);
    final boatNames =
        incident.involvedBoats.map((b) => b.sailNumber).join(' vs ');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  const Spacer(),
                  Text('Race ${incident.raceNumber}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Text(DateFormat.Hm().format(incident.incidentTime),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(boatNames,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(incident.description,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              if (incident.rulesAlleged.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: incident.rulesAlleged.take(3).map((r) {
                    final ruleNum = r.split(' – ').first;
                    return Chip(
                      label: Text('Rule $ruleNum',
                          style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              if (incident.attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, size: 14, color: Colors.grey),
                      Text('${incident.attachments.length} attachment(s)',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _statusInfo(RaceIncidentStatus status) => switch (status) {
        RaceIncidentStatus.reported => ('Reported', Colors.orange),
        RaceIncidentStatus.protestFiled => ('Protest Filed', Colors.red),
        RaceIncidentStatus.hearingScheduled =>
          ('Hearing Scheduled', Colors.purple),
        RaceIncidentStatus.hearingComplete =>
          ('Hearing Complete', Colors.blue),
        RaceIncidentStatus.resolved => ('Resolved', Colors.green),
        RaceIncidentStatus.withdrawn => ('Withdrawn', Colors.grey),
      };
}
