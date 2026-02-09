import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/crew_assignment_repository_impl.dart';
import '../domain/crew_assignment_repository.dart';

final crewAssignmentRepositoryProvider = Provider<CrewAssignmentRepository>((
  ref,
) {
  return CrewAssignmentRepositoryImpl();
});

final currentUserIdProvider = Provider<String>((ref) {
  return FirebaseAuth.instance.currentUser?.uid ?? '';
});

final upcomingEventsProvider = StreamProvider<List<RaceEvent>>((ref) {
  return ref.watch(crewAssignmentRepositoryProvider).watchUpcomingEvents();
});

final myAssignmentsProvider = StreamProvider<List<MyAssignment>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref.watch(crewAssignmentRepositoryProvider).watchMyAssignments(userId);
});

final eventDetailProvider = StreamProvider.family<EventDetailData, String>((
  ref,
  eventId,
) {
  return ref.watch(crewAssignmentRepositoryProvider).watchEventDetail(eventId);
});

final seriesProvider = StreamProvider<List<SeriesDefinition>>((ref) {
  return ref.watch(crewAssignmentRepositoryProvider).watchSeries();
});

final nextDutyProvider = Provider<AsyncValue<MyAssignment?>>((ref) {
  final assignments = ref.watch(myAssignmentsProvider);
  return assignments.whenData((items) {
    if (items.isEmpty) return null;
    final sorted = [...items]
      ..sort((a, b) => a.event.date.compareTo(b.event.date));
    return sorted.first;
  });
});
