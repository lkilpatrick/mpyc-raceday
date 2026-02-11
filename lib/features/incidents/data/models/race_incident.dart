enum CourseLocationOnIncident {
  startLine,
  windwardMark,
  gate,
  leewardMark,
  reachingMark,
  openWater,
}

class WeatherSnapshot {
  const WeatherSnapshot({
    this.windSpeedKts,
    this.windSpeedMph,
    this.windDirDeg,
    this.windDirLabel,
    this.gustKts,
    this.tempF,
    this.humidity,
    this.pressureInHg,
    this.source,
    this.stationName,
  });

  final double? windSpeedKts;
  final double? windSpeedMph;
  final int? windDirDeg;
  final String? windDirLabel;
  final double? gustKts;
  final double? tempF;
  final double? humidity;
  final double? pressureInHg;
  final String? source;
  final String? stationName;
}

enum BoatInvolvedRole { protesting, protested, witness }

class BoatInvolved {
  const BoatInvolved({
    required this.boatId,
    required this.sailNumber,
    required this.boatName,
    required this.skipperName,
    required this.role,
    this.boatClass = '',
  });

  final String boatId;
  final String sailNumber;
  final String boatName;
  final String skipperName;
  final BoatInvolvedRole role;
  final String boatClass;
}

enum RaceIncidentStatus {
  reported,
  protestFiled,
  hearingScheduled,
  hearingComplete,
  resolved,
  withdrawn,
}

class IncidentComment {
  const IncidentComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;
}

class HearingInfo {
  const HearingInfo({
    this.scheduledAt,
    this.location,
    this.juryMembers = const [],
    this.findingOfFact = '',
    this.rulesBroken = const [],
    this.penalty = '',
    this.decisionNotes = '',
  });

  final DateTime? scheduledAt;
  final String? location;
  final List<String> juryMembers;
  final String findingOfFact;
  final List<String> rulesBroken;
  final String penalty;
  final String decisionNotes;
}

class RaceIncident {
  const RaceIncident({
    required this.id,
    required this.eventId,
    this.eventName = '',
    required this.raceNumber,
    required this.reportedAt,
    required this.reportedBy,
    required this.incidentTime,
    required this.description,
    required this.locationOnCourse,
    this.locationDetail = '',
    this.courseName = '',
    required this.involvedBoats,
    this.rulesAlleged = const [],
    required this.status,
    this.hearing,
    this.resolution = '',
    this.penaltyApplied = '',
    this.witnesses = const [],
    this.attachments = const [],
    this.comments = const [],
    this.weatherSnapshot,
  });

  final String id;
  final String eventId;
  final String eventName;
  final int raceNumber;
  final DateTime reportedAt;
  final String reportedBy;
  final DateTime incidentTime;
  final String description;
  final CourseLocationOnIncident locationOnCourse;
  final String locationDetail;
  final String courseName;
  final List<BoatInvolved> involvedBoats;
  final List<String> rulesAlleged;
  final RaceIncidentStatus status;
  final HearingInfo? hearing;
  final String resolution;
  final String penaltyApplied;
  final List<String> witnesses;
  final List<String> attachments;
  final List<IncidentComment> comments;
  final WeatherSnapshot? weatherSnapshot;
}
