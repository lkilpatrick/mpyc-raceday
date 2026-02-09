class BoatCheckin {
  const BoatCheckin({
    required this.id,
    required this.eventId,
    required this.boatId,
    required this.sailNumber,
    required this.boatName,
    required this.skipperName,
    required this.boatClass,
    required this.checkedInAt,
    required this.checkedInBy,
    required this.crewCount,
    this.crewNames = const [],
    required this.safetyEquipmentVerified,
    this.phrfRating,
    this.notes = '',
  });

  final String id;
  final String eventId;
  final String boatId;
  final String sailNumber;
  final String boatName;
  final String skipperName;
  final String boatClass;
  final DateTime checkedInAt;
  final String checkedInBy;
  final int crewCount;
  final List<String> crewNames;
  final bool safetyEquipmentVerified;
  final int? phrfRating;
  final String notes;
}
