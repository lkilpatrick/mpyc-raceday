import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/race_incident.dart';
import '../incidents_providers.dart';

class IncidentDetailScreen extends ConsumerStatefulWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  ConsumerState<IncidentDetailScreen> createState() =>
      _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends ConsumerState<IncidentDetailScreen> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidentAsync = ref.watch(incidentDetailProvider(widget.incidentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Incident Detail')),
      body: incidentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incident) {
          if (incident == null) {
            return const Center(child: Text('Incident not found'));
          }
          return _buildBody(context, incident);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, RaceIncident incident) {
    final (statusLabel, statusColor) = _statusInfo(incident.status);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Status + time header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            const Spacer(),
            Text('Race ${incident.raceNumber}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 8),
            Text(DateFormat.yMMMd().add_Hm().format(incident.incidentTime),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 16),

        // Boats involved
        Text('Boats Involved',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...incident.involvedBoats.map((b) {
          final (roleLabel, roleColor) = _roleInfo(b.role);
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: roleColor,
                child: Text(roleLabel[0],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text('${b.boatName} (${b.sailNumber})'),
              subtitle: Text('${b.skipperName} — $roleLabel'),
            ),
          );
        }),
        const SizedBox(height: 12),

        // Location
        Card(
          child: ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(_locationLabel(incident.locationOnCourse)),
            subtitle: const Text('Location on course'),
          ),
        ),
        const SizedBox(height: 12),

        // Description
        Text('Description',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(incident.description),
          ),
        ),
        const SizedBox(height: 12),

        // Rules alleged
        if (incident.rulesAlleged.isNotEmpty) ...[
          Text('Rules Alleged',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          ...incident.rulesAlleged.map((r) => Card(
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.gavel, size: 18),
                  title: Text(r, style: const TextStyle(fontSize: 13)),
                ),
              )),
          const SizedBox(height: 12),
        ],

        // Hearing info
        if (incident.hearing != null) ...[
          Text('Hearing',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (incident.hearing!.scheduledAt != null)
                    Text(
                        'Scheduled: ${DateFormat.yMMMd().add_Hm().format(incident.hearing!.scheduledAt!)}'),
                  if (incident.hearing!.location != null)
                    Text('Location: ${incident.hearing!.location}'),
                  if (incident.hearing!.juryMembers.isNotEmpty)
                    Text('Jury: ${incident.hearing!.juryMembers.join(", ")}'),
                  if (incident.hearing!.findingOfFact.isNotEmpty) ...[
                    const Divider(),
                    const Text('Finding of Fact:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(incident.hearing!.findingOfFact),
                  ],
                  if (incident.hearing!.penalty.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Penalty: ${incident.hearing!.penalty}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Attachments
        if (incident.attachments.isNotEmpty) ...[
          Text('Attachments (${incident.attachments.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: incident.attachments.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    incident.attachments[i],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Comments
        Text('Comments (${incident.comments.length})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        ...incident.comments.map((c) => Card(
              child: ListTile(
                dense: true,
                title: Text(c.text),
                subtitle: Text(
                    '${c.authorName} • ${DateFormat.Hm().format(c.createdAt)}'),
              ),
            )),
        const SizedBox(height: 8),

        // Add comment
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _addComment(incident.id),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Resolution
        if (incident.resolution.isNotEmpty) ...[
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resolution',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(incident.resolution),
                  if (incident.penaltyApplied.isNotEmpty)
                    Text('Penalty: ${incident.penaltyApplied}',
                        style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _addComment(String incidentId) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final comment = IncidentComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: 'current_user',
      authorName: 'PRO',
      text: text,
      createdAt: DateTime.now(),
    );

    await ref
        .read(incidentsRepositoryProvider)
        .addComment(incidentId, comment);

    _commentCtrl.clear();
    ref.invalidate(incidentDetailProvider(incidentId));
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

  (String, Color) _roleInfo(BoatInvolvedRole role) => switch (role) {
        BoatInvolvedRole.protesting => ('Protesting', Colors.red),
        BoatInvolvedRole.protested => ('Protested', Colors.orange),
        BoatInvolvedRole.witness => ('Witness', Colors.blue),
      };

  String _locationLabel(CourseLocationOnIncident loc) => switch (loc) {
        CourseLocationOnIncident.startLine => 'Start Line',
        CourseLocationOnIncident.windwardMark => 'Windward Mark',
        CourseLocationOnIncident.gate => 'Gate',
        CourseLocationOnIncident.leewardMark => 'Leeward Mark',
        CourseLocationOnIncident.reachingMark => 'Reaching Mark',
        CourseLocationOnIncident.openWater => 'Open Water',
      };
}
