import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/models/live_weather.dart';
import '../data/services/noaa_weather_service.dart';

/// Fetches live weather from NOAA and refreshes every 60 seconds.
final liveWeatherProvider = StreamProvider<LiveWeather?>((ref) {
  final noaa = NoaaWeatherService();

  // ignore: close_sinks
  final controller = StreamController<LiveWeather?>();

  Future<void> fetch() async {
    try {
      final entry = await noaa.fetchCurrentConditions();
      if (entry == null) {
        controller.add(null);
        return;
      }
      final speedMph = entry.windSpeedKts / 0.868976;
      final gustMph = entry.windGustKts != null
          ? entry.windGustKts! / 0.868976
          : null;
      final pressureInHg = entry.pressureMb != null
          ? entry.pressureMb! * 0.02953
          : null;

      controller.add(LiveWeather(
        dirDeg: entry.windDirectionDeg.round(),
        speedMph: speedMph,
        speedKts: entry.windSpeedKts,
        gustMph: gustMph,
        gustKts: entry.windGustKts,
        tempF: entry.temperatureF,
        humidity: entry.humidity,
        pressureInHg: pressureInHg,
        observedAt: entry.timestamp,
        fetchedAt: DateTime.now(),
        source: 'noaa',
        station: const StationInfo(
          name: 'NOAA Monterey Bay',
          lat: 36.6002,
          lon: -121.8947,
        ),
      ));
    } catch (e) {
      controller.add(LiveWeather(
        dirDeg: 0,
        speedMph: 0,
        speedKts: 0,
        observedAt: DateTime.now(),
        fetchedAt: DateTime.now(),
        source: 'noaa',
        station: const StationInfo(
          name: 'NOAA Monterey Bay',
          lat: 36.6002,
          lon: -121.8947,
        ),
        error: e.toString(),
      ));
    }
  }

  // Fetch immediately, then every 60 seconds
  fetch();
  final timer = Timer.periodic(const Duration(seconds: 60), (_) => fetch());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

final windSpeedUnitProvider = StateProvider<WindSpeedUnit>((ref) {
  return WindSpeedUnit.kts;
});

final distanceUnitProvider = StateProvider<DistanceUnit>((ref) {
  return DistanceUnit.nm;
});
