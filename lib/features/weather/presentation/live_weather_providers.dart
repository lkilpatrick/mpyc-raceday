import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/models/live_weather.dart';

/// Listens to the weather/mpyc_station Firestore doc written by the
/// NOAA Cloud Function (runs every minute, server-side — no CORS issues).
final liveWeatherProvider = StreamProvider<LiveWeather?>((ref) {
  return FirebaseFirestore.instance
      .collection('weather')
      .doc('mpyc_station')
      .snapshots()
      .map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return LiveWeather.fromFirestore(snap.data()!);
  });
});

/// Listens to all station observation docs under weather/stations/observations/*
final allStationsWeatherProvider = StreamProvider<List<LiveWeather>>((ref) {
  return FirebaseFirestore.instance
      .collection('weather')
      .doc('stations')
      .collection('observations')
      .snapshots()
      .map((snap) {
    return snap.docs
        .where((doc) {
          final d = doc.data();
          // Always include primary/ambient stations even with errors
          // so they appear on the map; exclude other errored stations
          if (d['error'] != null) {
            final isPrimary = (d['station'] as Map?)?['isPrimary'] == true;
            final isAmbient = d['stationType'] == 'ambient';
            return isPrimary || isAmbient;
          }
          return true;
        })
        .map((doc) => LiveWeather.fromFirestore(doc.data()))
        .toList()
      ..sort((a, b) {
        // Primary station first, then by distance
        if (a.station.isPrimary && !b.station.isPrimary) return -1;
        if (!a.station.isPrimary && b.station.isPrimary) return 1;
        return a.station.distanceMi.compareTo(b.station.distanceMi);
      });
  });
});

final windSpeedUnitProvider = StateProvider<WindSpeedUnit>((ref) {
  return WindSpeedUnit.kts;
});

final distanceUnitProvider = StateProvider<DistanceUnit>((ref) {
  return DistanceUnit.nm;
});
