import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/crew_assignment_repository.dart';
import '../crew_assignment_formatters.dart';
import '../crew_assignment_providers.dart';

class EventDetailPanel extends ConsumerStatefulWidget {
  const EventDetailPanel({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailPanel> createState() => _EventDetailPanelState();
}

class _EventDetailPanelState extends ConsumerState<EventDetailPanel> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(eventDetailProvider(widget.eventId));

    return SizedBox(
      width: 720,
      child: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) {
          final event = detail.event;
          _notesController.text = event.notes ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(event.seriesName)),
                    Chip(label: Text(eventStatusLabel(event.status))),
                    Chip(
                      label: Text(
                        '${event.date.month}/${event.date.day}/${event.date.year}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Crew Assignment',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...event.crewSlots.map((slot) => _slotTile(event, slot)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _autoAssign(event),
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Auto-assign'),
                    ),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(crewAssignmentRepositoryProvider)
                          .notifyCrew(
                            eventId: event.id,
                            onlyUnconfirmed: false,
                          ),
                      child: const Text('Notify All'),
                    ),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(crewAssignmentRepositoryProvider)
                          .notifyCrew(eventId: event.id, onlyUnconfirmed: true),
                      child: const Text('Notify Unconfirmed'),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'Linked Data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Course: ${detail.courseName ?? 'Not selected'}'),
                Text('Weather: ${detail.weatherSummary ?? 'No log'}'),
                Text('Incidents: ${detail.incidentCount}'),
                Text('Checklists completed: ${detail.completedChecklists}'),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'PRO instructions / notes',
                  ),
                  onSubmitted: (value) => ref
                      .read(crewAssignmentRepositoryProvider)
                      .saveEvent(event.copyWith(notes: value)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _slotTile(RaceEvent event, CrewSlot slot) {
    return Card(
      child: ListTile(
        leading: Draggable<CrewSlot>(
          data: slot,
          feedback: Material(child: Chip(label: Text(roleLabel(slot.role)))),
          child: const Icon(Icons.drag_indicator),
        ),
        title: Text(roleLabel(slot.role)),
        subtitle: Text(slot.memberName ?? 'Unassigned'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor(slot.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 180,
              child: DragTarget<CrewSlot>(
                onAcceptWithDetails: (dragged) =>
                    _swapRoles(event, slot, dragged.data),
                builder: (_, __, ___) => DropdownButtonFormField<String>(
                  value: slot.memberName,
                  hint: const Text('Assign member'),
                  items:
                      const [
                            'Alex PRO',
                            'Sam Signal',
                            'Morgan Mark',
                            'Taylor Safety',
                            'Jordan Mark',
                            'Casey Safety',
                          ]
                          .map(
                            (name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => _assignMember(event, slot.role, value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignMember(
    RaceEvent event,
    CrewRole role,
    String? memberName,
  ) async {
    if (memberName == null) return;
    final slots = event.crewSlots
        .map(
          (s) => s.role == role
              ? s.copyWith(
                  memberName: memberName,
                  memberId: 'user_${memberName.hashCode.abs()}',
                )
              : s,
        )
        .toList();
    await ref
        .read(crewAssignmentRepositoryProvider)
        .updateCrewSlots(event.id, slots);
  }

  Future<void> _swapRoles(
    RaceEvent event,
    CrewSlot target,
    CrewSlot dragged,
  ) async {
    final targetSlot = event.crewSlots.firstWhere((s) => s.role == target.role);
    final draggedSlot = event.crewSlots.firstWhere(
      (s) => s.role == dragged.role,
    );

    final updated = event.crewSlots.map((slot) {
      if (slot.role == target.role) {
        return slot.copyWith(
          memberId: draggedSlot.memberId,
          memberName: draggedSlot.memberName,
        );
      }
      if (slot.role == dragged.role) {
        return slot.copyWith(
          memberId: targetSlot.memberId,
          memberName: targetSlot.memberName,
        );
      }
      return slot;
    }).toList();

    await ref
        .read(crewAssignmentRepositoryProvider)
        .updateCrewSlots(event.id, updated);
  }

  Future<void> _autoAssign(RaceEvent event) async {
    final suggestions = await ref
        .read(crewAssignmentRepositoryProvider)
        .suggestFairAssignments(event.id);
    final slots = event.crewSlots.asMap().entries.map((entry) {
      final name = suggestions.isNotEmpty
          ? suggestions[entry.key % suggestions.length]
          : 'Unassigned';
      return entry.value.copyWith(
        memberName: name,
        memberId: 'user_${name.hashCode.abs()}',
      );
    }).toList();
    await ref
        .read(crewAssignmentRepositoryProvider)
        .updateCrewSlots(event.id, slots);
  }
}
