import 'dart:typed_data';

import '../data/models/checklist.dart';

abstract class ChecklistsRepository {
  const ChecklistsRepository();

  // Templates
  Stream<List<Checklist>> watchTemplates();
  Future<Checklist?> getTemplate(String checklistId);
  Future<void> saveTemplate(Checklist checklist);
  Future<void> archiveTemplate(String checklistId);

  // Completions
  Stream<List<ChecklistCompletion>> watchActiveCompletions();
  Stream<ChecklistCompletion> watchCompletion(String completionId);
  Stream<List<ChecklistCompletion>> watchCompletionHistory({
    String? userId,
    String? checklistId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<ChecklistCompletion> startChecklist({
    required String checklistId,
    required String eventId,
    required String userId,
  });
  Future<void> updateItem({
    required String completionId,
    required String itemId,
    required bool checked,
    String? note,
    String? photoUrl,
  });
  Future<void> requestSignOff(String completionId);
  Future<void> signOff({
    required String completionId,
    required String signOffUserId,
  });

  // Photo upload
  Future<String> uploadPhoto({
    required String completionId,
    required String itemId,
    required Uint8List imageBytes,
  });

  // Seed
  Future<void> seedTemplates();
}
