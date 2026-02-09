import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Queues Firestore writes when offline and replays them on reconnect.
class OfflineQueue {
  OfflineQueue._();
  static final instance = OfflineQueue._();

  static const _queueKey = 'offline_write_queue';
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _processing = false;

  void init() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) processQueue();
    });
  }

  void dispose() {
    _sub?.cancel();
  }

  /// Enqueue a write operation for later replay.
  Future<void> enqueue({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    required String operation, // 'set', 'update', 'delete'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    queue.add(jsonEncode({
      'collection': collection,
      'docId': docId,
      'data': data,
      'operation': operation,
      'queuedAt': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(_queueKey, queue);
    debugPrint('OfflineQueue: enqueued $operation on $collection/$docId');
  }

  /// Process all queued writes.
  Future<void> processQueue() async {
    if (_processing) return;
    _processing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_queueKey) ?? [];
      if (queue.isEmpty) return;

      debugPrint('OfflineQueue: processing ${queue.length} queued writes');
      final failed = <String>[];

      for (final entry in queue) {
        try {
          final item = jsonDecode(entry) as Map<String, dynamic>;
          final collection = item['collection'] as String;
          final docId = item['docId'] as String;
          final data = Map<String, dynamic>.from(item['data'] as Map);
          final operation = item['operation'] as String;

          final docRef =
              FirebaseFirestore.instance.collection(collection).doc(docId);

          switch (operation) {
            case 'set':
              await docRef.set(data, SetOptions(merge: true));
            case 'update':
              await docRef.update(data);
            case 'delete':
              await docRef.delete();
          }
        } catch (e) {
          debugPrint('OfflineQueue: failed to replay: $e');
          failed.add(entry);
        }
      }

      await prefs.setStringList(_queueKey, failed);
      debugPrint(
          'OfflineQueue: done. ${queue.length - failed.length} succeeded, ${failed.length} failed');
    } finally {
      _processing = false;
    }
  }

  /// Get count of pending writes.
  Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_queueKey) ?? []).length;
  }
}
