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
       _firestore = firestore ?? FirebaseFirestore.instance,
       _logger = logger ?? const AppLogger(),
       _apiKey = apiKey ?? _resolveApiKey();

  static const String baseUrl = 'https://api.theclubspot.com/api/v1';

  final http.Client _client;
  final FirebaseFirestore _firestore;
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

        final resolvedRole = (existing['role'] ?? 'member').toString();
        final mapped = <String, dynamic>{
          'id': memberDocId,
          'firstName': member.firstName,
          'lastName': member.lastName,
          'email': member.email,
          'mobileNumber': member.mobile,
          'memberNumber': member.membershipNumber,
          'membershipStatus': member.membershipStatus,
          'membershipCategory': member.membershipCategory,
          'memberTags': member.tags,
          'clubspotId': member.id,
          'role': resolvedRole,
          'lastSynced': Timestamp.now(),
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

    await _firestore.collection('auditLogs').add({
      'id': '',
      'userId': 'system',
      'action': 'clubspot_member_sync',
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
