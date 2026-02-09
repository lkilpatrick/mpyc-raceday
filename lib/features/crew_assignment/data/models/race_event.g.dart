// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'race_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CrewAssignment _$CrewAssignmentFromJson(Map<String, dynamic> json) =>
    _CrewAssignment(
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String,
      role: $enumDecode(_$CrewRoleEnumMap, json['role']),
      confirmed: json['confirmed'] as bool,
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
      declineReason: json['declineReason'] as String?,
    );

Map<String, dynamic> _$CrewAssignmentToJson(_CrewAssignment instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'memberName': instance.memberName,
      'role': _$CrewRoleEnumMap[instance.role]!,
      'confirmed': instance.confirmed,
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
      'declineReason': instance.declineReason,
    };

const _$CrewRoleEnumMap = {
  CrewRole.pro: 'pro',
  CrewRole.assistantPro: 'assistantPro',
  CrewRole.signalBoat: 'signalBoat',
  CrewRole.markBoat: 'markBoat',
  CrewRole.finishBoat: 'finishBoat',
  CrewRole.safety: 'safety',
  CrewRole.other: 'other',
};

_RaceEvent _$RaceEventFromJson(Map<String, dynamic> json) => _RaceEvent(
  id: json['id'] as String,
  eventName: json['eventName'] as String,
  eventDate: DateTime.parse(json['eventDate'] as String),
  seriesName: json['seriesName'] as String,
  assignedCrew: (json['assignedCrew'] as List<dynamic>)
      .map((e) => CrewAssignment.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: $enumDecode(_$RaceEventStatusEnumMap, json['status']),
  courseId: json['courseId'] as String?,
  weatherLogId: json['weatherLogId'] as String?,
  notes: json['notes'] as String,
  sunsetTime: DateTime.parse(json['sunsetTime'] as String),
);

Map<String, dynamic> _$RaceEventToJson(_RaceEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventName': instance.eventName,
      'eventDate': instance.eventDate.toIso8601String(),
      'seriesName': instance.seriesName,
      'assignedCrew': instance.assignedCrew,
      'status': _$RaceEventStatusEnumMap[instance.status]!,
      'courseId': instance.courseId,
      'weatherLogId': instance.weatherLogId,
      'notes': instance.notes,
      'sunsetTime': instance.sunsetTime.toIso8601String(),
    };

const _$RaceEventStatusEnumMap = {
  RaceEventStatus.upcoming: 'upcoming',
  RaceEventStatus.active: 'active',
  RaceEventStatus.completed: 'completed',
  RaceEventStatus.cancelled: 'cancelled',
};
