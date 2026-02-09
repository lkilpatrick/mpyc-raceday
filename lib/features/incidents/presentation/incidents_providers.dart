import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/incidents_repository_impl.dart';
import '../data/models/race_incident.dart';
import '../domain/incidents_repository.dart';

final incidentsRepositoryProvider = Provider<IncidentsRepository>((ref) {
  return IncidentsRepositoryImpl();
});

final allIncidentsProvider = StreamProvider<List<RaceIncident>>((ref) {
  return ref.watch(incidentsRepositoryProvider).watchIncidents();
});

final eventIncidentsProvider =
    StreamProvider.family<List<RaceIncident>, String>((ref, eventId) {
  return ref.watch(incidentsRepositoryProvider).watchIncidents(
    eventId: eventId.isEmpty ? null : eventId,
  );
});

final incidentDetailProvider =
    FutureProvider.family<RaceIncident?, String>((ref, id) {
  return ref.watch(incidentsRepositoryProvider).getIncident(id);
});
