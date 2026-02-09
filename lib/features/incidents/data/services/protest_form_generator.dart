import 'dart:convert';
import 'dart:typed_data';

import '../models/race_incident.dart';

/// Generates a pre-filled protest form matching World Sailing layout.
/// Returns HTML content that can be rendered or converted to PDF.
class ProtestFormGenerator {
  const ProtestFormGenerator();

  /// Generate protest form HTML for the given incident.
  String generateProtestFormHtml(RaceIncident incident) {
    final protestingBoats = incident.involvedBoats
        .where((b) => b.role == BoatInvolvedRole.protesting)
        .toList();
    final protestedBoats = incident.involvedBoats
        .where((b) => b.role == BoatInvolvedRole.protested)
        .toList();
    final witnesses = incident.involvedBoats
        .where((b) => b.role == BoatInvolvedRole.witness)
        .toList();

    final protestingSail =
        protestingBoats.isNotEmpty ? protestingBoats.first.sailNumber : '';
    final protestingName =
        protestingBoats.isNotEmpty ? protestingBoats.first.boatName : '';
    final protestingSkipper =
        protestingBoats.isNotEmpty ? protestingBoats.first.skipperName : '';

    final protestedSail =
        protestedBoats.isNotEmpty ? protestedBoats.first.sailNumber : '';
    final protestedName =
        protestedBoats.isNotEmpty ? protestedBoats.first.boatName : '';
    final protestedSkipper =
        protestedBoats.isNotEmpty ? protestedBoats.first.skipperName : '';

    final witnessNames =
        witnesses.map((w) => '${w.boatName} (${w.sailNumber})').join(', ');

    final rulesText = incident.rulesAlleged.join('; ');
    final locationText = _locationLabel(incident.locationOnCourse);

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Protest Form — ${incident.id}</title>
<style>
  body { font-family: Arial, sans-serif; margin: 20px; font-size: 12px; }
  h1 { text-align: center; font-size: 18px; margin-bottom: 4px; }
  h2 { text-align: center; font-size: 14px; color: #666; margin-top: 0; }
  .section { border: 1px solid #333; padding: 10px; margin-bottom: 10px; }
  .section-title { font-weight: bold; font-size: 13px; margin-bottom: 6px; background: #eee; padding: 4px 8px; margin: -10px -10px 8px -10px; }
  .field { margin-bottom: 6px; }
  .field label { font-weight: bold; display: inline-block; width: 140px; }
  .field span { border-bottom: 1px dotted #999; padding-bottom: 1px; }
  .row { display: flex; gap: 20px; }
  .col { flex: 1; }
  .diagram-box { border: 1px solid #ccc; height: 200px; display: flex; align-items: center; justify-content: center; color: #999; margin-top: 8px; }
  .signature-line { border-bottom: 1px solid #333; height: 30px; margin-top: 20px; }
  .sig-label { font-size: 10px; color: #666; }
  @media print { body { margin: 0; } }
</style>
</head>
<body>
<h1>PROTEST FORM</h1>
<h2>Monterey Peninsula Yacht Club</h2>

<div class="section">
  <div class="section-title">1. EVENT INFORMATION</div>
  <div class="row">
    <div class="col">
      <div class="field"><label>Event:</label> <span>MPYC Race Day</span></div>
      <div class="field"><label>Race Number:</label> <span>${incident.raceNumber}</span></div>
    </div>
    <div class="col">
      <div class="field"><label>Date:</label> <span>${_formatDate(incident.incidentTime)}</span></div>
      <div class="field"><label>Time of Incident:</label> <span>${_formatTime(incident.incidentTime)}</span></div>
    </div>
  </div>
</div>

<div class="section">
  <div class="section-title">2. PROTESTING BOAT</div>
  <div class="row">
    <div class="col">
      <div class="field"><label>Sail Number:</label> <span>$protestingSail</span></div>
      <div class="field"><label>Boat Name:</label> <span>$protestingName</span></div>
    </div>
    <div class="col">
      <div class="field"><label>Skipper:</label> <span>$protestingSkipper</span></div>
    </div>
  </div>
</div>

<div class="section">
  <div class="section-title">3. BOAT(S) PROTESTED</div>
  <div class="row">
    <div class="col">
      <div class="field"><label>Sail Number:</label> <span>$protestedSail</span></div>
      <div class="field"><label>Boat Name:</label> <span>$protestedName</span></div>
    </div>
    <div class="col">
      <div class="field"><label>Skipper:</label> <span>$protestedSkipper</span></div>
    </div>
  </div>
</div>

<div class="section">
  <div class="section-title">4. INCIDENT</div>
  <div class="field"><label>Location on Course:</label> <span>$locationText</span></div>
  <div class="field"><label>Rules Alleged:</label> <span>$rulesText</span></div>
  <div class="field"><label>Description:</label></div>
  <p>${_escapeHtml(incident.description)}</p>
  <div class="field"><label>Witnesses:</label> <span>$witnessNames</span></div>
</div>

<div class="section">
  <div class="section-title">5. DIAGRAM</div>
  <p style="font-size:10px; color:#666;">Draw the positions and courses of all boats involved, showing marks, wind direction, and the incident.</p>
  <div class="diagram-box">[Diagram Area — draw by hand after printing]</div>
</div>

<div class="section">
  <div class="section-title">6. SIGNATURES</div>
  <div class="row">
    <div class="col">
      <div class="signature-line"></div>
      <div class="sig-label">Protesting Party Signature</div>
    </div>
    <div class="col">
      <div class="signature-line"></div>
      <div class="sig-label">Date / Time Filed</div>
    </div>
  </div>
</div>

<p style="font-size:9px; color:#999; text-align:center;">
  Generated by MPYC RaceDay — Incident ID: ${incident.id}
</p>
</body>
</html>
''';
  }

  /// Generate hearing decision document HTML.
  String generateDecisionHtml(RaceIncident incident) {
    final hearing = incident.hearing;
    final protestingBoats = incident.involvedBoats
        .where((b) => b.role == BoatInvolvedRole.protesting)
        .toList();
    final protestedBoats = incident.involvedBoats
        .where((b) => b.role == BoatInvolvedRole.protested)
        .toList();

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Hearing Decision — ${incident.id}</title>
<style>
  body { font-family: Arial, sans-serif; margin: 20px; font-size: 12px; }
  h1 { text-align: center; font-size: 18px; }
  h2 { text-align: center; font-size: 14px; color: #666; }
  .section { margin-bottom: 16px; }
  .section-title { font-weight: bold; font-size: 14px; border-bottom: 2px solid #333; padding-bottom: 4px; margin-bottom: 8px; }
  .field { margin-bottom: 4px; }
  .field label { font-weight: bold; }
</style>
</head>
<body>
<h1>PROTEST HEARING DECISION</h1>
<h2>Monterey Peninsula Yacht Club</h2>

<div class="section">
  <div class="section-title">Hearing Information</div>
  <div class="field"><label>Protest by:</label> ${protestingBoats.map((b) => '${b.boatName} (${b.sailNumber})').join(', ')}</div>
  <div class="field"><label>Against:</label> ${protestedBoats.map((b) => '${b.boatName} (${b.sailNumber})').join(', ')}</div>
  <div class="field"><label>Race:</label> ${incident.raceNumber}</div>
  <div class="field"><label>Date of Incident:</label> ${_formatDate(incident.incidentTime)}</div>
  ${hearing?.scheduledAt != null ? '<div class="field"><label>Hearing Date:</label> ${_formatDate(hearing!.scheduledAt!)}</div>' : ''}
  ${hearing?.juryMembers.isNotEmpty == true ? '<div class="field"><label>Jury:</label> ${hearing!.juryMembers.join(", ")}</div>' : ''}
</div>

<div class="section">
  <div class="section-title">Finding of Fact</div>
  <p>${_escapeHtml(hearing?.findingOfFact ?? 'Not yet determined')}</p>
</div>

<div class="section">
  <div class="section-title">Rules That Apply</div>
  <p>${incident.rulesAlleged.join('; ')}</p>
  ${hearing?.rulesBroken.isNotEmpty == true ? '<p><strong>Rules Broken:</strong> ${hearing!.rulesBroken.join("; ")}</p>' : ''}
</div>

<div class="section">
  <div class="section-title">Decision</div>
  <p>${_escapeHtml(hearing?.decisionNotes ?? incident.resolution)}</p>
</div>

<div class="section">
  <div class="section-title">Penalty</div>
  <p>${_escapeHtml(hearing?.penalty ?? incident.penaltyApplied)}</p>
</div>

<p style="font-size:9px; color:#999; text-align:center;">
  Generated by MPYC RaceDay — Incident ID: ${incident.id}
</p>
</body>
</html>
''';
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _escapeHtml(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  String _locationLabel(CourseLocationOnIncident loc) => switch (loc) {
        CourseLocationOnIncident.startLine => 'Start Line',
        CourseLocationOnIncident.windwardMark => 'Windward Mark',
        CourseLocationOnIncident.gate => 'Gate',
        CourseLocationOnIncident.leewardMark => 'Leeward Mark',
        CourseLocationOnIncident.reachingMark => 'Reaching Mark',
        CourseLocationOnIncident.openWater => 'Open Water',
      };
}
