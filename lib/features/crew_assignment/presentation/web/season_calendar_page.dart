import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpyc_raceday/core/theme.dart';

import '../../domain/crew_assignment_repository.dart';
import '../crew_assignment_providers.dart';
import 'calendar_import_dialog.dart';
import 'csv_download_stub.dart'
    if (dart.library.html) 'csv_download_web.dart' as csv_dl;

class SeasonCalendarPage extends ConsumerStatefulWidget {
  const SeasonCalendarPage({super.key});

  @override
  ConsumerState<SeasonCalendarPage> createState() => _SeasonCalendarPageState();
}

class _SeasonCalendarPageState extends ConsumerState<SeasonCalendarPage> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  RaceEvent? _selectedEvent;

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _selectedEvent = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      _selectedEvent = null;
    });
  }

  void _goToToday() {
    setState(() {
      _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
      _selectedEvent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Toolbar ──
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // Month navigation
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous month',
              ),
              GestureDetector(
                onTap: _goToToday,
                child: Text(
                  DateFormat.yMMMM().format(_focusedMonth),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next month',
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _goToToday,
                icon: const Icon(Icons.today, size: 18),
                label: const Text('Today'),
              ),
              const Spacer(),
              // Actions
              FilledButton.icon(
                onPressed: () => _showAddEventDialog(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Event'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const CalendarImportDialog(),
                ),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Import'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _exportCalendar,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
              ),
            ],
          ),
        ),

        // ── Calendar + Detail panel ──
        Expanded(
          child: eventsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (events) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar grid
                Expanded(
                  flex: 3,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: _MonthGrid(
                      month: _focusedMonth,
                      events: events,
                      selectedEvent: _selectedEvent,
                      onEventTap: (e) =>
                          setState(() => _selectedEvent = e),
                      onDayDoubleTap: (date) => _showAddEventDialog(date),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Detail / upcoming panel
                Expanded(
                  child: _selectedEvent != null
                      ? _EventDetailCard(
                          event: _selectedEvent!,
                          onEdit: () =>
                              _showEditEventDialog(_selectedEvent!),
                          onDelete: () =>
                              _confirmDeleteEvent(_selectedEvent!),
                          onClose: () =>
                              setState(() => _selectedEvent = null),
                        )
                      : _UpcomingEventsCard(
                          events: events,
                          onEventTap: (e) =>
                              setState(() => _selectedEvent = e),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── CRUD Dialogs ──

  Future<void> _showAddEventDialog(DateTime? date) async {
    final result = await showDialog<RaceEvent>(
      context: context,
      builder: (_) => _EventFormDialog(
        initialDate: date ?? DateTime.now(),
      ),
    );
    if (result == null) return;
    final repo = ref.read(crewAssignmentRepositoryProvider);
    await repo.saveEvent(result);
  }

  Future<void> _showEditEventDialog(RaceEvent event) async {
    final result = await showDialog<RaceEvent>(
      context: context,
      builder: (_) => _EventFormDialog(event: event),
    );
    if (result == null) return;
    final repo = ref.read(crewAssignmentRepositoryProvider);
    await repo.saveEvent(result);
    setState(() => _selectedEvent = result);
  }

  Future<void> _confirmDeleteEvent(RaceEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Delete "${event.name}"? This cannot be undone.'),
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
    try {
      final repo = ref.read(crewAssignmentRepositoryProvider);
      await repo.deleteEvent(event.id);
      setState(() => _selectedEvent = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportCalendar() async {
    final repo = ref.read(crewAssignmentRepositoryProvider);
    final rows = await repo.exportCalendar();
    if (rows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No events to export.')),
        );
      }
      return;
    }

    final headers = [
      'Title', 'Start Date', 'Start Time', 'Description',
      'Location', 'Contact', 'Extra Info', 'RC Fleet', 'Race Committee',
    ];
    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));
    for (final row in rows) {
      final line = headers.map((h) {
        final val = row[h] ?? '';
        return val.contains(',') ? '"$val"' : val;
      }).join(',');
      buffer.writeln(line);
    }
    csv_dl.downloadCsv(buffer.toString(), 'MPYC_RaceCalendar_Export.csv');
  }
}

// ═══════════════════════════════════════════════════════════════════
// Month Grid
// ═══════════════════════════════════════════════════════════════════

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.events,
    required this.selectedEvent,
    required this.onEventTap,
    required this.onDayDoubleTap,
  });

  final DateTime month;
  final List<RaceEvent> events;
  final RaceEvent? selectedEvent;
  final ValueChanged<RaceEvent> onEventTap;
  final ValueChanged<DateTime> onDayDoubleTap;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    // Sunday = 7 in Dart, so offset = weekday % 7 to start grid on Sunday
    final startOffset = firstOfMonth.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: [
        // Day-of-week headers
        Container(
          color: Colors.grey.shade100,
          child: Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((d) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: (d == 'Sat' || d == 'Sun')
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const Divider(height: 1),
        // Grid of days
        Expanded(
          child: Column(
            children: List.generate(rows, (row) {
              return Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(7, (col) {
                    final cellIndex = row * 7 + col;
                    final dayNum = cellIndex - startOffset + 1;

                    if (dayNum < 1 || dayNum > daysInMonth) {
                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            color: Colors.grey.shade50,
                          ),
                        ),
                      );
                    }

                    final day = DateTime(month.year, month.month, dayNum);
                    final isToday = day.year == today.year &&
                        day.month == today.month &&
                        day.day == today.day;
                    final dayEvents = events
                        .where((e) =>
                            e.date.year == day.year &&
                            e.date.month == day.month &&
                            e.date.day == day.day)
                        .toList();

                    return Expanded(
                      child: GestureDetector(
                        onDoubleTap: () => onDayDoubleTap(day),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            color: isToday
                                ? const Color(0xFFE8EEF5)
                                : Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day number
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: isToday
                                      ? const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        )
                                      : null,
                                  child: Text(
                                    '$dayNum',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isToday
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                // Events
                                ...dayEvents.take(3).map((e) {
                                  final isSelected =
                                      selectedEvent?.id == e.id;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 1),
                                    child: InkWell(
                                      onTap: () => onEventTap(e),
                                      child: Container(
                                        width: double.infinity,
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : _eventColor(e),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          e.name,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                if (dayEvents.length > 3)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Text(
                                      '+${dayEvents.length - 3} more',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  static Color _eventColor(RaceEvent e) {
    final lower = e.seriesName.toLowerCase();
    if (lower.contains('sunset')) return Colors.orange.shade100;
    if (lower.contains('phrf')) return Colors.green.shade100;
    if (lower.contains('one design')) return Colors.purple.shade100;
    if (lower.contains('mbyra')) return Colors.red.shade100;
    if (lower.contains('training')) return Colors.teal.shade100;
    if (lower.contains('youth')) return Colors.cyan.shade100;
    if (lower.contains('national')) return Colors.amber.shade100;
    if (lower.contains('commodore')) return Colors.indigo.shade100;
    return Colors.blue.shade100;
  }
}

// ═══════════════════════════════════════════════════════════════════
// Event Detail Card (right panel when event selected)
// ═══════════════════════════════════════════════════════════════════

class _EventDetailCard extends StatelessWidget {
  const _EventDetailCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    required this.onClose,
  });

  final RaceEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Close',
                ),
              ],
            ),
            const Divider(),
            _detailRow(Icons.calendar_today,
                DateFormat.yMMMMEEEEd().format(event.date)),
            if (event.startTime != null)
              _detailRow(Icons.access_time, event.startTime!.format(context)),
            if (event.seriesName.isNotEmpty)
              _detailRow(Icons.category, event.seriesName),
            if (event.location.isNotEmpty)
              _detailRow(Icons.location_on, event.location),
            if (event.description.isNotEmpty)
              _detailRow(Icons.description, event.description),
            if (event.contact.isNotEmpty)
              _detailRow(Icons.person, event.contact),
            if (event.rcFleet.isNotEmpty)
              _detailRow(Icons.sailing, 'RC Fleet: ${event.rcFleet}'),
            if (event.raceCommittee.isNotEmpty)
              _detailRow(Icons.groups, 'RC: ${event.raceCommittee}'),
            if (event.extraInfo.isNotEmpty)
              _detailRow(Icons.info_outline, event.extraInfo),
            if (event.notes != null && event.notes!.isNotEmpty)
              _detailRow(Icons.note, event.notes!),
            const SizedBox(height: 8),
            _statusChip(event.status),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _statusChip(EventStatus status) {
    final (label, color) = switch (status) {
      EventStatus.scheduled => ('Scheduled', Colors.blue),
      EventStatus.completed => ('Completed', Colors.green),
      EventStatus.cancelled => ('Cancelled', Colors.red),
    };
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withAlpha(25),
      side: BorderSide(color: color.withAlpha(80)),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Upcoming Events Card (right panel when no event selected)
// ═══════════════════════════════════════════════════════════════════

class _UpcomingEventsCard extends StatelessWidget {
  const _UpcomingEventsCard({
    required this.events,
    required this.onEventTap,
  });

  final List<RaceEvent> events;
  final ValueChanged<RaceEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = events
        .where((e) => !e.date.isBefore(DateTime(now.year, now.month, now.day)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upcoming Events',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: upcoming.isEmpty
                  ? const Center(
                      child: Text('No upcoming events',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: upcoming.take(15).length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = upcoming[i];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onTap: () => onEventTap(e),
                          leading: Container(
                            width: 4,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _MonthGrid._eventColor(e),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          title: Text(e.name,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            DateFormat.MMMEd().format(e.date),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600),
                          ),
                          trailing: e.startTime != null
                              ? Text(
                                  _formatTime(e.startTime!),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final amPm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $amPm';
  }
}

// ═══════════════════════════════════════════════════════════════════
// Event Create/Edit Form Dialog
// ═══════════════════════════════════════════════════════════════════

class _EventFormDialog extends StatefulWidget {
  const _EventFormDialog({this.event, this.initialDate});

  final RaceEvent? event;
  final DateTime? initialDate;

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _extraInfoCtrl;
  late final TextEditingController _rcFleetCtrl;
  late final TextEditingController _raceCommitteeCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _date;
  TimeOfDay? _startTime;
  EventStatus _status = EventStatus.scheduled;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _contactCtrl = TextEditingController(text: e?.contact ?? '');
    _extraInfoCtrl = TextEditingController(text: e?.extraInfo ?? '');
    _rcFleetCtrl = TextEditingController(text: e?.rcFleet ?? '');
    _raceCommitteeCtrl = TextEditingController(text: e?.raceCommittee ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _date = e?.date ?? widget.initialDate ?? DateTime.now();
    _startTime = e?.startTime;
    _status = e?.status ?? EventStatus.scheduled;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    _extraInfoCtrl.dispose();
    _rcFleetCtrl.dispose();
    _raceCommitteeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing ? 'Edit Event' : 'New Event',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Event Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date *',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                                DateFormat.yMMMEd().format(_date)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickTime,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_startTime != null
                                ? _startTime!.format(context)
                                : 'Not set'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EventStatus>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: EventStatus.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name[0].toUpperCase() +
                                  s.name.substring(1)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description / Fleet Class',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _contactCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Contact',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rcFleetCtrl,
                          decoration: const InputDecoration(
                            labelText: 'RC Fleet',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _raceCommitteeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Race Committee',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _extraInfoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Extra Info',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _submit,
                        child: Text(_isEditing ? 'Save' : 'Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.event;
    final id = existing?.id ??
        'manual_${DateTime.now().millisecondsSinceEpoch}';
    final seriesName = existing?.seriesName ?? 'Special Events';
    final seriesId = existing?.seriesId ??
        seriesName.toLowerCase().replaceAll(' ', '_');

    final event = RaceEvent(
      id: id,
      name: _nameCtrl.text.trim(),
      date: _date,
      seriesId: seriesId,
      seriesName: seriesName,
      status: _status,
      startTime: _startTime,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      contact: _contactCtrl.text.trim(),
      extraInfo: _extraInfoCtrl.text.trim(),
      rcFleet: _rcFleetCtrl.text.trim(),
      raceCommittee: _raceCommitteeCtrl.text.trim(),
      crewSlots: existing?.crewSlots ??
          const [
            CrewSlot(role: CrewRole.pro),
            CrewSlot(role: CrewRole.signalBoat),
            CrewSlot(role: CrewRole.markBoat),
            CrewSlot(role: CrewRole.safetyBoat),
          ],
    );
    Navigator.pop(context, event);
  }
}
