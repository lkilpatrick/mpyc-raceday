// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditLog _$AuditLogFromJson(Map<String, dynamic> json) => _AuditLog(
  id: json['id'] as String,
  userId: json['userId'] as String,
  action: json['action'] as String,
  entityType: json['entityType'] as String,
  entityId: json['entityId'] as String,
  details: json['details'] as Map<String, dynamic>,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$AuditLogToJson(_AuditLog instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'action': instance.action,
  'entityType': instance.entityType,
  'entityId': instance.entityId,
  'details': instance.details,
  'timestamp': instance.timestamp.toIso8601String(),
};
