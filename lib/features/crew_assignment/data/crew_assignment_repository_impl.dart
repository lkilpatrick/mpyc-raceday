import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../shared/services/audit_service.dart';
import '../domain/crew_assignment_repository.dart';

class CrewAssignmentRepositoryImpl implements CrewAssignmentRepository {
  CrewAssignmentRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    AuditService? audit,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _audit = audit ?? AuditService();

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final AuditService _audit;

  CollectionReference<Map<String, dynamic>> get _eventsCol =>
      _firestore.collection('race_events');

  CollectionReference<Map<String, dynamic>> get _seriesCol =>
      _firestore.collection('season_series');

  // ── Helpers ──

  static const _roleMap = {
    'pro': CrewRole.pro,
    'signalBoat': CrewRole.signalBoat,
    'markBoat': CrewRole.markBoat,
    'safetyBoat': CrewRole.safetyBoat,
  };

  static String _roleToString(CrewRole role) {
    return _roleMap.entries.firstWhere((e) => e.value == role).key;
  }

  static CrewRole _roleFromString(String s) {
    return _roleMap[s] ?? CrewRole.pro;
  }

  static const _statusMap = {
    'scheduled': EventStatus.scheduled,
    'cancelled': EventStatus.cancelled,
    'completed': EventStatus.completed,
  };

  static String _eventStatusToString(EventStatus s) {
    return _statusMap.entries.firstWhere((e) => e.value == s).key;
  }

  static EventStatus _eventStatusFromString(String s) {
    return _statusMap[s] ?? EventStatus.scheduled;
  }

  static const _confirmMap = {
    'pending': ConfirmationStatus.pending,
    'confirmed': ConfirmationStatus.confirmed,
    'declined': ConfirmationStatus.declined,
  };

  static String _confirmToString(ConfirmationStatus s) {
    return _confirmMap.entries.firstWhere((e) => e.value == s).key;
  }

  static ConfirmationStatus _confirmFromString(String s) {
    return _confirmMap[s] ?? ConfirmationStatus.pending;
  }

  RaceEvent _eventFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final slotsRaw = d['crewSlots'] as List<dynamic>? ?? [];
    final slots = slotsRaw.map((raw) {
      final m = raw as Map<String, dynamic>;
      return CrewSlot(
        role: _roleFromString(m['role'] as String? ?? 'pro'),
        memberId: m['memberId'] as String?,
        memberName: m['memberName'] as String?,
        status: _confirmFromString(m['status'] as String? ?? 'pending'),
      );
    }).toList();

    TimeOfDay? startTime;
    if (d['startTimeHour'] != null) {
      startTime = TimeOfDay(
        hour: d['startTimeHour'] as int,
        minute: (d['startTimeMinute'] as int?) ?? 0,
      );
    }

    DateTime date;
    final dateRaw = d['date'];
    if (dateRaw is Timestamp) {
      date = dateRaw.toDate();
    } else if (dateRaw is String) {
      date = DateTime.tryParse(dateRaw) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return RaceEvent(
      id: doc.id,
      name: d['name'] as String? ?? '',
      date: date,
      seriesId: d['seriesId'] as String? ?? '',
      seriesName: d['seriesName'] as String? ?? '',
      status: _eventStatusFromString(d['status'] as String? ?? 'scheduled'),
      startTime: startTime,
      notes: d['notes'] as String?,
      crewSlots: slots,
      description: d['description'] as String? ?? '',
      location: d['location'] as String? ?? '',
      contact: d['contact'] as String? ?? '',
      extraInfo: d['extraInfo'] as String? ?? '',
      rcFleet: d['rcFleet'] as String? ?? '',
      raceCommittee: d['raceCommittee'] as String? ?? '',
    );
  }

