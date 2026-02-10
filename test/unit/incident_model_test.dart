import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/incidents/data/models/race_incident.dart';

void main() {
  group('RaceIncidentStatus', () {
    test('has all expected values', () {
      expect(RaceIncidentStatus.values, hasLength(6));
      expect(RaceIncidentStatus.values, contains(RaceIncidentStatus.reported));
      expect(
          RaceIncidentStatus.values, contains(RaceIncidentStatus.protestFiled));
      expect(RaceIncidentStatus.values,
          contains(RaceIncidentStatus.hearingScheduled));
      expect(RaceIncidentStatus.values,
          contains(RaceIncidentStatus.hearingComplete));
      expect(RaceIncidentStatus.values, contains(RaceIncidentStatus.resolved));
      expect(RaceIncidentStatus.values, contains(RaceIncidentStatus.withdrawn));
    });

    test('name serialization roundtrips', () {
      for (final status in RaceIncidentStatus.values) {
        final restored = RaceIncidentStatus.values.firstWhere(
          (s) => s.name == status.name,
        );
        expect(restored, status);
      }
    });
  });

  group('CourseLocationOnIncident', () {
    test('has all expected values', () {
      expect(CourseLocationOnIncident.values, hasLength(6));
      expect(CourseLocationOnIncident.values,
          contains(CourseLocationOnIncident.startLine));
      expect(CourseLocationOnIncident.values,
          contains(CourseLocationOnIncident.windwardMark));
      expect(CourseLocationOnIncident.values,
          contains(CourseLocationOnIncident.gate));
      expect(CourseLocationOnIncident.values,
          contains(CourseLocationOnIncident.leewardMark));
      expect(CourseLocationOnIncident.values,
          contains(CourseLocationOnIncident.reachingMark));
      expect(CourseLocationOnIncident.values,
          contains(CourseLocationOnIncident.openWater));
    });
  });

  group('BoatInvolved', () {
    test('creates with all fields', () {
      final boat = BoatInvolved(
        boatId: 'b1',
        sailNumber: '42',
        boatName: 'Wind Dancer',
        skipperName: 'John Doe',
        role: BoatInvolvedRole.protesting,
      );

      expect(boat.boatId, 'b1');
      expect(boat.sailNumber, '42');
      expect(boat.boatName, 'Wind Dancer');
      expect(boat.skipperName, 'John Doe');
      expect(boat.role, BoatInvolvedRole.protesting);
    });

    test('all BoatInvolvedRole values exist', () {
      expect(BoatInvolvedRole.values, hasLength(3));
      expect(
          BoatInvolvedRole.values, contains(BoatInvolvedRole.protesting));
      expect(
          BoatInvolvedRole.values, contains(BoatInvolvedRole.protested));
      expect(BoatInvolvedRole.values, contains(BoatInvolvedRole.witness));
    });
  });

  group('IncidentComment', () {
    test('creates with all fields', () {
      final now = DateTime(2024, 6, 15, 10, 30);
      final comment = IncidentComment(
        id: 'c1',
        authorId: 'u1',
        authorName: 'Admin',
        text: 'Noted for review',
        createdAt: now,
      );

      expect(comment.id, 'c1');
      expect(comment.authorId, 'u1');
      expect(comment.authorName, 'Admin');
      expect(comment.text, 'Noted for review');
      expect(comment.createdAt, now);
    });
  });

  group('HearingInfo', () {
    test('creates with defaults', () {
      const hearing = HearingInfo();

      expect(hearing.scheduledAt, isNull);
      expect(hearing.location, isNull);
      expect(hearing.juryMembers, isEmpty);
      expect(hearing.findingOfFact, '');
      expect(hearing.rulesBroken, isEmpty);
      expect(hearing.penalty, '');
      expect(hearing.decisionNotes, '');
    });

    test('creates with all fields', () {
      final hearing = HearingInfo(
        scheduledAt: DateTime(2024, 6, 20, 18, 0),
        location: 'Clubhouse Room A',
        juryMembers: ['Judge A', 'Judge B', 'Judge C'],
        findingOfFact: 'Boat 42 failed to give room at the mark',
        rulesBroken: ['Rule 18.2(a)', 'Rule 18.2(b)'],
        penalty: 'DSQ',
        decisionNotes: 'Protest upheld',
      );

      expect(hearing.scheduledAt, DateTime(2024, 6, 20, 18, 0));
      expect(hearing.location, 'Clubhouse Room A');
      expect(hearing.juryMembers, hasLength(3));
      expect(hearing.findingOfFact, contains('room at the mark'));
      expect(hearing.rulesBroken, hasLength(2));
      expect(hearing.penalty, 'DSQ');
      expect(hearing.decisionNotes, 'Protest upheld');
    });
  });

  group('RaceIncident', () {
    RaceIncident makeIncident({
      String id = 'i1',
      RaceIncidentStatus status = RaceIncidentStatus.reported,
      List<BoatInvolved>? boats,
      List<String>? rulesAlleged,
      HearingInfo? hearing,
    }) {
      return RaceIncident(
        id: id,
        eventId: 'e1',
        raceNumber: 1,
        reportedAt: DateTime(2024, 6, 15, 14, 0),
        reportedBy: 'admin',
        incidentTime: DateTime(2024, 6, 15, 13, 45),
        description: 'Contact at windward mark',
        locationOnCourse: CourseLocationOnIncident.windwardMark,
        involvedBoats: boats ?? const [],
        rulesAlleged: rulesAlleged ?? const [],
        status: status,
        hearing: hearing,
      );
    }

    test('creates with required fields and defaults', () {
      final incident = makeIncident();

      expect(incident.id, 'i1');
      expect(incident.eventId, 'e1');
      expect(incident.raceNumber, 1);
      expect(incident.reportedBy, 'admin');
      expect(incident.description, 'Contact at windward mark');
      expect(incident.locationOnCourse,
          CourseLocationOnIncident.windwardMark);
      expect(incident.involvedBoats, isEmpty);
      expect(incident.rulesAlleged, isEmpty);
      expect(incident.status, RaceIncidentStatus.reported);
      expect(incident.hearing, isNull);
      expect(incident.resolution, '');
      expect(incident.penaltyApplied, '');
      expect(incident.witnesses, isEmpty);
      expect(incident.attachments, isEmpty);
      expect(incident.comments, isEmpty);
    });

    test('creates with involved boats', () {
      final incident = makeIncident(
        boats: [
          const BoatInvolved(
            boatId: 'b1',
            sailNumber: '42',
            boatName: 'Wind Dancer',
            skipperName: 'John',
            role: BoatInvolvedRole.protesting,
          ),
          const BoatInvolved(
            boatId: 'b2',
            sailNumber: '100',
            boatName: 'Sea Breeze',
            skipperName: 'Jane',
            role: BoatInvolvedRole.protested,
          ),
        ],
      );

      expect(incident.involvedBoats, hasLength(2));
      expect(
          incident.involvedBoats[0].role, BoatInvolvedRole.protesting);
      expect(
          incident.involvedBoats[1].role, BoatInvolvedRole.protested);
    });

    test('creates with hearing info', () {
      final incident = makeIncident(
        status: RaceIncidentStatus.hearingScheduled,
        hearing: HearingInfo(
          scheduledAt: DateTime(2024, 6, 20),
          location: 'Clubhouse',
        ),
      );

      expect(incident.hearing, isNotNull);
      expect(incident.hearing!.location, 'Clubhouse');
      expect(incident.status, RaceIncidentStatus.hearingScheduled);
    });

    test('creates with rules alleged', () {
      final incident = makeIncident(
        rulesAlleged: ['Rule 10 – On opposite tacks', 'Rule 18.2(a)'],
      );

      expect(incident.rulesAlleged, hasLength(2));
      expect(incident.rulesAlleged.first, contains('Rule 10'));
    });

    test('creates with full data including comments and attachments', () {
      final incident = RaceIncident(
        id: 'i2',
        eventId: 'e1',
        raceNumber: 2,
        reportedAt: DateTime(2024, 6, 15),
        reportedBy: 'skipper1',
        incidentTime: DateTime(2024, 6, 15),
        description: 'Port/starboard incident',
        locationOnCourse: CourseLocationOnIncident.openWater,
        involvedBoats: const [],
        status: RaceIncidentStatus.resolved,
        resolution: 'Protest upheld, boat 42 DSQ',
        penaltyApplied: 'DSQ',
        witnesses: ['witness1', 'witness2'],
        attachments: ['https://example.com/photo1.jpg'],
        comments: [
          IncidentComment(
            id: 'c1',
            authorId: 'u1',
            authorName: 'RC Chair',
            text: 'Reviewed',
            createdAt: DateTime(2024, 6, 16),
          ),
        ],
      );

      expect(incident.resolution, contains('DSQ'));
      expect(incident.penaltyApplied, 'DSQ');
      expect(incident.witnesses, hasLength(2));
      expect(incident.attachments, hasLength(1));
      expect(incident.comments, hasLength(1));
      expect(incident.comments.first.authorName, 'RC Chair');
    });
  });
}
