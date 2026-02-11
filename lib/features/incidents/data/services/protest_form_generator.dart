import '../models/race_incident.dart';

/// Extra data for the US Sailing Hearing Request Form fields
/// that go beyond what RaceIncident stores.
class ProtestFormData {
  const ProtestFormData({
    this.hearingType = 'protest',
    this.requestedBy = '',
    this.requestRedress = false,
    this.redressDescription = '',
    this.informedHow = 'hail',
    this.hailWords = 'Protest!',
    this.hailWhen = '',
    this.flagDisplayed = true,
    this.flagType = 'Red flag',
    this.flagWhen = '',
    this.incidentDescription = '',
    this.situationEncounterType = '',
    this.situationDetails = '',
    this.situationRules = const [],
    this.situationExplanations = const [],
  });

  final String hearingType; // protest, redress, reopening, ruleBreachByRC
  final String requestedBy;
  final bool requestRedress;
  final String redressDescription;
  final String informedHow; // hail, flag, other
  final String hailWords;
  final String hailWhen;
  final bool flagDisplayed;
  final String flagType;
  final String flagWhen;
  final String incidentDescription;
  // Pre-filled from situation advisor
  final String situationEncounterType;
  final String situationDetails;
  final List<String> situationRules;
  final List<String> situationExplanations;
}

/// Generates a pre-filled protest form matching US Sailing Hearing Request Form.
/// Returns HTML content that can be printed or saved.
class ProtestFormGenerator {
  const ProtestFormGenerator();

