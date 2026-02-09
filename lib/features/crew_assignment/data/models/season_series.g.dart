// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SeasonSeries _$SeasonSeriesFromJson(Map<String, dynamic> json) =>
    _SeasonSeries(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      color: json['color'] as String,
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$SeasonSeriesToJson(_SeasonSeries instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'dayOfWeek': instance.dayOfWeek,
      'color': instance.color,
      'isActive': instance.isActive,
    };
