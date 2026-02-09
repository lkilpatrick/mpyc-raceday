import 'package:flutter/material.dart';

enum EventStatus { scheduled, cancelled, completed }

enum ConfirmationStatus { pending, confirmed, declined }

enum CrewRole { pro, signalBoat, markBoat, safetyBoat }

class SeriesDefinition {
  const SeriesDefinition({
    required this.id,
    required this.name,
    required this.color,
    required this.startDate,
    required this.endDate,
    this.recurringWeekday,
  });

  final String id;
  final String name;
  final Color color;
  final DateTime startDate;
  final DateTime endDate;
  final int? recurringWeekday;

  SeriesDefinition copyWith({
    String? id,
    String? name,
    Color? color,
    DateTime? startDate,
    DateTime? endDate,
    int? recurringWeekday,
  }) {
    return SeriesDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      recurringWeekday: recurringWeekday ?? this.recurringWeekday,
    );
  }
}

class CrewSlot {
  const CrewSlot({
    required this.role,
    this.memberId,
    this.memberName,
    this.status = ConfirmationStatus.pending,
  });

  final CrewRole role;
  final String? memberId;
  final String? memberName;
  final ConfirmationStatus status;

  CrewSlot copyWith({
    CrewRole? role,
    String? memberId,
    String? memberName,
    ConfirmationStatus? status,
  }) {
    return CrewSlot(
      role: role ?? this.role,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      status: status ?? this.status,
    );
  }
}

class RaceEvent {
  const RaceEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.seriesId,
    required this.seriesName,
    required this.status,
    this.startTime,
    this.notes,
    this.crewSlots = const [],
  });

  final String id;
  final String name;
  final DateTime date;
  final String seriesId;
  final String seriesName;
  final EventStatus status;
  final TimeOfDay? startTime;
  final String? notes;
  final List<CrewSlot> crewSlots;

  int get confirmedCount => crewSlots
      .where((slot) => slot.status == ConfirmationStatus.confirmed)
      .length;

  RaceEvent copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? seriesId,
    String? seriesName,
    EventStatus? status,
    TimeOfDay? startTime,
    String? notes,
    List<CrewSlot>? crewSlots,
  }) {
    return RaceEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      seriesId: seriesId ?? this.seriesId,
      seriesName: seriesName ?? this.seriesName,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      notes: notes ?? this.notes,
      crewSlots: crewSlots ?? this.crewSlots,
    );
  }
}

class MyAssignment {
  const MyAssignment({
    required this.event,
    required this.role,
    required this.status,
  });

  final RaceEvent event;
  final CrewRole role;
  final ConfirmationStatus status;
}

class EventDetailData {
  const EventDetailData({
    required this.event,
    this.courseName,
    this.weatherSummary,
    this.incidentCount = 0,
    this.completedChecklists = 0,
  });

  final RaceEvent event;
  final String? courseName;
  final String? weatherSummary;
  final int incidentCount;
  final int completedChecklists;
}

class CalendarImportResult {
  const CalendarImportResult({
    required this.created,
    required this.updated,
    required this.skipped,
    required this.errors,
  });

  final int created;
  final int updated;
  final int skipped;
  final List<String> errors;
}

abstract class CrewAssignmentRepository {
  const CrewAssignmentRepository();

  Stream<List<RaceEvent>> watchUpcomingEvents();
  Stream<List<MyAssignment>> watchMyAssignments(String userId);
  Stream<EventDetailData> watchEventDetail(String eventId);
  Stream<List<SeriesDefinition>> watchSeries();

  Future<void> saveEvent(RaceEvent event);
  Future<void> bulkCancelEvents(List<String> eventIds);
  Future<void> updateCrewSlots(String eventId, List<CrewSlot> slots);
  Future<void> updateConfirmation(
    String eventId,
    CrewRole role,
    ConfirmationStatus status, {
    String? reason,
  });
  Future<void> saveSeries(SeriesDefinition series);
  Future<void> generateSeriesEvents(String seriesId);
  Future<CalendarImportResult> importCalendar(
    List<Map<String, String>> mappedRows,
  );
  Future<void> notifyCrew({
    required String eventId,
    required bool onlyUnconfirmed,
  });
  Future<List<String>> suggestFairAssignments(String eventId);
}
