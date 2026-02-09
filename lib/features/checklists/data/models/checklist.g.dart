// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChecklistItem _$ChecklistItemFromJson(Map<String, dynamic> json) =>
    _ChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      requiresPhoto: json['requiresPhoto'] as bool,
      requiresNote: json['requiresNote'] as bool,
      isCritical: json['isCritical'] as bool,
      order: (json['order'] as num).toInt(),
    );

Map<String, dynamic> _$ChecklistItemToJson(_ChecklistItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'requiresPhoto': instance.requiresPhoto,
      'requiresNote': instance.requiresNote,
      'isCritical': instance.isCritical,
      'order': instance.order,
    };

_Checklist _$ChecklistFromJson(Map<String, dynamic> json) => _Checklist(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$ChecklistTypeEnumMap, json['type']),
  items: (json['items'] as List<dynamic>)
      .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  version: (json['version'] as num).toInt(),
  lastModifiedBy: json['lastModifiedBy'] as String,
  lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$ChecklistToJson(_Checklist instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$ChecklistTypeEnumMap[instance.type]!,
      'items': instance.items,
      'version': instance.version,
      'lastModifiedBy': instance.lastModifiedBy,
      'lastModifiedAt': instance.lastModifiedAt.toIso8601String(),
      'isActive': instance.isActive,
    };

const _$ChecklistTypeEnumMap = {
  ChecklistType.preRace: 'preRace',
  ChecklistType.postRace: 'postRace',
  ChecklistType.safety: 'safety',
  ChecklistType.custom: 'custom',
};

_CompletedItem _$CompletedItemFromJson(Map<String, dynamic> json) =>
    _CompletedItem(
      itemId: json['itemId'] as String,
      checked: json['checked'] as bool,
      note: json['note'] as String?,
      photoUrl: json['photoUrl'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$CompletedItemToJson(_CompletedItem instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'checked': instance.checked,
      'note': instance.note,
      'photoUrl': instance.photoUrl,
      'timestamp': instance.timestamp.toIso8601String(),
    };

_ChecklistCompletion _$ChecklistCompletionFromJson(Map<String, dynamic> json) =>
    _ChecklistCompletion(
      id: json['id'] as String,
      checklistId: json['checklistId'] as String,
      eventId: json['eventId'] as String,
      completedBy: json['completedBy'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      items: (json['items'] as List<dynamic>)
          .map((e) => CompletedItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      signOffBy: json['signOffBy'] as String?,
      signOffAt: json['signOffAt'] == null
          ? null
          : DateTime.parse(json['signOffAt'] as String),
      status: $enumDecode(_$ChecklistCompletionStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$ChecklistCompletionToJson(
  _ChecklistCompletion instance,
) => <String, dynamic>{
  'id': instance.id,
  'checklistId': instance.checklistId,
  'eventId': instance.eventId,
  'completedBy': instance.completedBy,
  'startedAt': instance.startedAt.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'items': instance.items,
  'signOffBy': instance.signOffBy,
  'signOffAt': instance.signOffAt?.toIso8601String(),
  'status': _$ChecklistCompletionStatusEnumMap[instance.status]!,
};

const _$ChecklistCompletionStatusEnumMap = {
  ChecklistCompletionStatus.inProgress: 'inProgress',
  ChecklistCompletionStatus.completedPendingSignoff: 'completedPendingSignoff',
  ChecklistCompletionStatus.signedOff: 'signedOff',
};
