import 'package:freezed_annotation/freezed_annotation.dart';

part 'race_incident.freezed.dart';
part 'race_incident.g.dart';

enum CourseLocationOnIncident {
  startLine,
  windwardMark,
  gate,
  leewardMark,
  reachingMark,
  openWater,
}

enum BoatInvolvedRole { protesting, protested, witness }

@freezed
abstract class BoatInvolved with _$BoatInvolved {
  const factory BoatInvolved({
    required String sailNumber,
    required String boatName,
    required String skipperName,
    required BoatInvolvedRole role,
  }) = _BoatInvolved;

  factory BoatInvolved.fromJson(Map<String, dynamic> json) =>
      _$BoatInvolvedFromJson(json);
}

enum RaceIncidentStatus {
  reported,
  protestFiled,
  hearingScheduled,
  hearingComplete,
  resolved,
  withdrawn,
}

@freezed
abstract class RaceIncident with _$RaceIncident {
  const factory RaceIncident({
    required String id,
    required String eventId,
    required int raceNumber,
    required DateTime reportedAt,
    required String reportedBy,
    required DateTime incidentTime,
    required String description,
    required CourseLocationOnIncident locationOnCourse,
    required List<BoatInvolved> involvedBoats,
    required List<String> rulesAlleged,
    required RaceIncidentStatus status,
    DateTime? hearingDate,
    required String resolution,
    required String penaltyApplied,
    required List<String> witnesses,
    required List<String> attachments,
  }) = _RaceIncident;

  factory RaceIncident.fromJson(Map<String, dynamic> json) =>
      _$RaceIncidentFromJson(json);
}
