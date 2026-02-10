class Fleet {
  const Fleet({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
  });

  final String id;
  final String name;
  final String type; // "one_design" or "handicap"
  final String description;
}

class FleetCourseAssignment {
  const FleetCourseAssignment({
    required this.fleetId,
    required this.courseNumber,
    this.multiplier = 1,
  });

  final String fleetId;
  final String courseNumber;
  final int multiplier; // 1, 2, or 3 (only if course.canMultiply)
}
