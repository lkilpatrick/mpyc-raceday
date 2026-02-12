import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/race_session.dart';
import '../data/rc_race_repository.dart';

final rcRaceRepositoryProvider = Provider<RcRaceRepository>((ref) {
  return RcRaceRepository();
});

final todaysSessionProvider = StreamProvider<RaceSession?>((ref) {
  return ref.watch(rcRaceRepositoryProvider).watchTodaysSession();
});

final sessionByIdProvider =
    StreamProvider.family<RaceSession?, String>((ref, eventId) {
  return ref.watch(rcRaceRepositoryProvider).watchSession(eventId);
});

final finalizedSessionsProvider = FutureProvider<List<RaceSession>>((ref) {
  return ref.watch(rcRaceRepositoryProvider).getFinalizedSessions();
});
