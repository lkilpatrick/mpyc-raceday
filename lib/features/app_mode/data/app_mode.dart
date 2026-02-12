import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppMode {
  raceCommittee,
  skipper,
  crew,
  onshore,
}

extension AppModeX on AppMode {
  String get label => switch (this) {
        AppMode.raceCommittee => 'Race Committee',
        AppMode.skipper => 'Skipper',
        AppMode.crew => 'Crew',
        AppMode.onshore => 'Onshore',
      };

  String get subtitle => switch (this) {
        AppMode.raceCommittee =>
          'Course selection, timing, scoring, check-in management',
        AppMode.skipper =>
          'Remote check-in, countdown, protests, GPS tracking',
        AppMode.crew =>
          'Role dashboard, crew chat, safety info, performance',
        AppMode.onshore =>
          'Live spectator view, leaderboard, results, weather',
      };

  IconData get icon => switch (this) {
        AppMode.raceCommittee => Icons.flag,
        AppMode.skipper => Icons.sailing,
        AppMode.crew => Icons.group,
        AppMode.onshore => Icons.visibility,
      };

  Color get color => switch (this) {
        AppMode.raceCommittee => Colors.indigo,
        AppMode.skipper => Colors.teal,
        AppMode.crew => Colors.orange,
        AppMode.onshore => Colors.blue,
      };

  String get firestoreValue => name;
}

AppMode appModeFromString(String? s) => switch (s) {
      'raceCommittee' => AppMode.raceCommittee,
      'skipper' => AppMode.skipper,
      'crew' => AppMode.crew,
      'onshore' => AppMode.onshore,
      _ => AppMode.onshore,
    };

/// Global mutable holder for the current app mode.
/// Riverpod 3.x removed StateProvider, so we use a simple StreamProvider
/// backed by a broadcast controller.
final _appModeController =
    StreamController<AppMode>.broadcast()..add(AppMode.onshore);
AppMode _currentAppMode = AppMode.onshore;

final appModeProvider = StreamProvider<AppMode>((ref) {
  return _appModeController.stream;
});

/// Read the current mode synchronously.
AppMode currentAppMode() => _currentAppMode;

/// Call once at app startup to load the persisted mode from Firestore.
Future<void> loadAppMode(WidgetRef ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  try {
    final snap = await FirebaseFirestore.instance
        .collection('members')
        .where('firebaseUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      final mode = appModeFromString(data['appMode'] as String?);
      _currentAppMode = mode;
      _appModeController.add(mode);
    }
  } catch (_) {}
}

/// Persist the mode to Firestore and update the stream.
Future<void> setAppMode(WidgetRef ref, AppMode mode) async {
  _currentAppMode = mode;
  _appModeController.add(mode);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  try {
    final snap = await FirebaseFirestore.instance
        .collection('members')
        .where('firebaseUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference
          .update({'appMode': mode.firestoreValue});
    }
  } catch (_) {}
}
