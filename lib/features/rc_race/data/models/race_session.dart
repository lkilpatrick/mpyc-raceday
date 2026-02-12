import 'package:cloud_firestore/cloud_firestore.dart';

/// Status state machine for a race session.
/// setup → checkin_open → start_pending → running → scoring → review → finalized
/// Also: abandoned (terminal)
enum RaceSessionStatus {
  setup,
  checkinOpen,
  startPending,
  running,
  scoring,
  review,
  finalized,
  abandoned;

  String get label => switch (this) {
        setup => 'Setup',
        checkinOpen => 'Check-In Open',
        startPending => 'Start Pending',
        running => 'Racing',
        scoring => 'Scoring',
        review => 'Review',
        finalized => 'Finalized',
        abandoned => 'Abandoned',
      };

  String get firestoreValue => switch (this) {
        setup => 'setup',
        checkinOpen => 'checkin_open',
        startPending => 'start_pending',
        running => 'running',
        scoring => 'scoring',
        review => 'review',
        finalized => 'finalized',
        abandoned => 'abandoned',
      };

  static RaceSessionStatus fromString(String s) => switch (s) {
        'setup' => setup,
        'checkin_open' => checkinOpen,
        'start_pending' => startPending,
        'running' => running,
        'scoring' => scoring,
        'review' => review,
        'finalized' => finalized,
        'abandoned' => abandoned,
        _ => setup,
      };

  /// Which step index (0-based) this status maps to in the stepper.
  int get stepIndex => switch (this) {
        setup => 0,
        checkinOpen => 1,
        startPending => 2,
        running => 3,
        scoring => 4,
        review => 5,
        finalized => 5,
        abandoned => 4,
      };

  bool get isTerminal => this == finalized || this == abandoned;
}

/// Boat status within a race session.
enum BoatRaceStatus {
  notCheckedIn,
  checkedIn,
  finished,
  dnf;

  String get label => switch (this) {
        notCheckedIn => 'Not Checked In',
        checkedIn => 'Checked In',
        finished => 'Finished',
        dnf => 'DNF',
      };
}

/// Lightweight model wrapping a race_events document for the RC flow.
class RaceSession {
  const RaceSession({
    required this.id,
    required this.name,
    required this.date,
    required this.status,
    this.courseId,
    this.courseName,
    this.courseNumber,
    this.raceNumber = 1,
    this.fleetClass,
    this.raceStartId,
    this.startTime,
    this.startMethod,
    this.abandonedAt,
    this.abandonedReason,
    this.finalizedAt,
    this.clubspotReady = false,
    this.notes,
    this.isDemo = false,
    this.checkinsClosed = false,
  });

  final String id;
  final String name;
  final DateTime date;
  final RaceSessionStatus status;
  final String? courseId;
  final String? courseName;
  final String? courseNumber;
  final int raceNumber;
  final String? fleetClass;
  final String? raceStartId;
  final DateTime? startTime;
  final String? startMethod; // 'horn' or 'manual'
  final DateTime? abandonedAt;
  final String? abandonedReason;
  final DateTime? finalizedAt;
  final bool clubspotReady;
  final String? notes;
  final bool isDemo;
  final bool checkinsClosed;

  factory RaceSession.fromDoc(String id, Map<String, dynamic> d) {
    return RaceSession(
      id: id,
      name: d['name'] as String? ?? 'Race Day',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: RaceSessionStatus.fromString(d['status'] as String? ?? 'setup'),
      courseId: d['courseId'] as String?,
      courseName: d['courseName'] as String?,
      courseNumber: d['courseNumber'] as String?,
      raceNumber: d['raceNumber'] as int? ?? 1,
      fleetClass: d['fleetClass'] as String?,
      raceStartId: d['raceStartId'] as String?,
      startTime: (d['startTime'] as Timestamp?)?.toDate(),
      startMethod: d['startMethod'] as String?,
      abandonedAt: (d['abandonedAt'] as Timestamp?)?.toDate(),
      abandonedReason: d['abandonedReason'] as String?,
      finalizedAt: (d['finalizedAt'] as Timestamp?)?.toDate(),
      clubspotReady: d['clubspotReady'] as bool? ?? false,
      notes: d['notes'] as String?,
      isDemo: d['isDemo'] as bool? ?? false,
      checkinsClosed: d['checkinsClosed'] as bool? ?? false,
    );
  }

  RaceSession copyWith({
    String? id,
    String? name,
    DateTime? date,
    RaceSessionStatus? status,
    String? courseId,
    String? courseName,
    String? courseNumber,
    int? raceNumber,
    String? fleetClass,
    String? raceStartId,
    DateTime? startTime,
    String? startMethod,
    DateTime? abandonedAt,
    String? abandonedReason,
    DateTime? finalizedAt,
    bool? clubspotReady,
    String? notes,
    bool? isDemo,
    bool? checkinsClosed,
  }) {
    return RaceSession(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      status: status ?? this.status,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      courseNumber: courseNumber ?? this.courseNumber,
      raceNumber: raceNumber ?? this.raceNumber,
      fleetClass: fleetClass ?? this.fleetClass,
      raceStartId: raceStartId ?? this.raceStartId,
      startTime: startTime ?? this.startTime,
      startMethod: startMethod ?? this.startMethod,
      abandonedAt: abandonedAt ?? this.abandonedAt,
      abandonedReason: abandonedReason ?? this.abandonedReason,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      clubspotReady: clubspotReady ?? this.clubspotReady,
      notes: notes ?? this.notes,
      isDemo: isDemo ?? this.isDemo,
      checkinsClosed: checkinsClosed ?? this.checkinsClosed,
    );
  }
}