  Map<String, dynamic> _eventToMap(RaceEvent event) {
    return {
      'name': event.name,
      'date': Timestamp.fromDate(event.date),
      'seriesId': event.seriesId,
      'seriesName': event.seriesName,
      'status': _eventStatusToString(event.status),
      'startTimeHour': event.startTime?.hour,
      'startTimeMinute': event.startTime?.minute,
      'notes': event.notes,
      'crewSlots': event.crewSlots
          .map((s) => {
                'role': _roleToString(s.role),
                'memberId': s.memberId,
                'memberName': s.memberName,
                'status': _confirmToString(s.status),
              })
          .toList(),
      'description': event.description,
      'location': event.location,
      'contact': event.contact,
      'extraInfo': event.extraInfo,
      'rcFleet': event.rcFleet,
      'raceCommittee': event.raceCommittee,
    };
  }

  SeriesDefinition _seriesFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    DateTime startDate;
    final startRaw = d['startDate'];
    if (startRaw is Timestamp) {
      startDate = startRaw.toDate();
    } else {
      startDate = DateTime.now();
    }
    DateTime endDate;
    final endRaw = d['endDate'];
    if (endRaw is Timestamp) {
      endDate = endRaw.toDate();
    } else {
      endDate = DateTime.now();
    }

    final colorValue = d['color'] as int? ?? Colors.blue.value;

