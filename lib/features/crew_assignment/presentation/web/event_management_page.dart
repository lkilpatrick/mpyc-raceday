import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/crew_assignment_repository.dart';
import '../crew_assignment_formatters.dart';
import '../crew_assignment_providers.dart';
import 'event_detail_panel.dart';

class EventManagementPage extends ConsumerStatefulWidget {
  const EventManagementPage({super.key});

  @override
  ConsumerState<EventManagementPage> createState() =>
      _EventManagementPageState();
}

class _EventManagementPageState extends ConsumerState<EventManagementPage> {
  String _seriesFilter = 'All';
  EventStatus? _statusFilter;
  DateTimeRange? _range;
  String _crewMemberFilter = '';
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DropdownButton<String>(
              value: _seriesFilter,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Series')),
                DropdownMenuItem(
                  value: 'Spring Series',
                  child: Text('Spring Series'),
                ),
                DropdownMenuItem(
                  value: 'Summer Series',
                  child: Text('Summer Series'),
                ),
              ],
              onChanged: (v) => setState(() => _seriesFilter = v ?? 'All'),
            ),
            DropdownButton<EventStatus?>(
              value: _statusFilter,
              hint: const Text('Status'),
              items: [
                const DropdownMenuItem<EventStatus?>(
                  value: null,
                  child: Text('Any Status'),
                ),
                ...EventStatus.values.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(eventStatusLabel(s)),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _statusFilter = v),
            ),
            OutlinedButton(
              onPressed: _pickRange,
              child: Text(
                _range == null
                    ? 'Date range'
                    : '${DateFormat.Md().format(_range!.start)} - ${DateFormat.Md().format(_range!.end)}',
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Assigned crew member',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) =>
                    setState(() => _crewMemberFilter = value.trim()),
              ),
            ),
            FilledButton(
              onPressed: _selectedIds.isEmpty ? null : _cancelSelected,
              child: const Text('Cancel Selected'),
            ),
            OutlinedButton(
              onPressed: _selectedIds.isEmpty ? null : _reassignSelected,
              child: const Text('Reassign Crew'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: eventsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (events) {
              final filtered = events.where(_matchesFilter).toList();
              return DataTable2(
                columns: const [
                  DataColumn2(label: Text('Date')),
                  DataColumn2(size: ColumnSize.L, label: Text('Event')),
                  DataColumn2(label: Text('Series')),
                  DataColumn2(label: Text('Status')),
                  DataColumn2(label: Text('PRO')),
                  DataColumn2(label: Text('Crew Count')),
                  DataColumn2(label: Text('Confirmations')),
                ],
                rows: filtered.map((event) {
                  final pro = event.crewSlots
                      .where((s) => s.role == CrewRole.pro)
                      .firstOrNull;
                  final selected = _selectedIds.contains(event.id);
                  return DataRow2(
                    selected: selected,
                    onSelectChanged: (_) => setState(() {
                      if (selected) {
                        _selectedIds.remove(event.id);
                      } else {
                        _selectedIds.add(event.id);
                      }
                    }),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => EventDetailPanel(eventId: event.id),
                    ),
                    cells: [
                      DataCell(Text(DateFormat.yMMMd().format(event.date))),
                      DataCell(Text(event.name)),
                      DataCell(Text(event.seriesName)),
                      DataCell(Text(eventStatusLabel(event.status))),
                      DataCell(Text(pro?.memberName ?? 'Unassigned')),
                      DataCell(
                        Text(
                          '${event.crewSlots.where((s) => s.memberName != null).length}/${event.crewSlots.length}',
                        ),
                      ),
                      DataCell(
                        Text(
                          '${event.confirmedCount}/${event.crewSlots.length}',
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _matchesFilter(RaceEvent event) {
    if (_seriesFilter != 'All' && event.seriesName != _seriesFilter)
      return false;
    if (_statusFilter != null && event.status != _statusFilter) return false;
    if (_range != null &&
        (event.date.isBefore(_range!.start) ||
            event.date.isAfter(_range!.end))) {
      return false;
    }
    if (_crewMemberFilter.isNotEmpty) {
      final hasMember = event.crewSlots.any(
        (slot) => (slot.memberName ?? '').toLowerCase().contains(
          _crewMemberFilter.toLowerCase(),
        ),
      );
      if (!hasMember) return false;
    }
    return true;
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _range,
    );
    if (range != null) setState(() => _range = range);
  }

  Future<void> _cancelSelected() async {
    await ref
        .read(crewAssignmentRepositoryProvider)
        .bulkCancelEvents(_selectedIds.toList());
    setState(_selectedIds.clear);
  }

  Future<void> _reassignSelected() async {
    final events = ref
        .read(upcomingEventsProvider)
        .maybeWhen(data: (items) => items, orElse: () => <RaceEvent>[]);
    for (final id in _selectedIds) {
      final event = events.where((e) => e.id == id).firstOrNull;
      if (event == null) continue;
      final suggestions = await ref
          .read(crewAssignmentRepositoryProvider)
          .suggestFairAssignments(id);
      final updated = event.crewSlots.asMap().entries.map((entry) {
        final name = suggestions.isNotEmpty
            ? suggestions[entry.key % suggestions.length]
            : null;
        return entry.value.copyWith(
          memberName: name,
          memberId: name == null ? null : 'user_${name.hashCode.abs()}',
        );
      }).toList();
      await ref
          .read(crewAssignmentRepositoryProvider)
          .updateCrewSlots(id, updated);
    }
    setState(_selectedIds.clear);
  }
}
