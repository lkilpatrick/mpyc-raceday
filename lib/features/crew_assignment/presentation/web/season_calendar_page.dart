import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/crew_assignment_repository.dart';
import '../crew_assignment_providers.dart';
import 'calendar_import_dialog.dart';
import 'series_management_dialog.dart';

enum _CalendarViewMode { month, week, day }

class SeasonCalendarPage extends ConsumerStatefulWidget {
  const SeasonCalendarPage({super.key});

  @override
  ConsumerState<SeasonCalendarPage> createState() => _SeasonCalendarPageState();
}

class _SeasonCalendarPageState extends ConsumerState<SeasonCalendarPage> {
  _CalendarViewMode _mode = _CalendarViewMode.month;
  DateTime _focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final seriesAsync = ref.watch(seriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<_CalendarViewMode>(
              segments: const [
                ButtonSegment(
                  value: _CalendarViewMode.month,
                  label: Text('Month'),
                ),
                ButtonSegment(
                  value: _CalendarViewMode.week,
                  label: Text('Week'),
                ),
                ButtonSegment(value: _CalendarViewMode.day, label: Text('Day')),
              ],
              selected: {_mode},
              onSelectionChanged: (set) => setState(() => _mode = set.first),
            ),
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const CalendarImportDialog(),
              ),
              icon: const Icon(Icons.upload_file),
              label: const Text('Import from Excel'),
            ),
            OutlinedButton.icon(
              onPressed: _addEvent,
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
            ),
            OutlinedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const SeriesManagementDialog(),
              ),
              icon: const Icon(Icons.palette),
              label: const Text('Manage Series'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: eventsAsync.when(
                      data: (events) => _CalendarGrid(
                        focusedDate: _focusedDate,
                        mode: _mode,
                        events: events,
                        onDateSelected: (date) =>
                            setState(() => _focusedDate = date),
                        onDragCreate: (start, end) =>
                            _createMultiDayEvent(start, end),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error loading events: $e'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming Events',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: eventsAsync.when(
                            data: (events) => ListView(
                              children: events
                                  .take(10)
                                  .map(
                                    (event) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(event.name),
                                      subtitle: Text(
                                        DateFormat.yMMMd().format(event.date),
                                      ),
                                      trailing: seriesAsync.when(
                                        data: (seriesList) {
                                          final series = seriesList
                                              .where(
                                                (s) => s.id == event.seriesId,
                                              )
                                              .firstOrNull;
                                          return Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color:
                                                  series?.color ?? Colors.grey,
                                              shape: BoxShape.circle,
                                            ),
                                          );
                                        },
                                        loading: () => const SizedBox.shrink(),
                                        error: (_, __) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => Text('Error: $e'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addEvent() async {
    final repo = ref.read(crewAssignmentRepositoryProvider);
    final selectedSeries = ref
        .read(seriesProvider)
        .maybeWhen(
          data: (items) => items.isNotEmpty ? items.first : null,
          orElse: () => null,
        );
    await repo.saveEvent(
      RaceEvent(
        id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        name: 'New Event',
        date: _focusedDate,
        seriesId: selectedSeries?.id ?? 'general',
        seriesName: selectedSeries?.name ?? 'General',
        status: EventStatus.scheduled,
        crewSlots: const [
          CrewSlot(role: CrewRole.pro),
          CrewSlot(role: CrewRole.signalBoat),
          CrewSlot(role: CrewRole.markBoat),
          CrewSlot(role: CrewRole.safetyBoat),
        ],
      ),
    );
  }

  Future<void> _createMultiDayEvent(DateTime start, DateTime end) async {
    final repo = ref.read(crewAssignmentRepositoryProvider);
    final selectedSeries = ref
        .read(seriesProvider)
        .maybeWhen(
          data: (items) => items.isNotEmpty ? items.first : null,
          orElse: () => null,
        );
    var date = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (!date.isAfter(endDate)) {
      await repo.saveEvent(
        RaceEvent(
          id: 'drag_${date.millisecondsSinceEpoch}',
          name: 'Regatta Day ${DateFormat.Md().format(date)}',
          date: date,
          seriesId: selectedSeries?.id ?? 'general',
          seriesName: selectedSeries?.name ?? 'General',
          status: EventStatus.scheduled,
          crewSlots: const [
            CrewSlot(role: CrewRole.pro),
            CrewSlot(role: CrewRole.signalBoat),
            CrewSlot(role: CrewRole.markBoat),
            CrewSlot(role: CrewRole.safetyBoat),
          ],
        ),
      );
      date = date.add(const Duration(days: 1));
    }
  }
}

class _CalendarGrid extends StatefulWidget {
  const _CalendarGrid({
    required this.focusedDate,
    required this.mode,
    required this.events,
    required this.onDateSelected,
    required this.onDragCreate,
  });

  final DateTime focusedDate;
  final _CalendarViewMode mode;
  final List<RaceEvent> events;
  final ValueChanged<DateTime> onDateSelected;
  final Future<void> Function(DateTime start, DateTime end) onDragCreate;

  @override
  State<_CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<_CalendarGrid> {
  DateTime? _dragStart;

  @override
  Widget build(BuildContext context) {
    final base = DateTime(widget.focusedDate.year, widget.focusedDate.month, 1);
    final days = switch (widget.mode) {
      _CalendarViewMode.month => DateUtils.getDaysInMonth(
        base.year,
        base.month,
      ),
      _CalendarViewMode.week => 7,
      _ => 1,
    };
    final start = switch (widget.mode) {
      _CalendarViewMode.month => base,
      _CalendarViewMode.week => widget.focusedDate.subtract(
        Duration(days: widget.focusedDate.weekday - 1),
      ),
      _ => DateTime(
        widget.focusedDate.year,
        widget.focusedDate.month,
        widget.focusedDate.day,
      ),
    };

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.mode == _CalendarViewMode.month ? 7 : 1,
        mainAxisExtent: widget.mode == _CalendarViewMode.day ? 140 : 96,
      ),
      itemCount: days,
      itemBuilder: (context, index) {
        final day = start.add(Duration(days: index));
        final dayEvents = widget.events
            .where(
              (e) =>
                  e.date.year == day.year &&
                  e.date.month == day.month &&
                  e.date.day == day.day,
            )
            .toList();

        return DragTarget<DateTime>(
          onAcceptWithDetails: (details) =>
              widget.onDragCreate(details.data, day),
          builder: (_, __, ___) {
            return GestureDetector(
              onTap: () => widget.onDateSelected(day),
              onPanStart: (_) => _dragStart = day,
              onPanEnd: (_) {
                if (_dragStart != null) {
                  widget.onDragCreate(_dragStart!, day);
                }
              },
              child: Card(
                margin: const EdgeInsets.all(4),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat.Md().format(day)),
                      const SizedBox(height: 4),
                      ...dayEvents
                          .take(3)
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                color: Colors.blue.withValues(alpha: 0.18),
                                child: Text(
                                  e.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
