class Boat {
  const Boat({
    required this.id,
    required this.sailNumber,
    required this.boatName,
    required this.ownerName,
    required this.boatClass,
    this.phrfRating,
    this.lastRacedAt,
    this.raceCount = 0,
    this.isActive = true,
    this.isRCFleet = false,
    this.phone,
    this.email,
    this.fleet,
  });

  final String id;
  final String sailNumber;
  final String boatName;
  final String ownerName;
  final String boatClass;
  final int? phrfRating;
  final DateTime? lastRacedAt;
  final int raceCount;
  final bool isActive;
  final bool isRCFleet;
  final String? phone;
  final String? email;
  final String? fleet;
}
