import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/race_track.dart';

/// Streams GPS track points to Firestore in real-time so the live map
/// can render polyline trails for each boat during the race.
///
/// Data is stored in: `live_tracks/{eventId}/boats/{boatKey}/points/{auto}`
/// where boatKey = memberId or DEMO_{sailNumber}.
class GpsTrackService {
  GpsTrackService({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _fs;

  /// Write a single track point for a boat during a live race.
  /// Throttled writes should be handled by the caller.
  Future<void> writeTrackPoint({
    required String eventId,
    required String boatKey,
    required TrackPoint point,
    String? sailNumber,
    String? boatName,
  }) async {
    await _fs
        .collection('live_tracks')
        .doc(eventId)
        .collection('boats')
        .doc(boatKey)
        .collection('points')
        .add({
      ...point.toMap(),
      // ignore: use_null_aware_elements
      if (sailNumber != null) 'sailNumber': sailNumber,
      // ignore: use_null_aware_elements
      if (boatName != null) 'boatName': boatName,
    });

    // Update the boat's metadata doc (latest position + info)
    await _fs
        .collection('live_tracks')
        .doc(eventId)
        .collection('boats')
        .doc(boatKey)
        .set({
      'sailNumber': sailNumber ?? '',
      'boatName': boatName ?? '',
      'lastLat': point.lat,
      'lastLon': point.lon,
      'lastSpeed': point.speedKnots ?? 0,
      'lastHeading': point.heading ?? 0,
      'pointCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Write a batch of track points (used for demo mock data).
  Future<void> writeTrackPointsBatch({
    required String eventId,
    required String boatKey,
    required List<TrackPoint> points,
    String? sailNumber,
    String? boatName,
  }) async {
    final batch = _fs.batch();
    final pointsCol = _fs
        .collection('live_tracks')
        .doc(eventId)
        .collection('boats')
        .doc(boatKey)
        .collection('points');

    for (final point in points) {
      batch.set(pointsCol.doc(), {
        ...point.toMap(),
        // ignore: use_null_aware_elements
        if (sailNumber != null) 'sailNumber': sailNumber,
        // ignore: use_null_aware_elements
        if (boatName != null) 'boatName': boatName,
      });
    }
    await batch.commit();

    // Update metadata
    if (points.isNotEmpty) {
      final last = points.last;
      await _fs
          .collection('live_tracks')
          .doc(eventId)
          .collection('boats')
          .doc(boatKey)
          .set({
        'sailNumber': sailNumber ?? '',
        'boatName': boatName ?? '',
        'lastLat': last.lat,
        'lastLon': last.lon,
        'lastSpeed': last.speedKnots ?? 0,
        'lastHeading': last.heading ?? 0,
        'pointCount': points.length,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Stream all boats participating in a live race event.
  Stream<QuerySnapshot> watchBoats(String eventId) {
    return _fs
        .collection('live_tracks')
        .doc(eventId)
        .collection('boats')
        .snapshots();
  }

  /// Stream track points for a specific boat, ordered by timestamp.
  Stream<List<TrackPoint>> watchBoatTrack(String eventId, String boatKey) {
    return _fs
        .collection('live_tracks')
        .doc(eventId)
        .collection('boats')
        .doc(boatKey)
        .collection('points')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TrackPoint.fromMap(d.data()))
            .toList());
  }

  /// Get all track points for a boat (for replay).
  Future<List<TrackPoint>> getBoatTrack(String eventId, String boatKey) async {
    final snap = await _fs
        .collection('live_tracks')
        .doc(eventId)
        .collection('boats')
        .doc(boatKey)
        .collection('points')
        .orderBy('timestamp')
        .get();
    return snap.docs.map((d) => TrackPoint.fromMap(d.data())).toList();
  }

  /// Get all track points for a boat up to a given time (for delayed view).
  Stream<List<TrackPoint>> watchBoatTrackDelayed(
    String eventId,
    String boatKey, {
    required Duration delay,
  }) {
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final cutoff = DateTime.now().subtract(delay);
      final snap = await _fs
          .collection('live_tracks')
          .doc(eventId)
          .collection('boats')
          .doc(boatKey)
          .collection('points')
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(cutoff))
          .orderBy('timestamp')
          .get();
      return snap.docs.map((d) => TrackPoint.fromMap(d.data())).toList();
    });
  }

  /// Clean up live tracks for an event.
  Future<void> deleteLiveTracks(String eventId) async {
    final boatsSnap = await _fs
        .collection('live_tracks')
        .doc(eventId)
        .collection('boats')
        .get();
    for (final boatDoc in boatsSnap.docs) {
      final pointsSnap = await boatDoc.reference.collection('points').get();
      for (final p in pointsSnap.docs) {
        await p.reference.delete();
      }
      await boatDoc.reference.delete();
    }
    await _fs.collection('live_tracks').doc(eventId).delete();
  }
}
