import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/crew_assignment/domain/crew_assignment_repository.dart';

void main() {
  group('EventStatus', () {
    test('has all expected values', () {
      expect(EventStatus.values, hasLength(3));
      expect(EventStatus.values, contains(EventStatus.scheduled));
      expect(EventStatus.values, contains(EventStatus.cancelled));
      expect(EventStatus.values, contains(EventStatus.completed));
    });
  });

  group('ConfirmationStatus', () {
    test('has all expected values', () {
      expect(ConfirmationStatus.values, hasLength(3));
      expect(ConfirmationStatus.values, contains(ConfirmationStatus.pending));
      expect(
          ConfirmationStatus.values, contains(ConfirmationStatus.confirmed));
      expect(
          ConfirmationStatus.values, contains(ConfirmationStatus.declined));
    });
  });

  group('CrewRole', () {
    test('has all expected values', () {
      expect(CrewRole.values, hasLength(4));
      expect(CrewRole.values, contains(CrewRole.pro));
      expect(CrewRole.values, contains(CrewRole.signalBoat));
      expect(CrewRole.values, contains(CrewRole.markBoat));
      expect(CrewRole.values, contains(CrewRole.safetyBoat));
    });
  });

  group('CrewSlot', () {
    test('creates with defaults', () {
      const slot = CrewSlot(role: CrewRole.pro);

      expect(slot.role, CrewRole.pro);
      expect(slot.memberId, isNull);
      expect(slot.memberName, isNull);
      expect(slot.status, ConfirmationStatus.pending);
    });

    test('creates with all fields', () {
      const slot = CrewSlot(
        role: CrewRole.signalBoat,
        memberId: 'u1',
        memberName: 'Sam Signal',
        status: ConfirmationStatus.confirmed,
      );

      expect(slot.role, CrewRole.signalBoat);
      expect(slot.memberId, 'u1');
      expect(slot.memberName, 'Sam Signal');
      expect(slot.status, ConfirmationStatus.confirmed);
    });

    test('copyWith updates fields', () {
      const original = CrewSlot(role: CrewRole.markBoat);
      final updated = original.copyWith(
        memberId: 'u2',
        memberName: 'Morgan Mark',
        status: ConfirmationStatus.confirmed,
      );

      expect(updated.role, CrewRole.markBoat);
      expect(updated.memberId, 'u2');
      expect(updated.memberName, 'Morgan Mark');
      expect(updated.status, ConfirmationStatus.confirmed);
    });

    test('copyWith preserves unmodified fields', () {
      const original = CrewSlot(
        role: CrewRole.safetyBoat,
        memberId: 'u3',
        memberName: 'Casey Safety',
        status: ConfirmationStatus.pending,
      );

      final updated = original.copyWith(status: ConfirmationStatus.declined);
      expect(updated.role, CrewRole.safetyBoat);
      expect(updated.memberId, 'u3');
      expect(updated.memberName, 'Casey Safety');
      expect(updated.status, ConfirmationStatus.declined);
    });
  });

  group('RaceEvent', () {
    RaceEvent makeEvent({
      List<CrewSlot> crewSlots = const [],
      EventStatus status = EventStatus.scheduled,
    }) {
      return RaceEvent(
        id: 'ev1',
        name: 'Wednesday Night Race #5',
        date: DateTime(2024, 6, 19),
        seriesId: 's1',
        seriesName: 'Wednesday Night Series',
        status: status,
        crewSlots: crewSlots,
      );
    }

    test('creates with required fields and defaults', () {
      final event = makeEvent();

      expect(event.id, 'ev1');
      expect(event.name, 'Wednesday Night Race #5');
      expect(event.date, DateTime(2024, 6, 19));
      expect(event.seriesId, 's1');
      expect(event.seriesName, 'Wednesday Night Series');
      expect(event.status, EventStatus.scheduled);
      expect(event.startTime, isNull);
      expect(event.notes, isNull);
      expect(event.crewSlots, isEmpty);
      expect(event.description, '');
      expect(event.location, '');
      expect(event.contact, '');
      expect(event.extraInfo, '');
      expect(event.rcFleet, '');
      expect(event.raceCommittee, '');
    });

    test('confirmedCount returns correct count', () {
      final event = makeEvent(crewSlots: const [
        CrewSlot(
          role: CrewRole.pro,
          memberId: 'u1',
          memberName: 'Alex',
          status: ConfirmationStatus.confirmed,
        ),
        CrewSlot(
          role: CrewRole.signalBoat,
          memberId: 'u2',
          memberName: 'Sam',
          status: ConfirmationStatus.pending,
        ),
        CrewSlot(
          role: CrewRole.markBoat,
          memberId: 'u3',
          memberName: 'Morgan',
          status: ConfirmationStatus.confirmed,
        ),
        CrewSlot(
          role: CrewRole.safetyBoat,
          memberId: 'u4',
          memberName: 'Casey',
          status: ConfirmationStatus.declined,
        ),
      ]);

      expect(event.confirmedCount, 2);
    });

    test('confirmedCount is 0 when no crew confirmed', () {
      final event = makeEvent(crewSlots: const [
        CrewSlot(role: CrewRole.pro, status: ConfirmationStatus.pending),
        CrewSlot(role: CrewRole.signalBoat, status: ConfirmationStatus.declined),
      ]);

      expect(event.confirmedCount, 0);
    });

    test('confirmedCount is 0 when no crew slots', () {
      final event = makeEvent();
      expect(event.confirmedCount, 0);
    });

    test('copyWith updates single field', () {
      final original = makeEvent();
      final updated = original.copyWith(status: EventStatus.cancelled);

      expect(updated.id, 'ev1');
      expect(updated.name, 'Wednesday Night Race #5');
      expect(updated.status, EventStatus.cancelled);
    });

    test('copyWith updates multiple fields', () {
      final original = makeEvent();
      final updated = original.copyWith(
        name: 'Updated Race',
        notes: 'Postponed due to weather',
        startTime: const TimeOfDay(hour: 14, minute: 30),
      );

      expect(updated.name, 'Updated Race');
      expect(updated.notes, 'Postponed due to weather');
      expect(updated.startTime, const TimeOfDay(hour: 14, minute: 30));
      expect(updated.date, DateTime(2024, 6, 19)); // unchanged
    });

    test('copyWith replaces crew slots', () {
      final original = makeEvent(crewSlots: const [
        CrewSlot(role: CrewRole.pro),
      ]);

      final updated = original.copyWith(crewSlots: const [
        CrewSlot(role: CrewRole.pro, memberId: 'u1', memberName: 'Alex'),
        CrewSlot(role: CrewRole.signalBoat),
      ]);

      expect(updated.crewSlots, hasLength(2));
      expect(updated.crewSlots[0].memberName, 'Alex');
    });
  });

  group('SeriesDefinition', () {
    test('creates with required fields', () {
      final series = SeriesDefinition(
        id: 's1',
        name: 'Wednesday Night Series',
        color: Colors.blue,
        startDate: DateTime(2024, 4, 1),
        endDate: DateTime(2024, 10, 31),
      );

      expect(series.id, 's1');
      expect(series.name, 'Wednesday Night Series');
      expect(series.color, Colors.blue);
      expect(series.startDate, DateTime(2024, 4, 1));
      expect(series.endDate, DateTime(2024, 10, 31));
      expect(series.recurringWeekday, isNull);
    });

    test('creates with recurring weekday', () {
      final series = SeriesDefinition(
        id: 's1',
        name: 'Wednesday Night Series',
        color: Colors.blue,
        startDate: DateTime(2024, 4, 1),
        endDate: DateTime(2024, 10, 31),
        recurringWeekday: DateTime.wednesday,
      );

      expect(series.recurringWeekday, DateTime.wednesday);
    });

    test('copyWith preserves unmodified fields', () {
      final original = SeriesDefinition(
        id: 's1',
        name: 'Wednesday Night Series',
        color: Colors.blue,
        startDate: DateTime(2024, 4, 1),
        endDate: DateTime(2024, 10, 31),
      );

      final updated = original.copyWith(name: 'Saturday Series');
      expect(updated.id, 's1');
      expect(updated.name, 'Saturday Series');
      expect(updated.color, Colors.blue);
      expect(updated.startDate, DateTime(2024, 4, 1));
    });
  });

  group('MyAssignment', () {
    test('creates with all fields', () {
      final event = RaceEvent(
        id: 'ev1',
        name: 'Race #1',
        date: DateTime(2024, 6, 19),
        seriesId: 's1',
        seriesName: 'Series',
        status: EventStatus.scheduled,
      );

      final assignment = MyAssignment(
        event: event,
        role: CrewRole.pro,
        status: ConfirmationStatus.confirmed,
      );

      expect(assignment.event.id, 'ev1');
      expect(assignment.role, CrewRole.pro);
      expect(assignment.status, ConfirmationStatus.confirmed);
    });
  });

  group('EventDetailData', () {
    test('creates with defaults', () {
      final event = RaceEvent(
        id: 'ev1',
        name: 'Race #1',
        date: DateTime(2024, 6, 19),
        seriesId: 's1',
        seriesName: 'Series',
        status: EventStatus.scheduled,
      );

      final detail = EventDetailData(event: event);

      expect(detail.event.id, 'ev1');
      expect(detail.courseName, isNull);
      expect(detail.weatherSummary, isNull);
      expect(detail.incidentCount, 0);
      expect(detail.completedChecklists, 0);
    });

    test('creates with all fields', () {
      final event = RaceEvent(
        id: 'ev1',
        name: 'Race #1',
        date: DateTime(2024, 6, 19),
        seriesId: 's1',
        seriesName: 'Series',
        status: EventStatus.completed,
      );

      final detail = EventDetailData(
        event: event,
        courseName: 'Course 3A',
        weatherSummary: '12kt NW',
        incidentCount: 2,
        completedChecklists: 4,
      );

      expect(detail.courseName, 'Course 3A');
      expect(detail.weatherSummary, '12kt NW');
      expect(detail.incidentCount, 2);
      expect(detail.completedChecklists, 4);
    });
  });

  group('CalendarImportResult', () {
    test('creates with all fields', () {
      const result = CalendarImportResult(
        created: 10,
        updated: 3,
        skipped: 1,
        errors: ['Row 5: missing date'],
      );

      expect(result.created, 10);
      expect(result.updated, 3);
      expect(result.skipped, 1);
      expect(result.errors, hasLength(1));
      expect(result.errors.first, contains('Row 5'));
    });

    test('creates with no errors', () {
      const result = CalendarImportResult(
        created: 5,
        updated: 0,
        skipped: 0,
        errors: [],
      );

      expect(result.errors, isEmpty);
    });
  });
}
