// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_broadcast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FleetBroadcast _$FleetBroadcastFromJson(Map<String, dynamic> json) =>
    _FleetBroadcast(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      sentBy: json['sentBy'] as String,
      message: json['message'] as String,
      type: $enumDecode(_$BroadcastTypeEnumMap, json['type']),
      sentAt: DateTime.parse(json['sentAt'] as String),
      deliveryCount: (json['deliveryCount'] as num).toInt(),
    );

Map<String, dynamic> _$FleetBroadcastToJson(_FleetBroadcast instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'sentBy': instance.sentBy,
      'message': instance.message,
      'type': _$BroadcastTypeEnumMap[instance.type]!,
      'sentAt': instance.sentAt.toIso8601String(),
      'deliveryCount': instance.deliveryCount,
    };

const _$BroadcastTypeEnumMap = {
  BroadcastType.courseSelection: 'courseSelection',
  BroadcastType.postponement: 'postponement',
  BroadcastType.abandonment: 'abandonment',
  BroadcastType.courseChange: 'courseChange',
  BroadcastType.general: 'general',
};
