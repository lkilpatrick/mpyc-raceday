import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../boat_checkin/data/models/boat.dart';
import '../../../boat_checkin/presentation/boat_checkin_providers.dart';
import '../../../courses/data/models/course_config.dart';
import '../../../courses/presentation/courses_providers.dart';
import '../../../crew_assignment/domain/crew_assignment_repository.dart';
import '../../../crew_assignment/presentation/crew_assignment_providers.dart';
import '../../../weather/data/models/live_weather.dart';
import '../../../weather/presentation/live_weather_providers.dart';
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

  // Sorting state
  int _sortColumnIndex = 0;
  bool _sortAscending = false; // default: newest first

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
                    FilledButton.icon(
                      onPressed: _showCreateDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Report Incident'),
                    ),
                    const SizedBox(width: 8),
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
                      final q = _searchQuery;
                      filtered = filtered
                          .where((i) =>
                              i.description.toLowerCase().contains(q) ||
                              i.eventName.toLowerCase().contains(q) ||
                              i.reportedBy.toLowerCase().contains(q) ||
                              i.courseName.toLowerCase().contains(q) ||
                              i.locationDetail.toLowerCase().contains(q) ||
                              i.rulesAlleged.any((r) => r.toLowerCase().contains(q)) ||
                              i.involvedBoats.any((b) =>
                                  b.sailNumber.toLowerCase().contains(q) ||
                                  b.boatName.toLowerCase().contains(q) ||
                                  b.skipperName.toLowerCase().contains(q)))
                          .toList();
                    }

                    // Apply sorting
                    filtered = _applySorting(filtered);

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            const Text('No incidents found',
                                style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          showCheckboxColumn: false,
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                          columns: [
                            DataColumn(
                              label: const Text('Date',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (i, asc) => _onSort(i, asc),
                            ),
                            DataColumn(
                              label: const Text('Event',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (i, asc) => _onSort(i, asc),
                            ),
                            DataColumn(
                              label: const Text('Description',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (i, asc) => _onSort(i, asc),
                            ),
                            DataColumn(
                              label: const Text('Race',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              numeric: true,
                              onSort: (i, asc) => _onSort(i, asc),
                            ),
                            DataColumn(
                              label: const Text('Boats',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (i, asc) => _onSort(i, asc),
                            ),
                            DataColumn(
                              label: const Text('Rules',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (i, asc) => _onSort(i, asc),
                            ),
                            DataColumn(
                              label: const Text('Status',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (i, asc) => _onSort(i, asc),
                            ),
                            DataColumn(
                              label: const Text('Reporter',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (i, asc) => _onSort(i, asc),
                            ),
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
                            final descPreview = inc.description.length > 50
                                ? '${inc.description.substring(0, 50)}…'
                                : inc.description;

                            return DataRow(
                              selected:
                                  _selectedIncidentId == inc.id,
                              onSelectChanged: (_) => setState(
                                  () => _selectedIncidentId = inc.id),
                              cells: [
                                DataCell(Text(
                                    DateFormat('MMM d, yyyy\nh:mm a')
                                        .format(inc.reportedAt),
                                    style: const TextStyle(fontSize: 12))),
                                DataCell(Text(
                                    inc.eventName.isNotEmpty
                                        ? inc.eventName
                                        : inc.eventId.length > 8
                                            ? inc.eventId.substring(0, 8)
                                            : inc.eventId,
                                    style: const TextStyle(fontSize: 12))),
                                DataCell(SizedBox(
                                  width: 200,
                                  child: Tooltip(
                                    message: inc.description,
                                    child: Text(descPreview,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                )),
                                DataCell(Text('${inc.raceNumber}',
                                    style: const TextStyle(fontSize: 12))),
                                DataCell(SizedBox(
                                  width: 140,
                                  child: Tooltip(
                                    message: inc.involvedBoats
                                        .map((b) => '${b.sailNumber} ${b.boatName}')
                                        .join(', '),
                                    child: Text(boats,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                )),
                                DataCell(SizedBox(
                                  width: 100,
                                  child: Tooltip(
                                    message: inc.rulesAlleged.join('\n'),
                                    child: Text(rules,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11)),
                                  ),
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
            child: Column(
              children: [
                Expanded(
                  child: IncidentDetailPanel(
                    incidentId: _selectedIncidentId!,
                    onClose: () =>
                        setState(() => _selectedIncidentId = null),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteIncident(_selectedIncidentId!),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                    label: const Text('Delete Incident',
                        style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _deleteIncident(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Incident'),
        content: const Text(
            'Are you sure you want to delete this incident? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(incidentsRepositoryProvider).deleteIncident(id);
    setState(() => _selectedIncidentId = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident deleted')),
      );
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _ReportIncidentDialog(ref: ref),
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  List<RaceIncident> _applySorting(List<RaceIncident> list) {
    final sorted = [...list];
    final asc = _sortAscending;
    sorted.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0: // Date
          cmp = a.reportedAt.compareTo(b.reportedAt);
        case 1: // Event
          cmp = a.eventName.toLowerCase().compareTo(b.eventName.toLowerCase());
        case 2: // Description
          cmp = a.description.toLowerCase().compareTo(b.description.toLowerCase());
        case 3: // Race
          cmp = a.raceNumber.compareTo(b.raceNumber);
        case 4: // Boats
          final aBoats = a.involvedBoats.map((b) => b.sailNumber).join();
          final bBoats = b.involvedBoats.map((b) => b.sailNumber).join();
          cmp = aBoats.compareTo(bBoats);
        case 5: // Rules
          cmp = a.rulesAlleged.join().compareTo(b.rulesAlleged.join());
        case 6: // Status
          cmp = a.status.name.compareTo(b.status.name);
        case 7: // Reporter
          cmp = a.reportedBy.toLowerCase().compareTo(b.reportedBy.toLowerCase());
        default:
          cmp = 0;
      }
      return asc ? cmp : -cmp;
    });
    return sorted;
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

// ═══════════════════════════════════════════════════════════════════
// Report Incident Dialog — smart dropdowns, weather, course marks
// ═══════════════════════════════════════════════════════════════════

class _ReportIncidentDialog extends StatefulWidget {
  const _ReportIncidentDialog({required this.ref});
  final WidgetRef ref;

  @override
  State<_ReportIncidentDialog> createState() => _ReportIncidentDialogState();
}

class _ReportIncidentDialogState extends State<_ReportIncidentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();

  // Event
  RaceEvent? _selectedEvent;
  int _raceNumber = 1;

  // Course
  CourseConfig? _selectedCourse;
  bool _isOtherCourse = false;
  final _otherCourseCtrl = TextEditingController();

  // Location
  String _locationChoice = 'Open Water';

  // Boats
  final List<_BoatEntry> _boats = [_BoatEntry()];

  // Weather (auto-populated)
  LiveWeather? _weather;

  @override
  void initState() {
    super.initState();
    // Pre-select the latest upcoming event
    final events = widget.ref.read(upcomingEventsProvider).value ?? [];
    if (events.isNotEmpty) {
      _selectedEvent = events.first;
    }
    // Grab current weather
    _weather = widget.ref.read(liveWeatherProvider).value;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _otherCourseCtrl.dispose();
    for (final b in _boats) {
      b.dispose();
    }
    super.dispose();
  }

  List<String> _locationChoicesForCourse(CourseConfig? course) {
    if (course == null) {
      return ['Start Line', 'Windward Mark', 'Leeward Mark', 'Gate', 'Reaching Mark', 'Open Water'];
    }
    final locations = <String>{'Start Line'};
    for (final m in course.marks) {
      if (m.isStart) continue;
      if (m.isFinish) {
        locations.add('Finish Line');
      } else {
        locations.add('Near Mark ${m.markName}');
      }
    }
    locations.addAll(['Between Marks', 'Open Water']);
    return locations.toList();
  }

  CourseLocationOnIncident _mapLocationToEnum(String loc) {
    final lower = loc.toLowerCase();
    if (lower.contains('start')) return CourseLocationOnIncident.startLine;
    if (lower.contains('windward')) return CourseLocationOnIncident.windwardMark;
    if (lower.contains('leeward')) return CourseLocationOnIncident.leewardMark;
    if (lower.contains('gate')) return CourseLocationOnIncident.gate;
    if (lower.contains('reaching')) return CourseLocationOnIncident.reachingMark;
    return CourseLocationOnIncident.openWater;
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.ref.watch(upcomingEventsProvider).value ?? [];
    final courses = widget.ref.watch(allCoursesProvider).value ?? [];
    final fleet = widget.ref.watch(fleetProvider).value ?? [];
    final locationChoices = _locationChoicesForCourse(_selectedCourse);

    // Ensure current location choice is valid
    if (!locationChoices.contains(_locationChoice)) {
      _locationChoice = locationChoices.last;
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.report, color: Colors.orange.shade700, size: 28),
          const SizedBox(width: 10),
          const Text('Report Incident',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Event & Race ──
                _sectionHeader('Event & Race'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<RaceEvent>(
                        value: _selectedEvent,
                        decoration: const InputDecoration(
                          labelText: 'Race Event',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        items: events.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            '${e.name} — ${DateFormat.MMMd().format(e.date)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedEvent = v),
                        validator: (v) => v == null ? 'Select an event' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int>(
                        value: _raceNumber,
                        decoration: const InputDecoration(
                          labelText: 'Race #',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        items: List.generate(10, (i) => i + 1)
                            .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                            .toList(),
                        onChanged: (v) => setState(() => _raceNumber = v ?? 1),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Course & Location ──
                _sectionHeader('Course & Location'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _isOtherCourse
                            ? '__other__'
                            : _selectedCourse?.id,
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        items: [
                          ...courses.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.courseNumber} — ${c.courseName}',
                                overflow: TextOverflow.ellipsis),
                          )),
                          const DropdownMenuItem(
                            value: '__other__',
                            child: Text('Other (describe)'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            if (v == '__other__') {
                              _isOtherCourse = true;
                              _selectedCourse = null;
                            } else {
                              _isOtherCourse = false;
                              _selectedCourse = courses.firstWhere((c) => c.id == v);
                            }
                            // Reset location to first valid choice
                            final newChoices = _locationChoicesForCourse(_selectedCourse);
                            _locationChoice = newChoices.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _locationChoice,
                        decoration: const InputDecoration(
                          labelText: 'Location on Course',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        items: locationChoices
                            .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: (v) => setState(() => _locationChoice = v ?? _locationChoice),
                      ),
                    ),
                  ],
                ),
                if (_isOtherCourse) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _otherCourseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Describe course',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Boats Involved ──
                _sectionHeader('Boats Involved'),
                const SizedBox(height: 8),
                ..._boats.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final boat = entry.value;
                  return _buildBoatRow(idx, boat, fleet);
                }),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () => setState(() => _boats.add(_BoatEntry())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Boat', style: TextStyle(fontSize: 13)),
                ),

                const SizedBox(height: 20),

                // ── Description ──
                _sectionHeader('Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe what happened...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(14),
                  ),
                  style: const TextStyle(fontSize: 14),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                ),

                const SizedBox(height: 20),

                // ── Weather Conditions (auto-populated) ──
                if (_weather != null) _buildWeatherBanner(),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontSize: 14)),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Report Incident', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade700,
          letterSpacing: 0.5,
        ));
  }

  Widget _buildBoatRow(int idx, _BoatEntry boat, List<Boat> fleet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Boat autocomplete
          Expanded(
            flex: 3,
            child: Autocomplete<Boat>(
              displayStringForOption: (b) => '${b.sailNumber} — ${b.boatName}',
              optionsBuilder: (textEditingValue) {
                final q = textEditingValue.text.toLowerCase();
                if (q.isEmpty) return fleet.take(10);
                return fleet.where((b) =>
                    b.sailNumber.toLowerCase().contains(q) ||
                    b.boatName.toLowerCase().contains(q) ||
                    b.ownerName.toLowerCase().contains(q));
              },
              onSelected: (b) {
                setState(() {
                  boat.sailCtrl.text = b.sailNumber;
                  boat.nameCtrl.text = b.boatName;
                  boat.skipperCtrl.text = b.ownerName;
                  boat.boatClass = b.boatClass;
                  boat.boatId = b.id;
                });
              },
              fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
                // Sync the autocomplete controller with our boat entry
                if (ctrl.text.isEmpty && boat.sailCtrl.text.isNotEmpty) {
                  ctrl.text = '${boat.sailCtrl.text} — ${boat.nameCtrl.text}';
                }
                return TextFormField(
                  controller: ctrl,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Boat (sail # or name)',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        ctrl.clear();
                        boat.clear();
                        setState(() {});
                      },
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Skipper
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: boat.skipperCtrl,
              decoration: const InputDecoration(
                labelText: 'Skipper',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          // Role
          SizedBox(
            width: 100,
            child: SegmentedButton<BoatInvolvedRole>(
              segments: const [
                ButtonSegment(value: BoatInvolvedRole.protesting, label: Text('P', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: BoatInvolvedRole.protested, label: Text('D', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: BoatInvolvedRole.witness, label: Text('W', style: TextStyle(fontSize: 12))),
              ],
              selected: {boat.role},
              onSelectionChanged: (v) => setState(() => boat.role = v.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
          // Remove
          if (_boats.length > 1)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() {
                _boats[idx].dispose();
                _boats.removeAt(idx);
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherBanner() {
    final w = _weather!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text('Weather at Time of Incident',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  )),
              const Spacer(),
              Text('Auto-captured',
                  style: TextStyle(fontSize: 10, color: Colors.blue.shade400)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 20,
            runSpacing: 4,
            children: [
              _weatherChip('Wind', '${w.windDirectionLabel} ${w.speedKts.round()} kts'
                  '${w.gustKts != null ? " G${w.gustKts!.round()}" : ""}'),
              _weatherChip('Dir', '${w.dirDeg}°'),
              if (w.tempF != null) _weatherChip('Temp', '${w.tempF!.round()}°F'),
              if (w.humidity != null) _weatherChip('Humidity', '${w.humidity!.round()}%'),
              if (w.pressureInHg != null) _weatherChip('Pressure', '${w.pressureInHg!.toStringAsFixed(2)} inHg'),
              _weatherChip('Station', w.station.name),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weatherChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final w = _weather;

    WeatherSnapshot? weatherSnap;
    if (w != null) {
      weatherSnap = WeatherSnapshot(
        windSpeedKts: w.speedKts,
        windSpeedMph: w.speedMph,
        windDirDeg: w.dirDeg,
        windDirLabel: w.windDirectionLabel,
        gustKts: w.gustKts,
        tempF: w.tempF,
        humidity: w.humidity?.toDouble(),
        pressureInHg: w.pressureInHg,
        source: w.source,
        stationName: w.station.name,
      );
    }

    final involvedBoats = _boats
        .where((b) => b.sailCtrl.text.trim().isNotEmpty || b.nameCtrl.text.trim().isNotEmpty)
        .map((b) => BoatInvolved(
              boatId: b.boatId,
              sailNumber: b.sailCtrl.text.trim(),
              boatName: b.nameCtrl.text.trim(),
              skipperName: b.skipperCtrl.text.trim(),
              role: b.role,
              boatClass: b.boatClass,
            ))
        .toList();

    final courseName = _isOtherCourse
        ? _otherCourseCtrl.text.trim()
        : _selectedCourse != null
            ? '${_selectedCourse!.courseNumber} — ${_selectedCourse!.courseName}'
            : '';

    final incident = RaceIncident(
      id: '',
      eventId: _selectedEvent?.id ?? '',
      eventName: _selectedEvent?.name ?? '',
      raceNumber: _raceNumber,
      reportedAt: now,
      reportedBy: FirebaseAuth.instance.currentUser?.displayName ?? 'Admin',
      incidentTime: now,
      description: _descCtrl.text.trim(),
      locationOnCourse: _mapLocationToEnum(_locationChoice),
      locationDetail: _locationChoice,
      courseName: courseName,
      involvedBoats: involvedBoats,
      status: RaceIncidentStatus.reported,
      weatherSnapshot: weatherSnap,
    );

    await widget.ref.read(incidentsRepositoryProvider).createIncident(incident);
    if (mounted) Navigator.pop(context);
  }
}

class _BoatEntry {
  final sailCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final skipperCtrl = TextEditingController();
  String boatClass = '';
  String boatId = '';
  BoatInvolvedRole role = BoatInvolvedRole.protesting;

  void clear() {
    sailCtrl.clear();
    nameCtrl.clear();
    skipperCtrl.clear();
    boatClass = '';
    boatId = '';
  }

  void dispose() {
    sailCtrl.dispose();
    nameCtrl.dispose();
    skipperCtrl.dispose();
  }
}