    return SeriesDefinition(
      id: doc.id,
      name: d['name'] as String? ?? '',
      color: Color(colorValue),
      startDate: startDate,
      endDate: endDate,
      recurringWeekday: d['recurringWeekday'] as int?,
    );
  }

  Map<String, dynamic> _seriesToMap(SeriesDefinition series) {
    return {
      'name': series.name,
      'color': series.color.value,
      'startDate': Timestamp.fromDate(series.startDate),
      'endDate': Timestamp.fromDate(series.endDate),
      'recurringWeekday': series.recurringWeekday,
    };
  }

  // ── Streams ──

  @override
  Stream<List<RaceEvent>> watchUpcomingEvents() {
    return _eventsCol
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs.map(_eventFromDoc).toList());
  }

  @override
  Stream<List<MyAssignment>> watchMyAssignments(String userId) {
    return watchUpcomingEvents().map((events) {
      final now = DateTime.now().subtract(const Duration(days: 1));
      return events
          .where((e) => e.date.isAfter(now))
          .expand((event) {
            return event.crewSlots
                .where((slot) => slot.memberId == userId)
                .map((slot) => MyAssignment(
                      event: event,
                      role: slot.role,
                      status: slot.status,
                    ));
          })
          .toList();
    });
  }

  @override
  Stream<EventDetailData> watchEventDetail(String eventId) {
    return _eventsCol.doc(eventId).snapshots().asyncMap((snap) async {
      if (!snap.exists) {
        return EventDetailData(
          event: RaceEvent(
            id: eventId,
            name: 'Not found',
            date: DateTime.now(),
            seriesId: '',
            seriesName: '',
            status: EventStatus.scheduled,
          ),
        );
      }
      final event = _eventFromDoc(snap);

      // Fetch linked data
      String? courseName;
      String? weatherSummary;
      int incidentCount = 0;
      int completedChecklists = 0;

      if (event.notes != null && event.notes!.contains('courseId:')) {
        // Could look up course — simplified for now
      }

      try {
        final weatherSnap = await _firestore
            .collection('weather_logs')
            .where('eventId', isEqualTo: eventId)
            .limit(1)
            .get();
        if (weatherSnap.docs.isNotEmpty) {
          final wd = weatherSnap.docs.first.data();
          final entries = wd['entries'] as List<dynamic>? ?? [];
          if (entries.isNotEmpty) {
            final last = entries.last as Map<String, dynamic>;
            weatherSummary =
                '${last['windSpeedKnots'] ?? '?'}kt, ${last['seaState'] ?? '?'}';
          }
        }
      } catch (_) {}

      try {
        final incidentSnap = await _firestore
            .collection('race_incidents')
            .where('eventId', isEqualTo: eventId)
            .get();
        incidentCount = incidentSnap.docs.length;
      } catch (_) {}

      try {
        final checklistSnap = await _firestore
            .collection('checklist_completions')
            .where('eventId', isEqualTo: eventId)
            .get();
        completedChecklists = checklistSnap.docs.length;
      } catch (_) {}

      return EventDetailData(
        event: event,
        courseName: courseName,
        weatherSummary: weatherSummary,
        incidentCount: incidentCount,
        completedChecklists: completedChecklists,
      );
    });
  }

  @override
  Stream<List<SeriesDefinition>> watchSeries() {
    return _seriesCol
        .orderBy('startDate')
        .snapshots()
        .map((snap) => snap.docs.map(_seriesFromDoc).toList());
  }

  // ── Writes ──

  @override
  Future<void> saveEvent(RaceEvent event) async {
    await _eventsCol.doc(event.id).set(_eventToMap(event), SetOptions(merge: true));
    _audit.log(
      action: 'save_event',
      entityType: 'race_event',
      entityId: event.id,
      category: 'crew',
      details: {'name': event.name, 'status': event.status.name},
    );
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    await _eventsCol.doc(eventId).delete();
    _audit.log(
      action: 'delete_event',
      entityType: 'race_event',
      entityId: eventId,
      category: 'crew',
    );
  }

  @override
  Future<void> bulkCancelEvents(List<String> eventIds) async {
    final batch = _firestore.batch();
    for (final id in eventIds) {
      batch.update(_eventsCol.doc(id), {'status': 'cancelled'});
    }
    await batch.commit();
  }

  @override
  Future<void> updateCrewSlots(String eventId, List<CrewSlot> slots) async {
    await _eventsCol.doc(eventId).update({
      'crewSlots': slots
          .map((s) => {
                'role': _roleToString(s.role),
                'memberId': s.memberId,
                'memberName': s.memberName,
                'status': _confirmToString(s.status),
              })
          .toList(),
    });
  }

  @override
  Future<void> updateConfirmation(
    String eventId,
    CrewRole role,
    ConfirmationStatus status, {
    String? reason,
  }) async {
    final doc = await _eventsCol.doc(eventId).get();
    if (!doc.exists) return;
    final event = _eventFromDoc(doc);
    final slots = event.crewSlots
        .map((slot) => slot.role == role ? slot.copyWith(status: status) : slot)
        .toList();
    final updates = <String, dynamic>{
      'crewSlots': slots
          .map((s) => {
                'role': _roleToString(s.role),
                'memberId': s.memberId,
                'memberName': s.memberName,
                'status': _confirmToString(s.status),
              })
          .toList(),
    };
    if (reason != null) {
      updates['notes'] = 'Decline note: $reason';
    }
    await _eventsCol.doc(eventId).update(updates);
  }

  @override
  Future<void> saveSeries(SeriesDefinition series) async {
    await _seriesCol.doc(series.id).set(_seriesToMap(series), SetOptions(merge: true));
    _audit.log(
      action: 'save_series',
      entityType: 'season_series',
      entityId: series.id,
      category: 'crew',
      details: {'name': series.name},
    );
  }

  @override
  Future<void> generateSeriesEvents(String seriesId) async {
    final seriesDoc = await _seriesCol.doc(seriesId).get();
    if (!seriesDoc.exists) return;
    final series = _seriesFromDoc(seriesDoc);
    if (series.recurringWeekday == null) return;

    // Fetch existing events for this series to avoid duplicates
    final existingSnap = await _eventsCol
        .where('seriesId', isEqualTo: seriesId)
        .get();
    final existingDates = existingSnap.docs.map((d) {
      final event = _eventFromDoc(d);
      return '${event.date.year}-${event.date.month}-${event.date.day}';
    }).toSet();

    final batch = _firestore.batch();
    var cursor = series.startDate;
    while (!cursor.isAfter(series.endDate)) {
      if (cursor.weekday == series.recurringWeekday) {
        final key = '${cursor.year}-${cursor.month}-${cursor.day}';
        if (!existingDates.contains(key)) {
          final id = 'e_${series.id}_${cursor.millisecondsSinceEpoch}';
          batch.set(_eventsCol.doc(id), _eventToMap(RaceEvent(
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
          )));
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    await batch.commit();
  }

  /// Parse a time string like "1:00 PM", "6:00 PM", "TBD", "?" into a TimeOfDay.
  static TimeOfDay? _parseTime(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty || s == 'TBD' || s == '?') return null;

    // Try "H:MM AM/PM" format
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
        .firstMatch(s);
    if (match != null) {
      var hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final amPm = match.group(3)!.toUpperCase();
      if (amPm == 'PM' && hour != 12) hour += 12;
      if (amPm == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  /// Parse date strings like "Sunday, February 08, 2026" or "Saturday, June 6,2026"
  static DateTime? _parseMpycDate(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;

    // Remove leading day name (e.g. "Sunday, ")
    final commaIdx = s.indexOf(',');
    if (commaIdx > 0) {
      s = s.substring(commaIdx + 1).trim();
    }

    // Normalize: "June 6,2026" -> "June 6, 2026"
    s = s.replaceAll(RegExp(r',\s*'), ', ');

    // Try "Month DD, YYYY"
    final months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };

    final match = RegExp(r'(\w+)\s+(\d{1,2}),?\s*(\d{4})').firstMatch(s);
    if (match != null) {
      final month = months[match.group(1)!.toLowerCase()];
      final day = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    // Fallback to DateTime.tryParse
    return DateTime.tryParse(raw);
  }

  /// Derive a series name from the event title.
  static String _deriveSeries(String name, String description) {
    final lower = name.toLowerCase();
    if (lower.contains('sunset series')) return 'Sunset Series';
    if (lower.contains('phrf spring')) return 'PHRF Spring';
    if (lower.contains('phrf fall')) return 'PHRF Fall';
    if (lower.contains('one design spring')) return 'One Design Spring';
    if (lower.contains('one design summer')) return 'One Design Summer';
    if (lower.contains('one design fall')) return 'One Design Fall';
    if (lower.contains('mbyra')) return 'MBYRA';
    if (lower.contains('commodore')) return 'Commodores Regatta';
    if (lower.contains('national')) return 'Nationals';
    if (lower.contains('youth') || lower.contains('junior')) return 'Youth';
    if (lower.contains('clinic') || lower.contains('training')) return 'Training';
    return 'Special Events';
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
      final name = (row['Title'] ?? row['Event Name'] ?? '').trim();
      final dateRaw = (row['Start Date'] ?? row['Date'] ?? '').trim();
      final timeRaw = (row['Start Time'] ?? '').trim();
      final description = (row['Description'] ?? '').trim();
      final location = (row['Location'] ?? '').trim();
      final contact = (row['Contact'] ?? '').trim();
      final extraInfo = (row['Extra Info'] ?? '').trim();
      final rcFleet = (row['RC Fleet'] ?? '').trim();
      final raceCommittee = (row['Race Committee'] ?? '').trim();

      // Skip empty/filler rows (month headers, blank rows)
      if (name.isEmpty || dateRaw.isEmpty) {
        if (name.isNotEmpty) {
          // Might be a month header like "JANUARY" — skip silently
        }
        skipped++;
        continue;
      }

      // Skip the revision header row
      if (name.toLowerCase().startsWith('revision')) {
        skipped++;
        continue;
      }

      final date = _parseMpycDate(dateRaw);
      if (date == null) {
        errors.add('Invalid date for "$name": $dateRaw');
        skipped++;
        continue;
      }

      final startTime = _parseTime(timeRaw);
      final seriesName = _deriveSeries(name, description);
      final seriesId = seriesName.toLowerCase().replaceAll(' ', '_');

      // Check for duplicates by name + date
      final dupSnap = await _eventsCol
          .where('name', isEqualTo: name)
          .get();
      final duplicate = dupSnap.docs.where((d) {
        final e = _eventFromDoc(d);
        return e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day;
      }).firstOrNull;

      if (duplicate != null) {
        // Update existing event with all CSV fields
        await _eventsCol.doc(duplicate.id).update({
          'seriesId': seriesId,
          'seriesName': seriesName,
          'startTimeHour': startTime?.hour,
          'startTimeMinute': startTime?.minute,
          'description': description,
          'location': location,
          'contact': contact,
          'extraInfo': extraInfo,
          'rcFleet': rcFleet,
          'raceCommittee': raceCommittee,
        });
        updated++;
      } else {
        final id = 'import_${date.millisecondsSinceEpoch}_$created';
        await _eventsCol.doc(id).set(_eventToMap(RaceEvent(
          id: id,
          name: name,
          date: date,
          seriesId: seriesId,
          seriesName: seriesName,
          status: EventStatus.scheduled,
          startTime: startTime,
          description: description,
          location: location,
          contact: contact,
          extraInfo: extraInfo,
          rcFleet: rcFleet,
          raceCommittee: raceCommittee,
          crewSlots: const [
            CrewSlot(role: CrewRole.pro),
            CrewSlot(role: CrewRole.signalBoat),
            CrewSlot(role: CrewRole.markBoat),
            CrewSlot(role: CrewRole.safetyBoat),
          ],
        )));
        created++;
      }
    }

    return CalendarImportResult(
      created: created,
      updated: updated,
      skipped: skipped,
      errors: errors,
    );
  }

  @override
  Future<List<Map<String, String>>> exportCalendar() async {
    final snap = await _eventsCol.orderBy('date').get();
    final rows = <Map<String, String>>[];

    for (final doc in snap.docs) {
      final event = _eventFromDoc(doc);
      final dateStr = _formatExportDate(event.date);
      final timeStr = event.startTime != null
          ? _formatExportTime(event.startTime!)
          : '';

      rows.add({
        'Title': event.name,
        'Start Date': dateStr,
        'Start Time': timeStr,
        'Description': event.description,
        'Location': event.location,
        'Contact': event.contact,
        'Extra Info': event.extraInfo,
        'RC Fleet': event.rcFleet,
        'Race Committee': event.raceCommittee,
      });
    }
    return rows;
  }

  static String _formatExportDate(DateTime d) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final dayName = days[d.weekday - 1];
    final monthName = months[d.month];
    final dayNum = d.day.toString().padLeft(2, '0');
    return '$dayName, $monthName $dayNum, ${d.year}';
  }

  static String _formatExportTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final amPm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $amPm';
  }

  @override
  Future<void> notifyCrew({
    required String eventId,
    required bool onlyUnconfirmed,
  }) async {
    final callable = _functions.httpsCallable('sendCrewNotification');
    await callable.call<void>({
      'eventId': eventId,
      'onlyUnconfirmed': onlyUnconfirmed,
    });
  }

  @override
  Future<List<String>> suggestFairAssignments(String eventId) async {
    // Query all events to compute duty counts
    final snap = await _eventsCol.get();
    final dutyCounts = <String, int>{};
    for (final doc in snap.docs) {
      final event = _eventFromDoc(doc);
      for (final slot in event.crewSlots) {
        if (slot.memberName != null) {
          dutyCounts.update(
              slot.memberName!, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    // Also pull in all RC-qualified members from the members collection
    try {
      final membersSnap = await _firestore
          .collection('members')
          .where('memberTags', arrayContains: 'rc_qualified')
          .get();
      for (final doc in membersSnap.docs) {
        final data = doc.data();
        final name =
            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        if (name.isNotEmpty) {
          dutyCounts.putIfAbsent(name, () => 0);
        }
      }
    } catch (_) {}

    final sorted = dutyCounts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.take(4).map((e) => e.key).toList();
  }
}