  /// Generate protest / hearing request form HTML matching US Sailing layout.
  String generateProtestFormHtml(
    RaceIncident incident, {
    ProtestFormData formData = const ProtestFormData(),
  }) {
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
    final desc = formData.incidentDescription.isNotEmpty
        ? formData.incidentDescription
        : incident.description;

    // Hearing type checkboxes
    final isProtest = formData.hearingType == 'protest';
    final isRedress = formData.hearingType == 'redress' || formData.requestRedress;
    final isReopening = formData.hearingType == 'reopening';
    final isRCBreach = formData.hearingType == 'ruleBreachByRC';

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Hearing Request Form — ${incident.id}</title>
<style>
  * { box-sizing: border-box; }
  body { font-family: Arial, Helvetica, sans-serif; margin: 0; padding: 20px; font-size: 11px; color: #000; }
  h1 { text-align: center; font-size: 16px; margin: 0 0 2px 0; text-transform: uppercase; letter-spacing: 1px; }
  h2 { text-align: center; font-size: 12px; color: #444; margin: 0 0 4px 0; font-weight: normal; }
  .org { text-align: center; font-size: 13px; font-weight: bold; margin-bottom: 10px; color: #1B3A5C; }
  .section { border: 1.5px solid #333; padding: 8px 10px; margin-bottom: 8px; page-break-inside: avoid; }
  .section-num { display: inline-block; background: #1B3A5C; color: #fff; font-weight: bold; font-size: 11px; padding: 2px 8px; margin: -8px -10px 6px -10px; }
  .section-title { display: inline; font-weight: bold; font-size: 11px; margin-left: 8px; text-transform: uppercase; }
  .row { display: flex; gap: 12px; margin-bottom: 4px; }
  .col { flex: 1; }
  .field { margin-bottom: 5px; }
  .field-label { font-weight: bold; font-size: 10px; color: #333; text-transform: uppercase; letter-spacing: 0.3px; }
  .field-value { border-bottom: 1px solid #999; min-height: 16px; padding: 1px 4px; font-size: 11px; }
  .cb { display: inline-block; width: 12px; height: 12px; border: 1.5px solid #333; margin-right: 4px; vertical-align: middle; text-align: center; font-size: 10px; line-height: 12px; }
  .cb-checked { background: #1B3A5C; color: #fff; }
  .cb-label { vertical-align: middle; margin-right: 12px; }
  .diagram-box { border: 1px solid #aaa; height: 180px; display: flex; align-items: center; justify-content: center; color: #999; font-style: italic; margin-top: 6px; background: #fafafa; }
  .sig-row { display: flex; gap: 20px; margin-top: 14px; }
  .sig-col { flex: 1; }
  .sig-line { border-bottom: 1.5px solid #333; height: 24px; }
  .sig-label { font-size: 9px; color: #666; margin-top: 2px; }
  .desc-box { border: 1px solid #ccc; padding: 6px 8px; min-height: 60px; background: #fafafa; white-space: pre-wrap; }
  .note { font-size: 9px; color: #666; font-style: italic; }
  .footer { font-size: 8px; color: #999; text-align: center; margin-top: 12px; border-top: 1px solid #ddd; padding-top: 6px; }
  @media print { body { margin: 0; padding: 15px; } .section { break-inside: avoid; } }
</style>
</head>
<body>

<h1>Hearing Request Form</h1>
<h2>US Sailing — Racing Rules of Sailing</h2>
<div class="org">Monterey Peninsula Yacht Club</div>

<!-- Section 1: Type of Hearing -->
<div class="section">
  <span class="section-num">1</span><span class="section-title">Type of Hearing Requested</span>
  <div style="margin-top:8px;">
    <span class="cb ${isProtest ? 'cb-checked' : ''}">${isProtest ? '✓' : ''}</span><span class="cb-label">Protest by boat against boat</span>
    <span class="cb ${isRedress ? 'cb-checked' : ''}">${isRedress ? '✓' : ''}</span><span class="cb-label">Request for redress</span>
    <span class="cb ${isReopening ? 'cb-checked' : ''}">${isReopening ? '✓' : ''}</span><span class="cb-label">Request to reopen a hearing</span>
    <span class="cb ${isRCBreach ? 'cb-checked' : ''}">${isRCBreach ? '✓' : ''}</span><span class="cb-label">Alleged breach of rule by Race Committee</span>
  </div>
</div>

<!-- Section 2: Event Information -->
<div class="section">
  <span class="section-num">2</span><span class="section-title">Event Information</span>
  <div class="row" style="margin-top:8px;">
    <div class="col">
      <div class="field"><div class="field-label">Event Name</div><div class="field-value">MPYC Race Day</div></div>
    </div>
    <div class="col">
      <div class="field"><div class="field-label">Organizing Authority</div><div class="field-value">Monterey Peninsula Yacht Club</div></div>
    </div>
  </div>
  <div class="row">
    <div class="col">
      <div class="field"><div class="field-label">Race No.</div><div class="field-value">${incident.raceNumber}</div></div>
    </div>
    <div class="col">
      <div class="field"><div class="field-label">Date of Race</div><div class="field-value">${_formatDate(incident.incidentTime)}</div></div>
    </div>
    <div class="col">
      <div class="field"><div class="field-label">Time of Incident</div><div class="field-value">${_formatTime(incident.incidentTime)}</div></div>
    </div>
  </div>
</div>

<!-- Section 3: Parties -->
<div class="section">
  <span class="section-num">3</span><span class="section-title">Protesting Party / Requesting Party</span>
  <div class="row" style="margin-top:8px;">
    <div class="col">
      <div class="field"><div class="field-label">Boat Name</div><div class="field-value">$protestingName</div></div>
    </div>
    <div class="col">
      <div class="field"><div class="field-label">Sail Number</div><div class="field-value">$protestingSail</div></div>
    </div>
  </div>
  <div class="row">
    <div class="col">
      <div class="field"><div class="field-label">Skipper / Helm</div><div class="field-value">$protestingSkipper</div></div>
    </div>
    <div class="col">
      <div class="field"><div class="field-label">Class / Fleet</div><div class="field-value">&nbsp;</div></div>
    </div>
  </div>
</div>

<div class="section">
  <span class="section-num">4</span><span class="section-title">Boat(s) Protested / Party Protested</span>
  <div class="row" style="margin-top:8px;">
    <div class="col">
      <div class="field"><div class="field-label">Boat Name</div><div class="field-value">$protestedName</div></div>
    </div>
    <div class="col">
      <div class="field"><div class="field-label">Sail Number</div><div class="field-value">$protestedSail</div></div>
    </div>
  </div>
  <div class="row">
    <div class="col">
      <div class="field"><div class="field-label">Skipper / Helm</div><div class="field-value">$protestedSkipper</div></div>
    </div>
    <div class="col">
      <div class="field"><div class="field-label">Class / Fleet</div><div class="field-value">&nbsp;</div></div>
    </div>
  </div>
</div>

<!-- Section 5: Informing the Protestee -->
<div class="section">
  <span class="section-num">5</span><span class="section-title">How was the Protestee Informed?</span>
  <div style="margin-top:8px;">
    <span class="cb ${formData.informedHow == 'hail' ? 'cb-checked' : ''}">${formData.informedHow == 'hail' ? '✓' : ''}</span><span class="cb-label">By hailing</span>
    <span class="cb ${formData.flagDisplayed ? 'cb-checked' : ''}">${formData.flagDisplayed ? '✓' : ''}</span><span class="cb-label">By displaying a red flag</span>
    <span class="cb ${formData.informedHow == 'other' ? 'cb-checked' : ''}">${formData.informedHow == 'other' ? '✓' : ''}</span><span class="cb-label">Other</span>
  </div>
  <div class="row" style="margin-top:6px;">
    <div class="col">
      <div class="field"><div class="field-label">Words of Hail</div><div class="field-value">${_escapeHtml(formData.hailWords)}</div></div>
    </div>
    <div class="col">
      <div class="field"><div class="field-label">When Hailed</div><div class="field-value">${_escapeHtml(formData.hailWhen)}</div></div>
    </div>
  </div>
  <div class="row">
    <div class="col">
      <div class="field"><div class="field-label">Flag Type</div><div class="field-value">${_escapeHtml(formData.flagType)}</div></div>
    </div>
    <div class="col">
      <div class="field"><div class="field-label">When Flag Displayed</div><div class="field-value">${_escapeHtml(formData.flagWhen)}</div></div>
    </div>
  </div>
</div>

<!-- Section 6: Rules Alleged -->
<div class="section">
  <span class="section-num">6</span><span class="section-title">Rules Alleged to Have Been Broken</span>
  <div class="desc-box" style="margin-top:8px;">$rulesText</div>
</div>

<!-- Section 7: Incident Description -->
<div class="section">
  <span class="section-num">7</span><span class="section-title">Description of Incident</span>
  <div class="note" style="margin-top:6px;">Describe in detail what happened. Include positions, courses, wind, and actions of all boats involved.</div>
  <div class="desc-box" style="margin-top:4px;">${_escapeHtml(desc)}</div>
  <div class="row" style="margin-top:6px;">
    <div class="col">
      <div class="field"><div class="field-label">Location on Course</div><div class="field-value">$locationText</div></div>
    </div>
    <div class="col">
      <div class="field"><div class="field-label">Witnesses</div><div class="field-value">$witnessNames</div></div>
    </div>
  </div>
</div>

<!-- Section 8: Diagram -->
<div class="section">
  <span class="section-num">8</span><span class="section-title">Diagram</span>
  <div class="note" style="margin-top:6px;">Show positions and courses of all boats involved, marks, wind direction, and point of incident.</div>
  <div class="diagram-box">Diagram — draw by hand after printing, or attach a separate diagram</div>
</div>

<!-- Section 9: Signatures -->
<div class="section">
  <span class="section-num">9</span><span class="section-title">Signature</span>
  <div class="sig-row">
    <div class="sig-col">
      <div class="sig-line"></div>
      <div class="sig-label">Signature of Protesting Party / Representative</div>
    </div>
    <div class="sig-col">
      <div class="sig-line"></div>
      <div class="sig-label">Date / Time Filed</div>
    </div>
  </div>
  <div class="sig-row">
    <div class="sig-col">
      <div class="sig-line"></div>
      <div class="sig-label">Printed Name</div>
    </div>
    <div class="sig-col">
      <div class="sig-line"></div>
      <div class="sig-label">Received by Race Committee</div>
    </div>
  </div>
</div>

<!-- Section 10: For Protest Committee Use -->
<div class="section">
  <span class="section-num">10</span><span class="section-title">For Protest Committee Use Only</span>
  <div class="row" style="margin-top:8px;">
    <div class="col">
      <div class="field"><div class="field-label">Protest No.</div><div class="field-value">${incident.id.length > 8 ? incident.id.substring(0, 8) : incident.id}</div></div>
    </div>
    <div class="col">
      <div class="field"><div class="field-label">Hearing Date</div><div class="field-value">${incident.hearing?.scheduledAt != null ? _formatDate(incident.hearing!.scheduledAt!) : ''}</div></div>
    </div>
    <div class="col">
      <div class="field"><div class="field-label">Time Limit Met?</div><div class="field-value">&nbsp;</div></div>
    </div>
  </div>
  <div class="row">
    <div class="col">
      <div class="field"><div class="field-label">Protest Valid?</div>
        <div style="margin-top:4px;">
          <span class="cb"></span><span class="cb-label">Yes</span>
          <span class="cb"></span><span class="cb-label">No — reason:</span>
        </div>
      </div>
    </div>
  </div>
  <div class="field" style="margin-top:6px;"><div class="field-label">Jury / Protest Committee Members</div><div class="field-value">${incident.hearing?.juryMembers.join(', ') ?? ''}</div></div>
</div>

<div class="footer">
  Generated by MPYC RaceDay &bull; Incident ID: ${incident.id} &bull; US Sailing Hearing Request Form
</div>

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
  * { box-sizing: border-box; }
  body { font-family: Arial, Helvetica, sans-serif; margin: 0; padding: 20px; font-size: 11px; color: #000; }
  h1 { text-align: center; font-size: 16px; margin: 0 0 2px 0; text-transform: uppercase; letter-spacing: 1px; }
  h2 { text-align: center; font-size: 12px; color: #444; margin: 0 0 4px 0; font-weight: normal; }
  .org { text-align: center; font-size: 13px; font-weight: bold; margin-bottom: 12px; color: #1B3A5C; }
  .section { border: 1.5px solid #333; padding: 8px 10px; margin-bottom: 8px; page-break-inside: avoid; }
  .section-num { display: inline-block; background: #1B3A5C; color: #fff; font-weight: bold; font-size: 11px; padding: 2px 8px; margin: -8px -10px 6px -10px; }
  .section-title { display: inline; font-weight: bold; font-size: 11px; margin-left: 8px; text-transform: uppercase; }
  .row { display: flex; gap: 12px; margin-bottom: 4px; }
  .col { flex: 1; }
  .field { margin-bottom: 5px; }
  .field-label { font-weight: bold; font-size: 10px; color: #333; text-transform: uppercase; }
  .field-value { border-bottom: 1px solid #999; min-height: 16px; padding: 1px 4px; }
  .desc-box { border: 1px solid #ccc; padding: 6px 8px; min-height: 50px; background: #fafafa; white-space: pre-wrap; }
  .sig-row { display: flex; gap: 20px; margin-top: 14px; }
  .sig-col { flex: 1; }
  .sig-line { border-bottom: 1.5px solid #333; height: 24px; }
  .sig-label { font-size: 9px; color: #666; margin-top: 2px; }
  .footer { font-size: 8px; color: #999; text-align: center; margin-top: 12px; border-top: 1px solid #ddd; padding-top: 6px; }
  @media print { body { margin: 0; padding: 15px; } }
</style>
</head>
<body>

<h1>Protest Hearing Decision</h1>
<h2>US Sailing — Racing Rules of Sailing</h2>
<div class="org">Monterey Peninsula Yacht Club</div>

<div class="section">
  <span class="section-num">1</span><span class="section-title">Hearing Information</span>
  <div class="row" style="margin-top:8px;">
    <div class="col"><div class="field"><div class="field-label">Protest No.</div><div class="field-value">${incident.id.length > 8 ? incident.id.substring(0, 8) : incident.id}</div></div></div>
    <div class="col"><div class="field"><div class="field-label">Race No.</div><div class="field-value">${incident.raceNumber}</div></div></div>
    <div class="col"><div class="field"><div class="field-label">Date of Incident</div><div class="field-value">${_formatDate(incident.incidentTime)}</div></div></div>
  </div>
  <div class="row">
    <div class="col"><div class="field"><div class="field-label">Protest by</div><div class="field-value">${protestingBoats.map((b) => '${b.boatName} (${b.sailNumber})').join(', ')}</div></div></div>
    <div class="col"><div class="field"><div class="field-label">Against</div><div class="field-value">${protestedBoats.map((b) => '${b.boatName} (${b.sailNumber})').join(', ')}</div></div></div>
  </div>
  ${hearing?.scheduledAt != null ? '<div class="field"><div class="field-label">Hearing Date</div><div class="field-value">${_formatDate(hearing!.scheduledAt!)}</div></div>' : ''}
  <div class="field"><div class="field-label">Protest Committee / Jury</div><div class="field-value">${hearing?.juryMembers.join(', ') ?? ''}</div></div>
</div>

<div class="section">
  <span class="section-num">2</span><span class="section-title">Validity</span>
  <div class="row" style="margin-top:8px;">
    <div class="col"><div class="field"><div class="field-label">Protest Valid?</div><div class="field-value">Yes</div></div></div>
    <div class="col"><div class="field"><div class="field-label">All parties notified?</div><div class="field-value">Yes</div></div></div>
  </div>
</div>

<div class="section">
  <span class="section-num">3</span><span class="section-title">Finding of Fact</span>
  <div class="desc-box" style="margin-top:8px;">${_escapeHtml(hearing?.findingOfFact ?? 'Not yet determined')}</div>
</div>

<div class="section">
  <span class="section-num">4</span><span class="section-title">Rules That Apply</span>
  <div class="desc-box" style="margin-top:8px;">${incident.rulesAlleged.join('; ')}${hearing?.rulesBroken.isNotEmpty == true ? '\n\nRules Broken: ${hearing!.rulesBroken.join("; ")}' : ''}</div>
</div>

<div class="section">
  <span class="section-num">5</span><span class="section-title">Decision</span>
  <div class="desc-box" style="margin-top:8px;">${_escapeHtml(hearing?.decisionNotes ?? incident.resolution)}</div>
</div>

<div class="section">
  <span class="section-num">6</span><span class="section-title">Penalty</span>
  <div class="desc-box" style="margin-top:8px;">${_escapeHtml(hearing?.penalty ?? incident.penaltyApplied)}</div>
</div>

<div class="section">
  <span class="section-num">7</span><span class="section-title">Signatures</span>
  <div class="sig-row">
    <div class="sig-col"><div class="sig-line"></div><div class="sig-label">Chairman, Protest Committee</div></div>
    <div class="sig-col"><div class="sig-line"></div><div class="sig-label">Date</div></div>
  </div>
  <div class="sig-row">
    <div class="sig-col"><div class="sig-line"></div><div class="sig-label">Member</div></div>
    <div class="sig-col"><div class="sig-line"></div><div class="sig-label">Member</div></div>
  </div>
</div>

<div class="footer">
  Generated by MPYC RaceDay &bull; Incident ID: ${incident.id} &bull; US Sailing Hearing Decision
</div>

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
