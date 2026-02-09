// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'race_incident.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BoatInvolved _$BoatInvolvedFromJson(Map<String, dynamic> json) =>
    _BoatInvolved(
      sailNumber: json['sailNumber'] as String,
      boatName: json['boatName'] as String,
      skipperName: json['skipperName'] as String,
      role: $enumDecode(_$BoatInvolvedRoleEnumMap, json['role']),
    );

Map<String, dynamic> _$BoatInvolvedToJson(_BoatInvolved instance) =>
    <String, dynamic>{
      'sailNumber': instance.sailNumber,
      'boatName': instance.boatName,
      'skipperName': instance.skipperName,
      'role': _$BoatInvolvedRoleEnumMap[instance.role]!,
    };

const _$BoatInvolvedRoleEnumMap = {
  BoatInvolvedRole.protesting: 'protesting',
  BoatInvolvedRole.protested: 'protested',
  BoatInvolvedRole.witness: 'witness',
};

_RaceIncident _$RaceIncidentFromJson(Map<String, dynamic> json) =>
    _RaceIncident(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      raceNumber: (json['raceNumber'] as num).toInt(),
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      reportedBy: json['reportedBy'] as String,
      incidentTime: DateTime.parse(json['incidentTime'] as String),
      description: json['description'] as String,
      locationOnCourse: $enumDecode(
        _$CourseLocationOnIncidentEnumMap,
        json['locationOnCourse'],
      ),
      involvedBoats: (json['involvedBoats'] as List<dynamic>)
          .map((e) => BoatInvolved.fromJson(e as Map<String, dynamic>))
          .toList(),
      rulesAlleged: (json['rulesAlleged'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      status: $enumDecode(_$RaceIncidentStatusEnumMap, json['status']),
      hearingDate: json['hearingDate'] == null
          ? null
          : DateTime.parse(json['hearingDate'] as String),
      resolution: json['resolution'] as String,
      penaltyApplied: json['penaltyApplied'] as String,
      witnesses: (json['witnesses'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      attachments: (json['attachments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$RaceIncidentToJson(_RaceIncident instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'raceNumber': instance.raceNumber,
      'reportedAt': instance.reportedAt.toIso8601String(),
      'reportedBy': instance.reportedBy,
      'incidentTime': instance.incidentTime.toIso8601String(),
      'description': instance.description,
      'locationOnCourse':
          _$CourseLocationOnIncidentEnumMap[instance.locationOnCourse]!,
      'involvedBoats': instance.involvedBoats,
      'rulesAlleged': instance.rulesAlleged,
      'status': _$RaceIncidentStatusEnumMap[instance.status]!,
      'hearingDate': instance.hearingDate?.toIso8601String(),
      'resolution': instance.resolution,
      'penaltyApplied': instance.penaltyApplied,
      'witnesses': instance.witnesses,
      'attachments': instance.attachments,
    };

const _$CourseLocationOnIncidentEnumMap = {
  CourseLocationOnIncident.startLine: 'startLine',
  CourseLocationOnIncident.windwardMark: 'windwardMark',
  CourseLocationOnIncident.gate: 'gate',
  CourseLocationOnIncident.leewardMark: 'leewardMark',
  CourseLocationOnIncident.reachingMark: 'reachingMark',
  CourseLocationOnIncident.openWater: 'openWater',
};

const _$RaceIncidentStatusEnumMap = {
  RaceIncidentStatus.reported: 'reported',
  RaceIncidentStatus.protestFiled: 'protestFiled',
  RaceIncidentStatus.hearingScheduled: 'hearingScheduled',
  RaceIncidentStatus.hearingComplete: 'hearingComplete',
  RaceIncidentStatus.resolved: 'resolved',
  RaceIncidentStatus.withdrawn: 'withdrawn',
};
