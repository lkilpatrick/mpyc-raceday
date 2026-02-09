// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeatherEntry _$WeatherEntryFromJson(Map<String, dynamic> json) =>
    _WeatherEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: $enumDecode(_$WeatherSourceEnumMap, json['source']),
      windSpeedKnots: (json['windSpeedKnots'] as num).toDouble(),
      windGustKnots: (json['windGustKnots'] as num).toDouble(),
      windDirectionDegrees: (json['windDirectionDegrees'] as num).toInt(),
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      pressure: (json['pressure'] as num).toDouble(),
      seaState: $enumDecode(_$SeaStateEnumMap, json['seaState']),
      visibility: $enumDecode(_$VisibilityEnumMap, json['visibility']),
      precipitation: $enumDecode(_$PrecipitationEnumMap, json['precipitation']),
      notes: json['notes'] as String,
      loggedBy: json['loggedBy'] as String,
    );

Map<String, dynamic> _$WeatherEntryToJson(_WeatherEntry instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'source': _$WeatherSourceEnumMap[instance.source]!,
      'windSpeedKnots': instance.windSpeedKnots,
      'windGustKnots': instance.windGustKnots,
      'windDirectionDegrees': instance.windDirectionDegrees,
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'pressure': instance.pressure,
      'seaState': _$SeaStateEnumMap[instance.seaState]!,
      'visibility': _$VisibilityEnumMap[instance.visibility]!,
      'precipitation': _$PrecipitationEnumMap[instance.precipitation]!,
      'notes': instance.notes,
      'loggedBy': instance.loggedBy,
    };

const _$WeatherSourceEnumMap = {
  WeatherSource.noaa: 'noaa',
  WeatherSource.manual: 'manual',
  WeatherSource.openweather: 'openweather',
};

const _$SeaStateEnumMap = {
  SeaState.calm: 'calm',
  SeaState.slight: 'slight',
  SeaState.moderate: 'moderate',
  SeaState.rough: 'rough',
  SeaState.veryRough: 'veryRough',
};

const _$VisibilityEnumMap = {
  Visibility.good: 'good',
  Visibility.moderate: 'moderate',
  Visibility.poor: 'poor',
};

const _$PrecipitationEnumMap = {
  Precipitation.none: 'none',
  Precipitation.light: 'light',
  Precipitation.moderate: 'moderate',
  Precipitation.heavy: 'heavy',
};

_WeatherLog _$WeatherLogFromJson(Map<String, dynamic> json) => _WeatherLog(
  id: json['id'] as String,
  eventId: json['eventId'] as String,
  entries: (json['entries'] as List<dynamic>)
      .map((e) => WeatherEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WeatherLogToJson(_WeatherLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'entries': instance.entries,
    };
