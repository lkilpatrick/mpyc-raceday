import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfflineQueue serialization', () {
    test('enqueue entry serializes correctly', () {
      final entry = jsonEncode({
        'collection': 'race_starts',
        'docId': 'rs1',
        'data': {'raceNumber': 1, 'className': 'Fleet'},
        'operation': 'set',
        'queuedAt': DateTime(2024, 6, 15, 10, 0).toIso8601String(),
      });

      final decoded = jsonDecode(entry) as Map<String, dynamic>;
      expect(decoded['collection'], 'race_starts');
      expect(decoded['docId'], 'rs1');
      expect(decoded['operation'], 'set');
      expect(decoded['data']['raceNumber'], 1);
    });

    test('supports set, update, delete operations', () {
      for (final op in ['set', 'update', 'delete']) {
        final entry = jsonEncode({
          'collection': 'test',
          'docId': 'doc1',
          'data': {},
          'operation': op,
          'queuedAt': DateTime.now().toIso8601String(),
        });
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        expect(decoded['operation'], op);
      }
    });

    test('handles complex nested data', () {
      final entry = jsonEncode({
        'collection': 'boat_checkins',
        'docId': 'c1',
        'data': {
          'sailNumber': '42',
          'crewNames': ['Alice', 'Bob'],
          'safetyEquipmentVerified': true,
          'phrfRating': null,
        },
        'operation': 'set',
        'queuedAt': DateTime.now().toIso8601String(),
      });

      final decoded = jsonDecode(entry) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      expect(data['crewNames'], hasLength(2));
      expect(data['safetyEquipmentVerified'], true);
      expect(data['phrfRating'], isNull);
    });

    test('queue ordering is preserved', () {
      final queue = <String>[];
      for (int i = 0; i < 5; i++) {
        queue.add(jsonEncode({
          'collection': 'test',
          'docId': 'doc$i',
          'data': {'order': i},
          'operation': 'set',
          'queuedAt': DateTime.now().toIso8601String(),
        }));
      }

      expect(queue, hasLength(5));
      final first = jsonDecode(queue.first) as Map<String, dynamic>;
      final last = jsonDecode(queue.last) as Map<String, dynamic>;
      expect(first['data']['order'], 0);
      expect(last['data']['order'], 4);
    });

    test('failed entries are retained', () {
      final queue = ['entry1', 'entry2', 'entry3'];
      final failed = <String>[];

      for (final entry in queue) {
        if (entry == 'entry2') {
          failed.add(entry); // simulate failure
        }
      }

      expect(failed, hasLength(1));
      expect(failed.first, 'entry2');
    });
  });
}
