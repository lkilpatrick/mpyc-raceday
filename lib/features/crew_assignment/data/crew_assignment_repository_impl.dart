import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/crew_assignment_repository.dart';

class CrewAssignmentRepositoryImpl implements CrewAssignmentRepository {
  CrewAssignmentRepositoryImpl() {
    _series = [
      SeriesDefinition(
        id: 'spring',
        name: 'Spring Series',
        color: Colors.blue,
        startDate: DateTime(DateTime.now().year, 4, 1),
        endDate: DateTime(DateTime.now().year, 6, 30),
        recurringWeekday: DateTime.wednesday,
      ),
      SeriesDefinition(
        id: 'summer',
        name: 'Summer Series',
        color: Colors.orange,
        startDate: DateTime(DateTime.now().year, 7, 1),
        endDate: DateTime(DateTime.now().year, 9, 30),
        recurringWeekday: DateTime.wednesday,
      ),
    ];

    _events = [
      RaceEvent(
        id: 'e1',
        name: 'Spring #1',
        date: DateTime.now().add(const Duration(days: 3)),
        seriesId: 'spring',
        seriesName: 'Spring Series',
        status: EventStatus.scheduled,
        startTime: const TimeOfDay(hour: 13, minute: 0),
        crewSlots: const [
          CrewSlot(
            role: CrewRole.pro,
            memberId: 'user_1',
            memberName: 'Alex PRO',
            status: ConfirmationStatus.confirmed,
          ),
          CrewSlot(
            role: CrewRole.signalBoat,
            memberId: 'user_2',
            memberName: 'Sam Signal',
          ),
          CrewSlot(
            role: CrewRole.markBoat,
            memberId: 'user_3',
            memberName: 'Morgan Mark',
          ),
          CrewSlot(
            role: CrewRole.safetyBoat,
            memberId: 'user_4',
            memberName: 'Taylor Safety',
          ),
        ],
      ),
      RaceEvent(
        id: 'e2',
        name: 'Spring #2',
        date: DateTime.now().add(const Duration(days: 10)),
        seriesId: 'spring',
        seriesName: 'Spring Series',
        status: EventStatus.scheduled,
        startTime: const TimeOfDay(hour: 13, minute: 0),
        crewSlots: const [
          CrewSlot(
            role: CrewRole.pro,
            memberId: 'user_2',
            memberName: 'Sam Signal',
          ),
          CrewSlot(
            role: CrewRole.signalBoat,
            memberId: 'user_1',
            memberName: 'Alex PRO',
          ),
          CrewSlot(
            role: CrewRole.markBoat,
            memberId: 'user_5',
            memberName: 'Jordan Mark',
          ),
          CrewSlot(
            role: CrewRole.safetyBoat,
            memberId: 'user_6',
            memberName: 'Casey Safety',
          ),
        ],
      ),
    ];

    _emitAll();
  }

  late List<RaceEvent> _events;
  late List<SeriesDefinition> _series;

  final _eventsController = StreamController<List<RaceEvent>>.broadcast();
  final _seriesController =
      StreamController<List<SeriesDefinition>>.broadcast();

  void _emitAll() {
    final sorted = [..._events]..sort((a, b) => a.date.compareTo(b.date));
    _eventsController.add(sorted);
    _seriesController.add([..._series]);
  }

  void dispose() {
    _eventsController.close();
    _seriesController.close();
  }

  @override
  Stream<List<RaceEvent>> watchUpcomingEvents() async* {
    yield [..._events]..sort((a, b) => a.date.compareTo(b.date));
    yield* _eventsController.stream;
  }

  @override
  Stream<List<MyAssignment>> watchMyAssignments(String userId) {
    return watchUpcomingEvents().map(
      (events) => events
          .where(
            (e) => e.date.isAfter(
              DateTime.now().subtract(const Duration(days: 1)),
            ),
          )
          .expand((event) {
            return event.crewSlots
                .where((slot) => slot.memberId == userId)
                .map(
                  (slot) => MyAssignment(
                    event: event,
                    role: slot.role,
                    status: slot.status,
                  ),
                );
          })
          .toList(),
    );
  }

  @override
  Stream<EventDetailData> watchEventDetail(String eventId) {
    return watchUpcomingEvents().map((events) {
      final event = events.firstWhere((e) => e.id == eventId);
      return EventDetailData(
        event: event,
        courseName: 'Center Sound W/L',
        weatherSummary: '12kt NW, slight chop',
        incidentCount: 0,
        completedChecklists: 2,
      );
    });
  }

  @override
  Stream<List<SeriesDefinition>> watchSeries() async* {
    yield [..._series];
    yield* _seriesController.stream;
  }

