import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/race_incident.dart';
import '../incidents_providers.dart';
import 'incident_detail_panel.dart';

class IncidentManagementPage extends ConsumerStatefulWidget {
  const IncidentManagementPage({super.key});

  @override
  ConsumerState<IncidentManagementPage> createState() =>
      _IncidentManagementPageState();
}

class _IncidentManagementPageState
    extends ConsumerState<IncidentManagementPage> {
  String _statusFilter = 'all';
  String _searchQuery = '';
  String? _selectedIncidentId;

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(allIncidentsProvider);

    return Row(
      children: [
        // Main table
        Expanded(
          flex: _selectedIncidentId != null ? 3 : 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Text('Incident Management',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const Spacer(),
                  ],
                ),
              ),
              // Filters
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _statusFilter,
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Statuses')),
                        DropdownMenuItem(
                            value: 'reported', child: Text('Reported')),
                        DropdownMenuItem(
                            value: 'protestFiled',
                            child: Text('Protest Filed')),
                        DropdownMenuItem(
                            value: 'hearingScheduled',
                            child: Text('Hearing Scheduled')),
                        DropdownMenuItem(
                            value: 'hearingComplete',
                            child: Text('Hearing Complete')),
                        DropdownMenuItem(
                            value: 'resolved', child: Text('Resolved')),
                        DropdownMenuItem(
                            value: 'withdrawn', child: Text('Withdrawn')),
                      ],
                      onChanged: (v) =>
                          setState(() => _statusFilter = v ?? 'all'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: incidentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (incidents) {
                    var filtered = incidents;
                    if (_statusFilter != 'all') {
                      filtered = filtered
                          .where((i) => i.status.name == _statusFilter)
                          .toList();
                    }
                    if (_searchQuery.isNotEmpty) {
                      filtered = filtered
                          .where((i) =>
                              i.description
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              i.involvedBoats.any((b) =>
                                  b.sailNumber
                                      .toLowerCase()
                                      .contains(_searchQuery) ||
                                  b.boatName
                                      .toLowerCase()
                                      .contains(_searchQuery)))
                          .toList();
                    }

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No incidents found'));
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Event')),
                            DataColumn(label: Text('Race')),
                            DataColumn(label: Text('Time')),
                            DataColumn(label: Text('Boats')),
                            DataColumn(label: Text('Rules')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Reporter')),
                          ],
                          rows: filtered.map((inc) {
                            final boats = inc.involvedBoats
                                .map((b) => b.sailNumber)
                                .join(' vs ');
                            final rules = inc.rulesAlleged
                                .map((r) => r.split(' – ').first)
                                .join(', ');
                            final (statusLabel, statusColor) =
                                _statusInfo(inc.status);

                            return DataRow(
                              selected:
                                  _selectedIncidentId == inc.id,
                              onSelectChanged: (_) => setState(
                                  () => _selectedIncidentId = inc.id),
                              cells: [
                                DataCell(Text(
                                    inc.id.length > 6
                                        ? inc.id.substring(0, 6)
                                        : inc.id,
                                    style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12))),
                                DataCell(Text(
                                    inc.eventId.length > 8
                                        ? inc.eventId.substring(0, 8)
                                        : inc.eventId,
                                    style: const TextStyle(fontSize: 12))),
                                DataCell(Text('${inc.raceNumber}')),
                                DataCell(Text(DateFormat.Hm()
                                    .format(inc.incidentTime))),
                                DataCell(SizedBox(
                                  width: 150,
                                  child: Text(boats,
                                      overflow: TextOverflow.ellipsis),
                                )),
                                DataCell(SizedBox(
                                  width: 100,
                                  child: Text(rules,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          const TextStyle(fontSize: 11)),
                                )),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(statusLabel,
                                      style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                )),
                                DataCell(Text(inc.reportedBy,
                                    style: const TextStyle(fontSize: 12))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Detail panel (slide-out)
        if (_selectedIncidentId != null)
          SizedBox(
            width: 480,
            child: IncidentDetailPanel(
              incidentId: _selectedIncidentId!,
              onClose: () =>
                  setState(() => _selectedIncidentId = null),
            ),
          ),
      ],
    );
  }

  (String, Color) _statusInfo(RaceIncidentStatus status) => switch (status) {
        RaceIncidentStatus.reported => ('Reported', Colors.orange),
        RaceIncidentStatus.protestFiled => ('Protest Filed', Colors.red),
        RaceIncidentStatus.hearingScheduled =>
          ('Hearing Sched.', Colors.purple),
        RaceIncidentStatus.hearingComplete =>
          ('Hearing Done', Colors.blue),
        RaceIncidentStatus.resolved => ('Resolved', Colors.green),
        RaceIncidentStatus.withdrawn => ('Withdrawn', Colors.grey),
      };
}
