// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boat_checkin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BoatCheckin _$BoatCheckinFromJson(Map<String, dynamic> json) => _BoatCheckin(
  id: json['id'] as String,
  eventId: json['eventId'] as String,
  sailNumber: json['sailNumber'] as String,
  boatName: json['boatName'] as String,
  skipperName: json['skipperName'] as String,
  boatClass: json['boatClass'] as String,
  checkedInAt: DateTime.parse(json['checkedInAt'] as String),
  checkedInBy: json['checkedInBy'] as String,
  crewCount: (json['crewCount'] as num).toInt(),
  crewNames: (json['crewNames'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  safetyEquipmentVerified: json['safetyEquipmentVerified'] as bool,
  phrfRating: (json['phrfRating'] as num?)?.toInt(),
);

Map<String, dynamic> _$BoatCheckinToJson(_BoatCheckin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'sailNumber': instance.sailNumber,
      'boatName': instance.boatName,
      'skipperName': instance.skipperName,
      'boatClass': instance.boatClass,
      'checkedInAt': instance.checkedInAt.toIso8601String(),
      'checkedInBy': instance.checkedInBy,
      'crewCount': instance.crewCount,
      'crewNames': instance.crewNames,
      'safetyEquipmentVerified': instance.safetyEquipmentVerified,
      'phrfRating': instance.phrfRating,
    };
