import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist.freezed.dart';
part 'checklist.g.dart';

enum ChecklistType { preRace, postRace, safety, custom }

@freezed
class ChecklistItem with _$ChecklistItem {
  const factory ChecklistItem({
    required String id,
    required String title,
    required String description,
    required String category,
    required bool requiresPhoto,
    required bool requiresNote,
    required bool isCritical,
    required int order,
  }) = _ChecklistItem;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemFromJson(json);
}

@freezed
class Checklist with _$Checklist {
  const factory Checklist({
    required String id,
    required String name,
    required ChecklistType type,
    required List<ChecklistItem> items,
    required int version,
    required String lastModifiedBy,
    required DateTime lastModifiedAt,
    required bool isActive,
  }) = _Checklist;

  factory Checklist.fromJson(Map<String, dynamic> json) =>
      _$ChecklistFromJson(json);
}

@freezed
class CompletedItem with _$CompletedItem {
  const factory CompletedItem({
    required String itemId,
    required bool checked,
    String? note,
    String? photoUrl,
    required DateTime timestamp,
  }) = _CompletedItem;

  factory CompletedItem.fromJson(Map<String, dynamic> json) =>
      _$CompletedItemFromJson(json);
}

enum ChecklistCompletionStatus {
  inProgress,
  completedPendingSignoff,
  signedOff,
}

@freezed
class ChecklistCompletion with _$ChecklistCompletion {
  const factory ChecklistCompletion({
    required String id,
    required String checklistId,
    required String eventId,
    required String completedBy,
    required DateTime startedAt,
    DateTime? completedAt,
    required List<CompletedItem> items,
    String? signOffBy,
    DateTime? signOffAt,
    required ChecklistCompletionStatus status,
  }) = _ChecklistCompletion;

  factory ChecklistCompletion.fromJson(Map<String, dynamic> json) =>
      _$ChecklistCompletionFromJson(json);
}
