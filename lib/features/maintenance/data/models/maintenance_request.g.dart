// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MaintenanceComment _$MaintenanceCommentFromJson(Map<String, dynamic> json) =>
    _MaintenanceComment(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      text: json['text'] as String,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MaintenanceCommentToJson(_MaintenanceComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'text': instance.text,
      'photoUrl': instance.photoUrl,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_MaintenanceRequest _$MaintenanceRequestFromJson(Map<String, dynamic> json) =>
    _MaintenanceRequest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: $enumDecode(_$MaintenancePriorityEnumMap, json['priority']),
      reportedBy: json['reportedBy'] as String,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      assignedTo: json['assignedTo'] as String?,
      status: $enumDecode(_$MaintenanceStatusEnumMap, json['status']),
      photos: (json['photos'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      completionNotes: json['completionNotes'] as String?,
      boatName: json['boatName'] as String,
      category: $enumDecode(_$MaintenanceCategoryEnumMap, json['category']),
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      comments: (json['comments'] as List<dynamic>)
          .map((e) => MaintenanceComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MaintenanceRequestToJson(_MaintenanceRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'priority': _$MaintenancePriorityEnumMap[instance.priority]!,
      'reportedBy': instance.reportedBy,
      'reportedAt': instance.reportedAt.toIso8601String(),
      'assignedTo': instance.assignedTo,
      'status': _$MaintenanceStatusEnumMap[instance.status]!,
      'photos': instance.photos,
      'completedAt': instance.completedAt?.toIso8601String(),
      'completionNotes': instance.completionNotes,
      'boatName': instance.boatName,
      'category': _$MaintenanceCategoryEnumMap[instance.category]!,
      'estimatedCost': instance.estimatedCost,
      'comments': instance.comments,
    };

const _$MaintenancePriorityEnumMap = {
  MaintenancePriority.low: 'low',
  MaintenancePriority.medium: 'medium',
  MaintenancePriority.high: 'high',
  MaintenancePriority.critical: 'critical',
};

const _$MaintenanceStatusEnumMap = {
  MaintenanceStatus.reported: 'reported',
  MaintenanceStatus.acknowledged: 'acknowledged',
  MaintenanceStatus.inProgress: 'inProgress',
  MaintenanceStatus.awaitingParts: 'awaitingParts',
  MaintenanceStatus.completed: 'completed',
  MaintenanceStatus.deferred: 'deferred',
};

const _$MaintenanceCategoryEnumMap = {
  MaintenanceCategory.engine: 'engine',
  MaintenanceCategory.electrical: 'electrical',
  MaintenanceCategory.hull: 'hull',
  MaintenanceCategory.rigging: 'rigging',
  MaintenanceCategory.safety: 'safety',
  MaintenanceCategory.electronics: 'electronics',
  MaintenanceCategory.general: 'general',
};
