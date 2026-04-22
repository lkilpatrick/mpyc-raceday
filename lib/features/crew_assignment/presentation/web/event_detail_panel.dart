import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../boat_checkin/presentation/boat_checkin_providers.dart';
import '../../../rc_race/data/models/race_session.dart';
import '../../../rc_race/presentation/rc_race_providers.dart';
import '../../../timing/data/models/timing_models.dart';
import '../../../timing/presentation/timing_providers.dart';
import '../../domain/crew_assignment_repository.dart';
import '../crew_assignment_formatters.dart';
import '../crew_assignment_providers.dart';

class EventDetailPanel extends ConsumerStatefulWidget {
  const EventDetailPanel({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailPanel> createState() => _EventDetailPanelState();
}

class _EventDetailPanelState extends ConsumerState<EventDetailPanel>
    with SingleTickerProviderStateMixin {
  final _notesController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tabController.dispose();
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

          return SizedBox(
            height: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    ],
                  ),
                ),

                // ── Tabs ──
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.people, size: 18),
                      text: 'Crew & Notes',
                    ),
                    Tab(icon: Icon(Icons.sailing, size: 18), text: 'Race Data'),
                  ],
                ),

                // ── Tab content ──
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCrewTab(event),
                      _buildRaceDataTab(widget.eventId),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Tab 1 — Crew & Notes
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildCrewTab(RaceEvent event) {
    final detailAsync2 = ref.watch(eventDetailProvider(widget.eventId));
    final detail = switch (detailAsync2) {
      AsyncData(:final value) => value,
      _ => null,
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    .notifyCrew(eventId: event.id, onlyUnconfirmed: false),
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
          Text('Linked Data', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Course: ${detail?.courseName ?? 'Not selected'}'),
          Text('Weather: ${detail?.weatherSummary ?? 'No log'}'),
          Text('Incidents: ${detail?.incidentCount ?? 0}'),
          Text('Checklists completed: ${detail?.completedChecklists ?? 0}'),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'PRO instructions / notes',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => ref
                .read(crewAssignmentRepositoryProvider)
                .saveEvent(event.copyWith(notes: value)),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Tab 2 — Race Data
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildRaceDataTab(String eventId) {
    final sessionAsync = ref.watch(sessionByIdProvider(eventId));
    final checkinsAsync = ref.watch(eventCheckinsProvider(eventId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Race Session Status ──
          Text('Race Session', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          sessionAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              'Error loading session: $e',
              style: const TextStyle(color: Colors.red),
            ),
            data: (session) => session == null
                ? const Text(
                    'No race session found for this event.',
                    style: TextStyle(color: Colors.grey),
                  )
                : _buildSessionCard(session),
          ),

          const SizedBox(height: 20),

          // ── Fleet Check-ins ──
          Text(
            'Fleet Check-ins',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          checkinsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              'Error loading check-ins: $e',
              style: const TextStyle(color: Colors.red),
            ),
            data: (checkins) => checkins.isEmpty
                ? const Text(
                    'No boats checked in yet.',
                    style: TextStyle(color: Colors.grey),
                  )
                : _buildCheckinTable(checkins),
          ),

          // ── Finish Results ──
          const SizedBox(height: 20),
          Builder(
            builder: (context) {
              final session = switch (sessionAsync) {
                AsyncData(:final value) => value,
                _ => null,
              };
              final raceStartId = session?.raceStartId;
              if (raceStartId == null || raceStartId.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finish Results',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Race has not started yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                );
              }
              return _buildFinishResults(raceStartId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(RaceSession session) {
    final statusColor = _statusColor(session.status);
    final fmt = DateFormat('h:mm a');
    final fmtDate = DateFormat('MMM d, yyyy h:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(session.status),
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        session.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (session.clubspotReady) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text(
                      'ClubSpot Ready',
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Color(0xFFE8F5E9),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Details grid
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                if (session.startTime != null)
                  _infoChip(
                    Icons.timer,
                    'Started ${fmt.format(session.startTime!)}',
                  ),
                if (session.startMethod != null)
                  _infoChip(Icons.campaign, 'Start: ${session.startMethod}'),
                if (session.courseName != null)
                  _infoChip(Icons.map, session.courseName!),
                if (session.fleetClass != null)
                  _infoChip(Icons.directions_boat, session.fleetClass!),
                if (session.raceNumber > 1)
                  _infoChip(Icons.looks_one, 'Race #${session.raceNumber}'),
              ],
            ),

            if (session.status == RaceSessionStatus.abandoned &&
                session.abandonedReason != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Abandoned: ${session.abandonedReason}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (session.finalizedAt != null) ...[
              const SizedBox(height: 8),
              _infoChip(
                Icons.check_circle,
                'Finalized ${fmtDate.format(session.finalizedAt!)}',
                color: Colors.green,
              ),
            ],

            // Fleet courses (multi-fleet)
            if (session.fleetCourses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Fleet Courses',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              ...session.fleetCourses.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${e.key}: ${e.value['courseName'] ?? '—'} '
                    '(${e.value['courseNumber'] ?? '—'})',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],

            // ── Reset Race button ──
            if (session.status != RaceSessionStatus.setup) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmResetRace(session),
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Reset Race to Setup'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckinTable(List checkins) {
    final fmt = DateFormat('h:mm a');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${checkins.length} boat${checkins.length == 1 ? '' : 's'} checked in',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            headingRowHeight: 36,
            dataRowMinHeight: 32,
            dataRowMaxHeight: 44,
            columns: const [
              DataColumn(label: Text('Sail')),
              DataColumn(label: Text('Boat')),
              DataColumn(label: Text('Skipper')),
              DataColumn(label: Text('Class')),
              DataColumn(label: Text('PHRF'), numeric: true),
              DataColumn(label: Text('Checked in')),
            ],
            rows: checkins
                .map(
                  (c) => DataRow(
                    cells: [
                      DataCell(
                        Text(
                          c.sailNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(c.boatName)),
                      DataCell(Text(c.skipperName)),
                      DataCell(Text(c.boatClass)),
                      DataCell(Text(c.phrfRating?.toString() ?? '—')),
                      DataCell(Text(fmt.format(c.checkedInAt))),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishResults(String raceStartId) {
    final recordsAsync = ref.watch(finishRecordsProvider(raceStartId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Finish Results', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        recordsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (records) {
            if (records.isEmpty) {
              return const Text(
                'No finish records yet.',
                style: TextStyle(color: Colors.grey),
              );
            }
            final sorted = [...records]
              ..sort((a, b) => a.position.compareTo(b.position));
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 44,
                columns: const [
                  DataColumn(label: Text('Pos'), numeric: true),
                  DataColumn(label: Text('Sail')),
                  DataColumn(label: Text('Boat')),
                  DataColumn(label: Text('Elapsed')),
                  DataColumn(label: Text('Corrected')),
                  DataColumn(label: Text('Score')),
                ],
                rows: sorted
                    .map(
                      (r) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              r.letterScore == LetterScore.finished
                                  ? '${r.position}'
                                  : '—',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text(r.sailNumber)),
                          DataCell(Text(r.boatName)),
                          DataCell(Text(_formatElapsed(r.elapsedSeconds))),
                          DataCell(
                            Text(
                              r.correctedSeconds != null
                                  ? _formatElapsed(r.correctedSeconds!)
                                  : '—',
                            ),
                          ),
                          DataCell(
                            Text(
                              r.letterScore == LetterScore.finished
                                  ? '${r.position}'
                                  : r.letterScore.name.toUpperCase(),
                              style: TextStyle(
                                color: r.letterScore == LetterScore.finished
                                    ? null
                                    : Colors.orange.shade800,
                                fontWeight:
                                    r.letterScore != LetterScore.finished
                                    ? FontWeight.bold
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Helpers ──

  Widget _infoChip(
    IconData icon,
    String label, {
    Color color = Colors.black87,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }

  String _formatElapsed(double seconds) {
    final s = seconds.truncate();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${sec.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${sec.toString().padLeft(2, '0')}s';
  }

  Color _statusColor(RaceSessionStatus status) => switch (status) {
    RaceSessionStatus.setup => Colors.grey,
    RaceSessionStatus.checkinOpen => Colors.blue,
    RaceSessionStatus.startPending => Colors.orange,
    RaceSessionStatus.running => Colors.green,
    RaceSessionStatus.scoring => Colors.indigo,
    RaceSessionStatus.review => Colors.purple,
    RaceSessionStatus.finalized => Colors.green.shade700,
    RaceSessionStatus.abandoned => Colors.red,
  };

  IconData _statusIcon(RaceSessionStatus status) => switch (status) {
    RaceSessionStatus.setup => Icons.settings,
    RaceSessionStatus.checkinOpen => Icons.how_to_reg,
    RaceSessionStatus.startPending => Icons.hourglass_top,
    RaceSessionStatus.running => Icons.sailing,
    RaceSessionStatus.scoring => Icons.sports_score,
    RaceSessionStatus.review => Icons.rate_review,
    RaceSessionStatus.finalized => Icons.check_circle,
    RaceSessionStatus.abandoned => Icons.cancel,
  };

  Future<void> _confirmResetRace(RaceSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Race to Setup?'),
        content: Text(
          'This will clear the race start time, start method, and return '
          '"${session.name}" to Setup status.\n\n'
          'Check-ins and crew assignments are kept. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset Race'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await ref.read(rcRaceRepositoryProvider).resetRace(session.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Race reset to Setup')));
    }
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
                  initialValue: slot.memberName,
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
