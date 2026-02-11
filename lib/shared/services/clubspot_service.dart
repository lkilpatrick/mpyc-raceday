import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mpyc_raceday/shared/models/clubspot_member.dart';
import 'package:mpyc_raceday/shared/models/sync_result.dart';
import 'package:mpyc_raceday/shared/services/logger.dart';

class ClubspotService {
  ClubspotService({
    http.Client? client,
    FirebaseFirestore? firestore,
    AppLogger? logger,
    String? apiKey,
  }) : _client = client ?? http.Client(),
       _firestoreOverride = firestore,
       _logger = logger ?? const AppLogger(),
       _apiKey = apiKey ?? _resolveApiKey();

  static const String baseUrl = 'https://api.theclubspot.com/api/v1';

  final http.Client _client;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;
  final AppLogger _logger;
  final String? _apiKey;

  static String? _resolveApiKey() {
    if (kIsWeb) {
      return const String.fromEnvironment('CLUBSPOT_API_KEY');
    }
    final mobileEnvKey = dotenv.maybeGet('CLUBSPOT_API_KEY');
    if (mobileEnvKey != null && mobileEnvKey.isNotEmpty) {
      return mobileEnvKey;
    }
    return const String.fromEnvironment('CLUBSPOT_API_KEY');
  }

  Map<String, String> get _headers {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw ClubspotApiException(
        'Clubspot API key is missing. Configure CLUBSPOT_API_KEY.',
      );
    }
    return <String, String>{
      'api-key': apiKey,
      'Content-Type': 'application/json',
    };
  }

  Future<List<ClubspotMember>> fetchMembers(
    String clubId, {
    bool primaryOnly = false,
    int skip = 0,
  }) async {
    final members = <ClubspotMember>[];
    var currentSkip = skip;
    var hasMore = true;

    while (hasMore) {
      final uri = Uri.parse(
        '$baseUrl/members?club_id=$clubId&skip=$currentSkip&primary_only=$primaryOnly',
      );

      final response = await _requestWithRetry(
        () => _client.get(uri, headers: _headers),
      );
      final jsonBody = _decodeJson(response.body);

      final rows =
          (jsonBody['members'] as List?) ??
          (jsonBody['data'] as List?) ??
          const <dynamic>[];
      members.addAll(
        rows
            .whereType<Map<String, dynamic>>()
            .map(ClubspotMember.fromJson)
            .where((member) => member.id.isNotEmpty),
      );

      hasMore = jsonBody['has_more'] == true;
      currentSkip += rows.length;
      if (rows.isEmpty) {
        hasMore = false;
      }
    }

    return members;
  }

  Future<SyncResult> syncMembersToFirestore(String clubId) async {
    final startedAt = DateTime.now();
    var newCount = 0;
    var updatedCount = 0;
    var unchangedCount = 0;
    final errors = <String>[];

    final members = await fetchMembers(clubId);
    for (final member in members) {
      try {
        final memberDocId = member.id.isNotEmpty
            ? member.id
            : member.membershipNumber;
        if (memberDocId.isEmpty) {
          errors.add(
            'Skipped member without id or membership_number: ${member.fullName}',
          );
          continue;
        }

        final docRef = _firestore.collection('members').doc(memberDocId);
        final existingSnap = await docRef.get();
        final existing = existingSnap.data() ?? const <String, dynamic>{};

        // Preserve roles — never overwrite from Clubspot
        List<dynamic> roles;
        final existingRoles = existing['roles'];
        if (existingRoles is List && existingRoles.isNotEmpty) {
          roles = existingRoles;
        } else {
          // Migrate legacy single 'role' field
          final legacyRole = existing['role'] as String?;
          const legacyMap = {
            'admin': 'web_admin',
            'pro': 'rc_chair',
            'rc_crew': 'crew',
            'member': 'crew',
          };
          roles = [legacyMap[legacyRole] ?? 'crew'];
        }

        final mapped = <String, dynamic>{
          'id': memberDocId,
          'firstName': member.firstName,
          'lastName': member.lastName,
          'email': member.email,
          'mobileNumber': member.mobileNumber,
          'memberNumber': member.membershipNumber,
          'membershipId': member.membershipId,
          'membershipStatus': member.membershipStatus,
          'membershipCategory': member.membershipCategory,
          'memberTags': member.memberTags,
          'dob': member.dob.isNotEmpty ? member.dob : null,
          'clubspotId': member.id,
          'clubspotCreated': member.created,
          'roles': roles,
          'lastSynced': Timestamp.now(),
          // Preserve locally-managed fields
          'signalNumber': existing['signalNumber'],
          'boatName': existing['boatName'],
          'sailNumber': existing['sailNumber'],
          'boatClass': existing['boatClass'],
          'phrfRating': existing['phrfRating'],
          'firebaseUid': existing['firebaseUid'],
          'lastLogin': existing['lastLogin'],
          'isActive': existing['isActive'] ?? true,
          'profilePhotoUrl': existing['profilePhotoUrl'],
          'emergencyContact':
              existing['emergencyContact'] ??
              const {'name': 'Unknown', 'phone': ''},
        };

        final normalizedExisting = Map<String, dynamic>.from(existing)
          ..remove('lastSynced');
        final normalizedNext = Map<String, dynamic>.from(mapped)
          ..remove('lastSynced');
        final isUnchanged =
            _jsonStable(normalizedExisting) == _jsonStable(normalizedNext);

        if (existingSnap.exists && isUnchanged) {
          unchangedCount++;
          await docRef.set({
            'lastSynced': Timestamp.now(),
          }, SetOptions(merge: true));
        } else {
          await docRef.set(mapped, SetOptions(merge: true));
          if (existingSnap.exists) {
            updatedCount++;
          } else {
            newCount++;
          }
        }
      } catch (error) {
        errors.add('Failed to sync ${member.fullName} (${member.id}): $error');
      }
    }

    final finishedAt = DateTime.now();
    final result = SyncResult(
      newCount: newCount,
      updatedCount: updatedCount,
      unchangedCount: unchangedCount,
      errors: errors,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );

    await _firestore.collection('audit_logs').add({
      'id': '',
      'userId': 'system',
      'userName': 'System',
      'action': 'clubspot_member_sync',
      'category': 'sync',
      'entityType': 'member',
      'entityId': clubId,
      'details': result.toJson(),
      'timestamp': Timestamp.now(),
    });

    await _firestore.collection('memberSyncLogs').add({
      ...result.toJson(),
      'clubId': clubId,
      'timestamp': Timestamp.now(),
    });

    return result;
  }

  Future<Uri> createMemberPortalSession(
    String membershipNumber, {
    String initialView = 'home',
  }) async {
    final uri = Uri.parse('$baseUrl/member-portal/sessions');
    final response = await _requestWithRetry(
      () => _client.post(
        uri,
        headers: _headers,
        body: jsonEncode(<String, dynamic>{
          'membership_number': membershipNumber,
          'initial_view': initialView,
        }),
      ),
    );

    final jsonBody = _decodeJson(response.body);
    final url = (jsonBody['session_url'] ?? jsonBody['url'] ?? '').toString();
    if (url.isEmpty) {
      throw ClubspotApiException(
        'Clubspot portal session URL missing in response.',
      );
    }
    return Uri.parse(url);
  }

  /// Submit a single score to Clubspot for a regatta race.
  Future<Map<String, dynamic>> submitScore({
    required int finishTime,
    required String registrationId,
    required int raceNumber,
  }) async {
    final uri = Uri.parse('$baseUrl/scores');
    final response = await _requestWithRetry(
      () => _client.post(
        uri,
        headers: _headers,
        body: jsonEncode(<String, dynamic>{
          'finish_time': finishTime,
          'registration_id': registrationId,
          'race_number': raceNumber,
        }),
      ),
    );
    return _decodeJson(response.body);
  }

  /// Submit multiple scores to Clubspot in sequence.
  Future<({int submitted, List<String> errors})> submitBatchScores(
    List<({int finishTime, String registrationId, int raceNumber})> scores,
  ) async {
    var submitted = 0;
    final errors = <String>[];

    for (final score in scores) {
      try {
        await submitScore(
          finishTime: score.finishTime,
          registrationId: score.registrationId,
          raceNumber: score.raceNumber,
        );
        submitted++;
      } catch (error) {
        errors.add(
          '${score.registrationId} R${score.raceNumber}: $error',
        );
      }
    }

    return (submitted: submitted, errors: errors);
  }

  /// Fetch line items (billing activity) from Clubspot for a date range.
  Future<List<Map<String, dynamic>>> fetchLineItems({
    required String startDate,
    required String endDate,
    String? clubId,
  }) async {
    final items = <Map<String, dynamic>>[];
    var currentSkip = 0;
    var hasMore = true;

    while (hasMore) {
      final queryParams = <String, String>{
        'start_date': startDate,
        'end_date': endDate,
        'skip': '$currentSkip',
      };
      if (clubId != null && clubId.isNotEmpty) {
        queryParams['club_id'] = clubId;
      }

      final uri = Uri.parse('$baseUrl/line-items').replace(
        queryParameters: queryParams,
      );
      final response = await _requestWithRetry(
        () => _client.get(uri, headers: _headers),
      );
      final jsonBody = _decodeJson(response.body);

      final rows = (jsonBody['line_items'] as List?) ??
          ((jsonBody['data'] as Map<String, dynamic>?)?['line_items'] as List?) ??
          const <dynamic>[];
      items.addAll(rows.whereType<Map<String, dynamic>>());

      hasMore = jsonBody['has_more'] == true ||
          (jsonBody['data'] as Map<String, dynamic>?)?['has_more'] == true;
      currentSkip += rows.length;
      if (rows.isEmpty) hasMore = false;
    }

    return items;
  }

  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() request,
  ) async {
    var attempt = 0;
    Object? lastError;
    while (attempt < 4) {
      attempt++;
      try {
        final response = await request();
        if (response.statusCode == 429) {
          final retryAfterHeader = response.headers['retry-after'];
          final retryAfterSeconds = int.tryParse(retryAfterHeader ?? '');
          final delay = Duration(seconds: retryAfterSeconds ?? (attempt * 2));
          _logger.warn(
            'Clubspot rate-limited. Retrying in ${delay.inSeconds}s.',
          );
          await Future<void>.delayed(delay);
          continue;
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw ClubspotApiException(
            'Invalid Clubspot API key or unauthorized request.',
          );
        }
        if (response.statusCode >= 500) {
          if (attempt < 4) {
            await Future<void>.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          throw ClubspotApiException(
            'Clubspot API unavailable (${response.statusCode}).',
            statusCode: response.statusCode,
          );
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ClubspotApiException(
            'Clubspot request failed (${response.statusCode}): ${response.body}',
            statusCode: response.statusCode,
          );
        }
        return response;
      } catch (error) {
        lastError = error;
        if (error is ClubspotApiException) rethrow;
        if (attempt >= 4) {
          throw ClubspotApiException(
            'Network failure while contacting Clubspot: $error',
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw ClubspotApiException('Clubspot request failed: $lastError');
  }

  Map<String, dynamic> _decodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const FormatException('Response was not an object');
    } catch (error) {
      throw ClubspotApiException('Invalid JSON from Clubspot API: $error');
    }
  }

  String _jsonStable(Map<String, dynamic> value) => jsonEncode(_stable(value));

  Object? _stable(Object? input) {
    if (input is Map<String, dynamic>) {
      final sortedKeys = input.keys.toList()..sort();
      return <String, Object?>{
        for (final key in sortedKeys) key: _stable(input[key]),
      };
    }
    if (input is List) {
      return input.map(_stable).toList();
    }
    return input;
  }
}

class ClubspotApiException implements Exception {
  const ClubspotApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) return message;
    return '$message (statusCode=$statusCode)';
  }
}
