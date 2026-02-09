import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_log.freezed.dart';
part 'weather_log.g.dart';

enum WeatherSource { noaa, manual, openweather }

enum SeaState { calm, slight, moderate, rough, veryRough }

enum Visibility { good, moderate, poor }

enum Precipitation { none, light, moderate, heavy }

@freezed
class WeatherEntry with _$WeatherEntry {
  const factory WeatherEntry({
    required DateTime timestamp,
    required WeatherSource source,
    required double windSpeedKnots,
    required double windGustKnots,
    required int windDirectionDegrees,
    required double temperature,
    required double humidity,
    required double pressure,
    required SeaState seaState,
    required Visibility visibility,
    required Precipitation precipitation,
    required String notes,
    required String loggedBy,
  }) = _WeatherEntry;

  factory WeatherEntry.fromJson(Map<String, dynamic> json) =>
      _$WeatherEntryFromJson(json);
}

@freezed
class WeatherLog with _$WeatherLog {
  const factory WeatherLog({
    required String id,
    required String eventId,
    required List<WeatherEntry> entries,
  }) = _WeatherLog;

  factory WeatherLog.fromJson(Map<String, dynamic> json) =>
      _$WeatherLogFromJson(json);
}
