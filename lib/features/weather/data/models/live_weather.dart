import 'package:cloud_firestore/cloud_firestore.dart';

class LiveWeather {
  const LiveWeather({
    required this.dirDeg,
    required this.speedMph,
    required this.speedKts,
    this.gustMph,
    this.gustKts,
    this.tempF,
    this.humidity,
    this.pressureInHg,
    required this.observedAt,
    required this.fetchedAt,
    required this.source,
    required this.station,
    this.error,
  });

  final int dirDeg;
  final double speedMph;
  final double speedKts;
  final double? gustMph;
  final double? gustKts;
  final double? tempF;
  final double? humidity;
  final double? pressureInHg;
  final DateTime observedAt;
  final DateTime fetchedAt;
  final String source;
  final StationInfo station;
  final String? error;

  factory LiveWeather.fromFirestore(Map<String, dynamic> data) {
    final stationData = data['station'] as Map<String, dynamic>? ?? {};
    return LiveWeather(
      dirDeg: (data['dirDeg'] as num?)?.toInt() ?? 0,
      speedMph: (data['speedMph'] as num?)?.toDouble() ?? 0,
      speedKts: (data['speedKts'] as num?)?.toDouble() ?? 0,
      gustMph: (data['gustMph'] as num?)?.toDouble(),
      gustKts: (data['gustKts'] as num?)?.toDouble(),
      tempF: (data['tempF'] as num?)?.toDouble(),
      humidity: (data['humidity'] as num?)?.toDouble(),
      pressureInHg: (data['pressureInHg'] as num?)?.toDouble(),
      observedAt: (data['observedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fetchedAt: (data['fetchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      source: data['source'] as String? ?? 'unknown',
      station: StationInfo.fromMap(stationData),
      error: data['error'] as String?,
    );
  }

  String get windDirectionLabel {
    const labels = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                    'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((dirDeg + 11.25) % 360 / 22.5).floor();
    return labels[index % 16];
  }

  bool get isStale {
    return DateTime.now().difference(fetchedAt).inSeconds > 120;
  }

  Duration get staleness => DateTime.now().difference(fetchedAt);
}

class StationInfo {
  const StationInfo({
    required this.name,
    required this.lat,
    required this.lon,
  });

  final String name;
  final double lat;
  final double lon;

  factory StationInfo.fromMap(Map<String, dynamic> data) {
    return StationInfo(
      name: data['name'] as String? ?? 'MPYC Weather Station',
      lat: (data['lat'] as num?)?.toDouble() ?? 36.6053,
      lon: (data['lon'] as num?)?.toDouble() ?? -121.8885,
    );
  }
}

enum WindSpeedUnit { kts, mph }

enum DistanceUnit { nm, mi, km }
