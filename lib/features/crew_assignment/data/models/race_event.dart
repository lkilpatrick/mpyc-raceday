import 'package:freezed_annotation/freezed_annotation.dart';

part 'race_event.freezed.dart';
part 'race_event.g.dart';

enum CrewRole {
  pro,
  assistantPro,
  signalBoat,
  markBoat,
  finishBoat,
  safety,
  other,
}

@freezed
abstract class CrewAssignment with _$CrewAssignment {
  const factory CrewAssignment({
    required String memberId,
    required String memberName,
    required CrewRole role,
    required bool confirmed,
    DateTime? confirmedAt,
    String? declineReason,
  }) = _CrewAssignment;

  factory CrewAssignment.fromJson(Map<String, dynamic> json) =>
      _$CrewAssignmentFromJson(json);
}

enum RaceEventStatus { upcoming, active, completed, cancelled }

@freezed
abstract class RaceEvent with _$RaceEvent {
  const factory RaceEvent({
    required String id,
    required String eventName,
    required DateTime eventDate,
    required String seriesName,
    required List<CrewAssignment> assignedCrew,
    required RaceEventStatus status,
    String? courseId,
    String? weatherLogId,
    required String notes,
    required DateTime sunsetTime,
  }) = _RaceEvent;

  factory RaceEvent.fromJson(Map<String, dynamic> json) =>
      _$RaceEventFromJson(json);
}
