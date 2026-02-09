import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_request.freezed.dart';
part 'maintenance_request.g.dart';

enum MaintenancePriority { low, medium, high, critical }

enum MaintenanceStatus {
  reported,
  acknowledged,
  inProgress,
  awaitingParts,
  completed,
  deferred,
}

enum MaintenanceCategory {
  engine,
  electrical,
  hull,
  rigging,
  safety,
  electronics,
  general,
}

@freezed
class MaintenanceComment with _$MaintenanceComment {
  const factory MaintenanceComment({
    required String id,
    required String authorId,
    required String authorName,
    required String text,
    String? photoUrl,
    required DateTime createdAt,
  }) = _MaintenanceComment;

  factory MaintenanceComment.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceCommentFromJson(json);
}

@freezed
class MaintenanceRequest with _$MaintenanceRequest {
  const factory MaintenanceRequest({
    required String id,
    required String title,
    required String description,
    required MaintenancePriority priority,
    required String reportedBy,
    required DateTime reportedAt,
    String? assignedTo,
    required MaintenanceStatus status,
    required List<String> photos,
    DateTime? completedAt,
    String? completionNotes,
    required String boatName,
    required MaintenanceCategory category,
    double? estimatedCost,
    required List<MaintenanceComment> comments,
  }) = _MaintenanceRequest;

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceRequestFromJson(json);
}
