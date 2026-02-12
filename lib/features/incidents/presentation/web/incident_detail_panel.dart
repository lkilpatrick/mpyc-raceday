import 'package:flutter/material.dart';
import '../../../../shared/utils/web_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/race_incident.dart';
import '../../data/services/protest_form_generator.dart';
import '../incidents_providers.dart';

class IncidentDetailPanel extends ConsumerStatefulWidget {
  const IncidentDetailPanel({
    super.key,
    required this.incidentId,
    required this.onClose,
  });

  final String incidentId;
  final VoidCallback onClose;

  @override
  ConsumerState<IncidentDetailPanel> createState() =>
      _IncidentDetailPanelState();
}

class _IncidentDetailPanelState extends ConsumerState<IncidentDetailPanel> {
  final _commentCtrl = TextEditingController();
  final _hearingDateCtrl = TextEditingController();
  final _hearingLocationCtrl = TextEditingController();
  final _juryCtrl = TextEditingController();
  final _findingCtrl = TextEditingController();
  final _penaltyCtrl = TextEditingController();
  final _decisionCtrl = TextEditingController();
  final _resolutionCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    _hearingDateCtrl.dispose();
    _hearingLocationCtrl.dispose();
    _juryCtrl.dispose();
    _findingCtrl.dispose();
    _penaltyCtrl.dispose();
    _decisionCtrl.dispose();
    _resolutionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidentAsync = ref.watch(incidentDetailProvider(widget.incidentId));

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: incidentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incident) {
          if (incident == null) {
            return const Center(child: Text('Incident not found'));
          }
          return _buildPanel(context, incident);
        },
      ),
    );
  }

  Widget _buildPanel(BuildContext context, RaceIncident incident) {
    final (statusLabel, statusColor) = _statusInfo(incident.status);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            Text('Incident Detail',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _showEditDialog(incident),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
          ],
        ),
        const Divider(),

        // Reported date
        Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text('Reported: ${DateFormat('MMM d, yyyy h:mm a').format(incident.reportedAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const Spacer(),
            Text('by ${incident.reportedBy}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 8),

        // Status workflow
        Text('Status', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(statusLabel,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: RaceIncidentStatus.values.map((s) {
            final (label, color) = _statusInfo(s);
            final isCurrent = incident.status == s;
            return ActionChip(
              label: Text(label, style: TextStyle(fontSize: 10, color: isCurrent ? Colors.white : color)),
              backgroundColor: isCurrent ? color : color.withValues(alpha: 0.1),
              onPressed: () => _updateStatus(incident.id, s),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Boats
        Text('Boats Involved', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        ...incident.involvedBoats.map((b) {
          final (roleLabel, roleColor) = _roleInfo(b.role);
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: roleColor,
              child: Text(roleLabel[0],
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
            title: Text('${b.boatName} (${b.sailNumber})',
                style: const TextStyle(fontSize: 13)),
            subtitle: Text('${b.skipperName} — $roleLabel',
                style: const TextStyle(fontSize: 11)),
          );
        }),
        const SizedBox(height: 12),

        // Description
        Text('Description', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(incident.description),
        const SizedBox(height: 12),

        // Rules
        if (incident.rulesAlleged.isNotEmpty) ...[
          Text('Rules Alleged', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          ...incident.rulesAlleged.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    const Icon(Icons.gavel, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(r, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              )),
          const SizedBox(height: 12),
        ],

        // Hearing management
        Text('Hearing', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        if (incident.hearing != null && incident.hearing!.scheduledAt != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scheduled: ${DateFormat.yMMMd().add_Hm().format(incident.hearing!.scheduledAt!)}'),
                  if (incident.hearing!.location != null)
                    Text('Location: ${incident.hearing!.location}'),
                  if (incident.hearing!.juryMembers.isNotEmpty)
                    Text('Jury: ${incident.hearing!.juryMembers.join(", ")}'),
                  if (incident.hearing!.findingOfFact.isNotEmpty) ...[
                    const Divider(),
                    const Text('Finding of Fact:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(incident.hearing!.findingOfFact, style: const TextStyle(fontSize: 12)),
                  ],
                  if (incident.hearing!.penalty.isNotEmpty)
                    Text('Penalty: ${incident.hearing!.penalty}',
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                  if (incident.hearing!.decisionNotes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Decision: ${incident.hearing!.decisionNotes}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        ],
        OutlinedButton.icon(
          onPressed: () => _showHearingDialog(incident),
          icon: const Icon(Icons.event, size: 16),
          label: Text(incident.hearing?.scheduledAt != null
              ? 'Edit Hearing'
              : 'Schedule Hearing'),
        ),
        const SizedBox(height: 12),

        // Evidence / attachments
        Text('Evidence (${incident.attachments.length})',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        if (incident.attachments.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: incident.attachments.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    incident.attachments[i],
                    width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80, height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const Text('No attachments', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),

        // Resolution
        Text('Resolution', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        if (incident.resolution.isNotEmpty)
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(incident.resolution),
                  if (incident.penaltyApplied.isNotEmpty)
                    Text('Penalty: ${incident.penaltyApplied}',
                        style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          )
        else
          TextField(
            controller: _resolutionCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter resolution...',
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => _saveResolution(incident),
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Comments
        Text('Comments (${incident.comments.length})',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        ...incident.comments.map((c) => Card(
              child: ListTile(
                dense: true,
                title: Text(c.text, style: const TextStyle(fontSize: 12)),
                subtitle: Text(
                    '${c.authorName} • ${DateFormat.Hm().format(c.createdAt)}',
                    style: const TextStyle(fontSize: 10)),
              ),
            )),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                decoration: const InputDecoration(
                  hintText: 'Add comment...',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              onPressed: () => _addComment(incident.id),
              icon: const Icon(Icons.send, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _generateProtestForm(incident),
              icon: const Icon(Icons.description, size: 16),
              label: const Text('Protest Form'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _generateDecision(incident),
              icon: const Icon(Icons.article, size: 16),
              label: const Text('Decision Doc'),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _updateStatus(String id, RaceIncidentStatus status) async {
    await ref.read(incidentsRepositoryProvider).updateStatus(id, status);
    ref.invalidate(incidentDetailProvider(id));
    ref.invalidate(allIncidentsProvider);
  }

  Future<void> _addComment(String incidentId) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final comment = IncidentComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: 'admin',
      authorName: 'Admin',
      text: text,
      createdAt: DateTime.now(),
    );
    await ref.read(incidentsRepositoryProvider).addComment(incidentId, comment);
    _commentCtrl.clear();
    ref.invalidate(incidentDetailProvider(incidentId));
  }

  void _showHearingDialog(RaceIncident incident) {
    if (incident.hearing != null) {
      _hearingLocationCtrl.text = incident.hearing!.location ?? '';
      _juryCtrl.text = incident.hearing!.juryMembers.join(', ');
      _findingCtrl.text = incident.hearing!.findingOfFact;
      _penaltyCtrl.text = incident.hearing!.penalty;
      _decisionCtrl.text = incident.hearing!.decisionNotes;
    }

    DateTime? selectedDate = incident.hearing?.scheduledAt;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Hearing Details'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(selectedDate != null
                        ? DateFormat.yMMMd().add_Hm().format(selectedDate!)
                        : 'Select date/time'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(
                            selectedDate ?? DateTime.now()),
                      );
                      if (time == null) return;
                      setDialogState(() {
                        selectedDate = DateTime(
                            date.year, date.month, date.day, time.hour, time.minute);
                      });
                    },
                  ),
                  TextField(
                    controller: _hearingLocationCtrl,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  TextField(
                    controller: _juryCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Jury Members (comma-separated)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _findingCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Finding of Fact',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _penaltyCtrl,
                    decoration: const InputDecoration(labelText: 'Penalty'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _decisionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Decision Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final hearing = HearingInfo(
                  scheduledAt: selectedDate,
                  location: _hearingLocationCtrl.text.trim(),
                  juryMembers: _juryCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList(),
                  findingOfFact: _findingCtrl.text.trim(),
                  penalty: _penaltyCtrl.text.trim(),
                  decisionNotes: _decisionCtrl.text.trim(),
                );
                await ref
                    .read(incidentsRepositoryProvider)
                    .updateHearing(incident.id, hearing);
                ref.invalidate(incidentDetailProvider(incident.id));
                ref.invalidate(allIncidentsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveResolution(RaceIncident incident) async {
    final text = _resolutionCtrl.text.trim();
    if (text.isEmpty) return;

    final updated = RaceIncident(
      id: incident.id,
      eventId: incident.eventId,
      raceNumber: incident.raceNumber,
      reportedAt: incident.reportedAt,
      reportedBy: incident.reportedBy,
      incidentTime: incident.incidentTime,
      description: incident.description,
      locationOnCourse: incident.locationOnCourse,
      involvedBoats: incident.involvedBoats,
      rulesAlleged: incident.rulesAlleged,
      status: RaceIncidentStatus.resolved,
      hearing: incident.hearing,
      resolution: text,
      penaltyApplied: incident.penaltyApplied,
      witnesses: incident.witnesses,
      attachments: incident.attachments,
      comments: incident.comments,
    );
    await ref.read(incidentsRepositoryProvider).updateIncident(updated);
    _resolutionCtrl.clear();
    ref.invalidate(incidentDetailProvider(incident.id));
    ref.invalidate(allIncidentsProvider);
  }

  void _showEditDialog(RaceIncident incident) {
    final descCtrl = TextEditingController(text: incident.description);
    final reporterCtrl = TextEditingController(text: incident.reportedBy);
    int raceNumber = incident.raceNumber;
    String locationChoice = _locationLabel(incident.locationOnCourse);
    final locationDetailCtrl = TextEditingController(text: incident.locationDetail);
    final rulesCtrl = TextEditingController(text: incident.rulesAlleged.join('\n'));

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Incident'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: reporterCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reporter',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: raceNumber,
                          decoration: const InputDecoration(
                            labelText: 'Race #',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(10, (i) => i + 1)
                              .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                              .toList(),
                          onChanged: (v) => setDialogState(() => raceNumber = v ?? raceNumber),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: locationChoice,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Start Line', child: Text('Start Line')),
                            DropdownMenuItem(value: 'Windward Mark', child: Text('Windward Mark')),
                            DropdownMenuItem(value: 'Leeward Mark', child: Text('Leeward Mark')),
                            DropdownMenuItem(value: 'Gate', child: Text('Gate')),
                            DropdownMenuItem(value: 'Reaching Mark', child: Text('Reaching Mark')),
                            DropdownMenuItem(value: 'Open Water', child: Text('Open Water')),
                          ],
                          onChanged: (v) => setDialogState(() => locationChoice = v ?? locationChoice),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationDetailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Location Detail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: rulesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Rules Alleged (one per line)',
                      border: OutlineInputBorder(),
                      hintText: 'Rule 10 – On Opposite Tacks\nRule 11 – On the Same Tack, Overlapped',
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Boats display (read-only summary — full edit would be complex)
                  if (incident.involvedBoats.isNotEmpty) ...[
                    Text('Boats Involved',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...incident.involvedBoats.map((b) => Text(
                          '${b.sailNumber} ${b.boatName} (${b.role.name})',
                          style: const TextStyle(fontSize: 12),
                        )),
                    const SizedBox(height: 4),
                    Text('To change boats, delete and re-create the incident.',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final locationEnum = _mapLocationToEnum(locationChoice);
                final rulesList = rulesCtrl.text
                    .split('\n')
                    .map((r) => r.trim())
                    .where((r) => r.isNotEmpty)
                    .toList();

                final updated = RaceIncident(
                  id: incident.id,
                  eventId: incident.eventId,
                  eventName: incident.eventName,
                  raceNumber: raceNumber,
                  reportedAt: incident.reportedAt,
                  reportedBy: reporterCtrl.text.trim(),
                  incidentTime: incident.incidentTime,
                  description: descCtrl.text.trim(),
                  locationOnCourse: locationEnum,
                  locationDetail: locationDetailCtrl.text.trim(),
                  courseName: incident.courseName,
                  involvedBoats: incident.involvedBoats,
                  rulesAlleged: rulesList,
                  status: incident.status,
                  hearing: incident.hearing,
                  resolution: incident.resolution,
                  penaltyApplied: incident.penaltyApplied,
                  witnesses: incident.witnesses,
                  attachments: incident.attachments,
                  comments: incident.comments,
                  weatherSnapshot: incident.weatherSnapshot,
                );
                await ref.read(incidentsRepositoryProvider).updateIncident(updated);
                ref.invalidate(incidentDetailProvider(incident.id));
                ref.invalidate(allIncidentsProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  static String _locationLabel(CourseLocationOnIncident loc) => switch (loc) {
        CourseLocationOnIncident.startLine => 'Start Line',
        CourseLocationOnIncident.windwardMark => 'Windward Mark',
        CourseLocationOnIncident.leewardMark => 'Leeward Mark',
        CourseLocationOnIncident.gate => 'Gate',
        CourseLocationOnIncident.reachingMark => 'Reaching Mark',
        CourseLocationOnIncident.openWater => 'Open Water',
      };

  static CourseLocationOnIncident _mapLocationToEnum(String loc) {
    final lower = loc.toLowerCase();
    if (lower.contains('start')) return CourseLocationOnIncident.startLine;
    if (lower.contains('windward')) return CourseLocationOnIncident.windwardMark;
    if (lower.contains('leeward')) return CourseLocationOnIncident.leewardMark;
    if (lower.contains('gate')) return CourseLocationOnIncident.gate;
    if (lower.contains('reaching')) return CourseLocationOnIncident.reachingMark;
    return CourseLocationOnIncident.openWater;
  }

  void _generateProtestForm(RaceIncident incident) {
    _showProtestFormDialog(incident);
  }

  void _openHtmlInNewTab(String htmlContent, String title) {
    openHtmlInNewTab(htmlContent, title);
  }

  void _showProtestFormDialog(RaceIncident incident, {ProtestFormData? prefill}) {
    String hearingType = prefill?.hearingType ?? 'protest';
    String informedHow = prefill?.informedHow ?? 'hail';
    bool flagDisplayed = prefill?.flagDisplayed ?? true;
    final hailWordsCtrl = TextEditingController(text: prefill?.hailWords ?? 'Protest!');
    final hailWhenCtrl = TextEditingController(text: prefill?.hailWhen ?? '');
    final flagTypeCtrl = TextEditingController(text: prefill?.flagType ?? 'Red flag');
    final flagWhenCtrl = TextEditingController(text: prefill?.flagWhen ?? '');
    final descCtrl = TextEditingController(
        text: prefill?.incidentDescription ?? incident.description);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Generate Hearing Request Form'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Type of Hearing',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _hearingTypeChip(hearingType, 'protest', 'Protest', setDialogState,
                          (v) => hearingType = v),
                      _hearingTypeChip(hearingType, 'redress', 'Redress', setDialogState,
                          (v) => hearingType = v),
                      _hearingTypeChip(hearingType, 'reopening', 'Reopen Hearing',
                          setDialogState, (v) => hearingType = v),
                      _hearingTypeChip(hearingType, 'ruleBreachByRC', 'RC Rule Breach',
                          setDialogState, (v) => hearingType = v),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('How was the Protestee Informed?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('By hailing'),
                        selected: informedHow == 'hail',
                        onSelected: (_) =>
                            setDialogState(() => informedHow = 'hail'),
                      ),
                      ChoiceChip(
                        label: const Text('Other'),
                        selected: informedHow == 'other',
                        onSelected: (_) =>
                            setDialogState(() => informedHow = 'other'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hailWordsCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Words of Hail'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: hailWhenCtrl,
                          decoration:
                              const InputDecoration(labelText: 'When Hailed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Red flag displayed'),
                    value: flagDisplayed,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) =>
                        setDialogState(() => flagDisplayed = v ?? true),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: flagTypeCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Flag Type'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: flagWhenCtrl,
                          decoration: const InputDecoration(
                              labelText: 'When Flag Displayed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Incident Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Describe what happened in detail...',
                    ),
                  ),
                  if (prefill != null &&
                      prefill.situationRules.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Text('Pre-filled from Situation Advisor',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.blue.shade700)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Encounter: ${prefill.situationEncounterType}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            ...prefill.situationRules.map((r) => Text(
                                  '• Rule $r',
                                  style: const TextStyle(fontSize: 11),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final formData = ProtestFormData(
                  hearingType: hearingType,
                  informedHow: informedHow,
                  hailWords: hailWordsCtrl.text.trim(),
                  hailWhen: hailWhenCtrl.text.trim(),
                  flagDisplayed: flagDisplayed,
                  flagType: flagTypeCtrl.text.trim(),
                  flagWhen: flagWhenCtrl.text.trim(),
                  incidentDescription: descCtrl.text.trim(),
                  situationEncounterType:
                      prefill?.situationEncounterType ?? '',
                  situationRules: prefill?.situationRules ?? [],
                  situationExplanations:
                      prefill?.situationExplanations ?? [],
                );
                const gen = ProtestFormGenerator();
                final htmlContent = gen.generateProtestFormHtml(
                  incident,
                  formData: formData,
                );
                _openHtmlInNewTab(htmlContent, 'Protest Form');
                Navigator.pop(dialogContext);
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Generate & Print'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hearingTypeChip(String current, String value, String label,
      StateSetter setState, ValueChanged<String> onChanged) {
    return ChoiceChip(
      label: Text(label),
      selected: current == value,
      onSelected: (_) => setState(() => onChanged(value)),
    );
  }

  void _generateDecision(RaceIncident incident) {
    const gen = ProtestFormGenerator();
    final htmlContent = gen.generateDecisionHtml(incident);
    _openHtmlInNewTab(htmlContent, 'Hearing Decision');
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
}
