import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/checklists_repository_impl.dart';
import '../data/models/checklist.dart';
import '../domain/checklists_repository.dart';

final checklistsRepositoryProvider = Provider<ChecklistsRepository>((ref) {
  return ChecklistsRepositoryImpl();
});

final checklistTemplatesProvider = StreamProvider<List<Checklist>>((ref) {
  return ref.watch(checklistsRepositoryProvider).watchTemplates();
});

final activeCompletionsProvider =
    StreamProvider<List<ChecklistCompletion>>((ref) {
  return ref.watch(checklistsRepositoryProvider).watchActiveCompletions();
});

final completionProvider =
    StreamProvider.family<ChecklistCompletion, String>((ref, completionId) {
  return ref.watch(checklistsRepositoryProvider).watchCompletion(completionId);
});

final completionHistoryProvider =
    StreamProvider<List<ChecklistCompletion>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  return ref.watch(checklistsRepositoryProvider).watchCompletionHistory(
        userId: userId,
      );
});

final allCompletionHistoryProvider =
    StreamProvider<List<ChecklistCompletion>>((ref) {
  return ref.watch(checklistsRepositoryProvider).watchCompletionHistory();
});
