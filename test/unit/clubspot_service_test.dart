import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mpyc_raceday/shared/models/clubspot_member.dart';
import 'package:mpyc_raceday/shared/services/clubspot_service.dart';

void main() {
  group('ClubspotService', () {
    late ClubspotService service;

    ClubspotService buildService(MockClient client) {
      return ClubspotService(
        client: client,
        apiKey: 'test-api-key',
      );
    }

    group('fetchMembers', () {
      test('parses single page of members', () async {
        final client = MockClient((req) async {
          expect(req.headers['api-key'], 'test-api-key');
          return http.Response(
            jsonEncode({
              'members': [
                {
                  'id': 'm1',
                  'club_id': 'c1',
                  'membership_number': '100',
                  'first_name': 'John',
                  'last_name': 'Doe',
                  'email': 'john@example.com',
                  'mobile': '+15551234567',
                  'membership_status': 'active',
                  'membership_category': 'Regular',
                  'tags': ['RC Crew'],
                },
              ],
              'has_more': false,
            }),
            200,
          );
        });

        service = buildService(client);
        final members = await service.fetchMembers('c1');

        expect(members, hasLength(1));
        expect(members.first.id, 'm1');
        expect(members.first.firstName, 'John');
        expect(members.first.lastName, 'Doe');
        expect(members.first.fullName, 'John Doe');
        expect(members.first.email, 'john@example.com');
        expect(members.first.mobile, '+15551234567');
        expect(members.first.tags, ['RC Crew']);
      });

      test('handles pagination with has_more', () async {
        var callCount = 0;
        final client = MockClient((req) async {
          callCount++;
          if (callCount == 1) {
            expect(req.url.queryParameters['skip'], '0');
            return http.Response(
              jsonEncode({
                'members': [
                  {'id': 'm1', 'first_name': 'A', 'last_name': 'B'},
                  {'id': 'm2', 'first_name': 'C', 'last_name': 'D'},
                ],
                'has_more': true,
              }),
              200,
            );
          }
          expect(req.url.queryParameters['skip'], '2');
          return http.Response(
            jsonEncode({
              'members': [
                {'id': 'm3', 'first_name': 'E', 'last_name': 'F'},
              ],
              'has_more': false,
            }),
            200,
          );
        });

        service = buildService(client);
        final members = await service.fetchMembers('c1');

        expect(members, hasLength(3));
        expect(callCount, 2);
      });

      test('skips members without id', () async {
        final client = MockClient((req) async {
          return http.Response(
            jsonEncode({
              'members': [
                {'id': '', 'first_name': 'No', 'last_name': 'Id'},
                {'id': 'm1', 'first_name': 'Has', 'last_name': 'Id'},
              ],
              'has_more': false,
            }),
            200,
          );
        });

        service = buildService(client);
        final members = await service.fetchMembers('c1');

        expect(members, hasLength(1));
        expect(members.first.id, 'm1');
      });

      test('handles alternate JSON keys (data, _id)', () async {
        final client = MockClient((req) async {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  '_id': 'alt1',
                  'first_name': 'Alt',
                  'last_name': 'Key',
                  'mobile_phone': '+15559999999',
                  'member_number': '200',
                },
              ],
              'has_more': false,
            }),
            200,
          );
        });

        service = buildService(client);
        final members = await service.fetchMembers('c1');

        expect(members, hasLength(1));
        expect(members.first.id, 'alt1');
        expect(members.first.mobile, '+15559999999');
        expect(members.first.membershipNumber, '200');
      });
    });

    group('error handling', () {
      test('throws on 401 unauthorized', () async {
        final client = MockClient((req) async {
          return http.Response('Unauthorized', 401);
        });

        service = buildService(client);
        expect(
          () => service.fetchMembers('c1'),
          throwsA(isA<ClubspotApiException>()),
        );
      });

      test('throws on invalid JSON', () async {
        final client = MockClient((req) async {
          return http.Response('not json', 200);
        });

        service = buildService(client);
        expect(
          () => service.fetchMembers('c1'),
          throwsA(isA<ClubspotApiException>()),
        );
      });

      test('retries on 429 rate limit', () async {
        var callCount = 0;
        final client = MockClient((req) async {
          callCount++;
          if (callCount == 1) {
            return http.Response('Rate limited', 429,
                headers: {'retry-after': '0'});
          }
          return http.Response(
            jsonEncode({'members': [], 'has_more': false}),
            200,
          );
        });

        service = buildService(client);
        final members = await service.fetchMembers('c1');

        expect(members, isEmpty);
        expect(callCount, 2);
      });

      test('retries on 500 server error', () async {
        var callCount = 0;
        final client = MockClient((req) async {
          callCount++;
          if (callCount <= 2) {
            return http.Response('Server Error', 500);
          }
          return http.Response(
            jsonEncode({'members': [], 'has_more': false}),
            200,
          );
        });

        service = buildService(client);
        final members = await service.fetchMembers('c1');

        expect(members, isEmpty);
        expect(callCount, 3);
      });

      test('throws on missing API key', () {
        service = ClubspotService(apiKey: '');
        expect(
          () => service.fetchMembers('c1'),
          throwsA(isA<ClubspotApiException>()),
        );
      });
    });
  });

  group('ClubspotMember.fromJson', () {
    test('maps all fields correctly', () {
      final member = ClubspotMember.fromJson({
        'id': 'abc',
        'club_id': 'club1',
        'membership_number': '42',
        'first_name': 'Jane',
        'last_name': 'Smith',
        'email': 'jane@test.com',
        'mobile': '+15550001111',
        'membership_status': 'active',
        'membership_category': 'Full',
        'tags': ['Skipper', 'RC'],
      });

      expect(member.id, 'abc');
      expect(member.clubId, 'club1');
      expect(member.membershipNumber, '42');
      expect(member.firstName, 'Jane');
      expect(member.lastName, 'Smith');
      expect(member.fullName, 'Jane Smith');
      expect(member.email, 'jane@test.com');
      expect(member.mobile, '+15550001111');
      expect(member.membershipStatus, 'active');
      expect(member.membershipCategory, 'Full');
      expect(member.tags, ['Skipper', 'RC']);
    });

    test('handles missing fields gracefully', () {
      final member = ClubspotMember.fromJson({'id': 'x'});
      expect(member.id, 'x');
      expect(member.firstName, '');
      expect(member.lastName, '');
      expect(member.email, '');
      expect(member.tags, isEmpty);
    });
  });
}
