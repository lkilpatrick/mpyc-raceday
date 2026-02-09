import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/boat_checkin_repository_impl.dart';
import '../data/models/boat.dart';
import '../data/models/boat_checkin.dart';
import '../domain/boat_checkin_repository.dart';

final boatCheckinRepositoryProvider = Provider<BoatCheckinRepository>((ref) {
  return BoatCheckinRepositoryImpl();
});

final eventCheckinsProvider =
    StreamProvider.family<List<BoatCheckin>, String>((ref, eventId) {
  return ref.watch(boatCheckinRepositoryProvider).watchCheckins(eventId);
});

final checkinCountProvider =
    Provider.family<int, String>((ref, eventId) {
  return ref.watch(eventCheckinsProvider(eventId)).value?.length ?? 0;
});

final checkinsClosedProvider =
    StreamProvider.family<bool, String>((ref, eventId) {
  return ref.watch(boatCheckinRepositoryProvider).watchCheckinsClosed(eventId);
});

final fleetProvider = StreamProvider<List<Boat>>((ref) {
  return ref.watch(boatCheckinRepositoryProvider).watchFleet();
});

final boatsNotCheckedInProvider =
    FutureProvider.family<List<Boat>, String>((ref, eventId) {
  return ref.watch(boatCheckinRepositoryProvider).getBoatsNotCheckedIn(eventId);
});