  @override
  Future<void> saveEvent(RaceEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index == -1) {
      _events.add(event);
    } else {
      _events[index] = event;
    }
    _emitAll();
  }

  @override
  Future<void> bulkCancelEvents(List<String> eventIds) async {
    _events = _events
        .map(
          (e) => eventIds.contains(e.id)
              ? e.copyWith(status: EventStatus.cancelled)
              : e,
        )
        .toList();
    _emitAll();
  }

  @override
  Future<void> updateCrewSlots(String eventId, List<CrewSlot> slots) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index < 0) return;
    _events[index] = _events[index].copyWith(crewSlots: slots);
    _emitAll();
  }

  @override
  Future<void> updateConfirmation(
    String eventId,
    CrewRole role,
    ConfirmationStatus status, {
    String? reason,
  }) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index < 0) return;
    final slots = _events[index].crewSlots
        .map((slot) => slot.role == role ? slot.copyWith(status: status) : slot)
        .toList();
    _events[index] = _events[index].copyWith(
      crewSlots: slots,
      notes: reason == null ? _events[index].notes : 'Decline note: $reason',
    );
    _emitAll();
  }

  @override
  Future<void> saveSeries(SeriesDefinition series) async {
    final index = _series.indexWhere((s) => s.id == series.id);
    if (index < 0) {
      _series.add(series);
    } else {
      _series[index] = series;
    }
    _emitAll();
  }

  @override
  Future<void> generateSeriesEvents(String seriesId) async {
    final series = _series.firstWhere((s) => s.id == seriesId);
    if (series.recurringWeekday == null) return;

    var cursor = series.startDate;
    while (!cursor.isAfter(series.endDate)) {
      if (cursor.weekday == series.recurringWeekday) {
        final id = 'e_${series.id}_${cursor.millisecondsSinceEpoch}';
        final exists = _events.any(
          (e) =>
              e.seriesId == series.id &&
              e.date.year == cursor.year &&
              e.date.month == cursor.month &&
              e.date.day == cursor.day,
        );
        if (!exists) {
          _events.add(
            RaceEvent(
              id: id,
              name: '${series.name} ${cursor.month}/${cursor.day}',
              date: DateTime(cursor.year, cursor.month, cursor.day),
              seriesId: series.id,
              seriesName: series.name,
              status: EventStatus.scheduled,
              startTime: const TimeOfDay(hour: 13, minute: 0),
              crewSlots: const [
                CrewSlot(role: CrewRole.pro),
                CrewSlot(role: CrewRole.signalBoat),
                CrewSlot(role: CrewRole.markBoat),
                CrewSlot(role: CrewRole.safetyBoat),
              ],
            ),
          );
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    _emitAll();
  }

  @override
  Future<CalendarImportResult> importCalendar(
    List<Map<String, String>> mappedRows,
  ) async {
    var created = 0;
    var updated = 0;
    var skipped = 0;
    final errors = <String>[];

    for (final row in mappedRows) {
      final name = row['Event Name']?.trim();
      final dateRaw = row['Date']?.trim();
      final seriesName = row['Series']?.trim() ?? 'Uncategorized';

      if (name == null || name.isEmpty || dateRaw == null || dateRaw.isEmpty) {
        errors.add('Missing required value (Event Name/Date): $row');
        skipped++;
        continue;
      }

      final date = DateTime.tryParse(dateRaw);
      if (date == null) {
        errors.add('Invalid date format for "$name": $dateRaw');
        skipped++;
        continue;
      }

      final duplicateIndex = _events.indexWhere(
        (e) =>
            e.name == name &&
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day,
      );

      if (duplicateIndex >= 0) {
        _events[duplicateIndex] = _events[duplicateIndex].copyWith(
          seriesName: seriesName,
        );
        updated++;
      } else {
        _events.add(
          RaceEvent(
            id: 'import_${date.millisecondsSinceEpoch}_$created',
            name: name,
            date: date,
            seriesId: seriesName.toLowerCase().replaceAll(' ', '_'),
            seriesName: seriesName,
            status: EventStatus.scheduled,
            crewSlots: const [
              CrewSlot(role: CrewRole.pro),
              CrewSlot(role: CrewRole.signalBoat),
              CrewSlot(role: CrewRole.markBoat),
              CrewSlot(role: CrewRole.safetyBoat),
            ],
          ),
        );
        created++;
      }
    }

    _emitAll();
    return CalendarImportResult(
      created: created,
      updated: updated,
      skipped: skipped,
      errors: errors,
    );
  }

  @override
  Future<void> notifyCrew({
    required String eventId,
    required bool onlyUnconfirmed,
  }) async {}

  @override
  Future<List<String>> suggestFairAssignments(String eventId) async {
    final dutyCounts = <String, int>{};
    for (final event in _events) {
      for (final slot in event.crewSlots) {
        if (slot.memberName != null) {
          dutyCounts.update(slot.memberName!, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    final sorted = dutyCounts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.take(4).map((e) => e.key).toList();
  }
}
