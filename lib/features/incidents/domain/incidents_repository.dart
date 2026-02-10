import '../data/models/race_incident.dart';

abstract class IncidentsRepository {
  const IncidentsRepository();

  // Incidents
  Stream<List<RaceIncident>> watchIncidents({String? eventId});
  Future<RaceIncident?> getIncident(String id);
  Future<String> createIncident(RaceIncident incident);
  Future<void> updateIncident(RaceIncident incident);
  Future<void> updateStatus(String id, RaceIncidentStatus status);
  Future<void> deleteIncident(String id);

  // Comments
  Future<void> addComment(String incidentId, IncidentComment comment);

  // Hearing
  Future<void> updateHearing(String incidentId, HearingInfo hearing);

  // Attachments
  Future<void> addAttachment(String incidentId, String attachmentUrl);
}
