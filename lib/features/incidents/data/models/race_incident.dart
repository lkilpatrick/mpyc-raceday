enum CourseLocationOnIncident {
  startLine,
  windwardMark,
  gate,
  leewardMark,
  reachingMark,
  openWater,
}

enum BoatInvolvedRole { protesting, protested, witness }

class BoatInvolved {
  const BoatInvolved({
    required this.boatId,
    required this.sailNumber,
    required this.boatName,
    required this.skipperName,
    required this.role,
  });

  final String boatId;
  final String sailNumber;
  final String boatName;
  final String skipperName;
  final BoatInvolvedRole role;
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
    required this.raceNumber,
    required this.reportedAt,
    required this.reportedBy,
    required this.incidentTime,
    required this.description,
    required this.locationOnCourse,
    required this.involvedBoats,
    this.rulesAlleged = const [],
    required this.status,
    this.hearing,
    this.resolution = '',
    this.penaltyApplied = '',
    this.witnesses = const [],
    this.attachments = const [],
    this.comments = const [],
  });

  final String id;
  final String eventId;
  final int raceNumber;
  final DateTime reportedAt;
  final String reportedBy;
  final DateTime incidentTime;
  final String description;
  final CourseLocationOnIncident locationOnCourse;
  final List<BoatInvolved> involvedBoats;
  final List<String> rulesAlleged;
  final RaceIncidentStatus status;
  final HearingInfo? hearing;
  final String resolution;
  final String penaltyApplied;
  final List<String> witnesses;
  final List<String> attachments;
  final List<IncidentComment> comments;
}
