import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/timing_models.dart';
import '../data/timing_repository_impl.dart';
import '../domain/signal_controller.dart';
import '../domain/timing_repository.dart';

final timingRepositoryProvider = Provider<TimingRepository>((ref) {
  return TimingRepositoryImpl();
});

final signalControllerProvider = Provider<SignalController>((ref) {
  return ManualSignalController();
});

final raceStartsProvider =
    StreamProvider.family<List<RaceStart>, String>((ref, eventId) {
  return ref.watch(timingRepositoryProvider).watchRaceStarts(eventId);
});

final finishRecordsProvider =
    StreamProvider.family<List<FinishRecord>, String>((ref, raceStartId) {
  return ref.watch(timingRepositoryProvider).watchFinishRecords(raceStartId);
});

final handicapRatingsProvider = FutureProvider<List<HandicapRating>>((ref) {
  return ref.watch(timingRepositoryProvider).getHandicapRatings();
});
