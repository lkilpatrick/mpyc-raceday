import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/models/live_weather.dart';

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

final windSpeedUnitProvider = StateProvider<WindSpeedUnit>((ref) {
  return WindSpeedUnit.kts;
});

final distanceUnitProvider = StateProvider<DistanceUnit>((ref) {
  return DistanceUnit.nm;
});
