import '../data/models/timing_models.dart';

abstract class TimingRepository {
  const TimingRepository();

  // Race starts
  Stream<List<RaceStart>> watchRaceStarts(String eventId);
  Stream<RaceStart?> watchRaceStartById(String raceStartId);
  Future<RaceStart> createRaceStart(RaceStart start);
  Future<void> updateRaceStart(RaceStart start);

  // Finish records
  Stream<List<FinishRecord>> watchFinishRecords(String raceStartId);
  Future<FinishRecord> recordFinish(FinishRecord record);
  Future<void> updateFinishRecord(FinishRecord record);
  Future<void> deleteFinishRecord(String id);

  // Handicap ratings
  Future<List<HandicapRating>> getHandicapRatings();

  // Publish results
  Future<void> publishResults(String raceStartId, List<FinishRecord> results);
}
