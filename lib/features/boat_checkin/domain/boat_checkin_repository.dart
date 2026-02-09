import '../data/models/boat.dart';
import '../data/models/boat_checkin.dart';

abstract class BoatCheckinRepository {
  const BoatCheckinRepository();

  // Check-ins
  Stream<List<BoatCheckin>> watchCheckins(String eventId);
  Future<void> checkInBoat(BoatCheckin checkin);
  Future<void> removeCheckin(String checkinId);
  Future<void> closeCheckins(String eventId);
  Stream<bool> watchCheckinsClosed(String eventId);

  // Fleet (master boat list)
  Stream<List<Boat>> watchFleet();
  Future<Boat?> getBoat(String boatId);
  Future<void> saveBoat(Boat boat);
  Future<void> deleteBoat(String boatId);
  Future<void> importFleetFromCsv(String csvContent);

  // Historical lookup
  Future<List<Boat>> getBoatsNotCheckedIn(String eventId);
}
