// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CourseMark _$CourseMarkFromJson(Map<String, dynamic> json) => _CourseMark(
  name: json['name'] as String,
  order: (json['order'] as num).toInt(),
  rounding: $enumDecode(_$MarkRoundingEnumMap, json['rounding']),
);

Map<String, dynamic> _$CourseMarkToJson(_CourseMark instance) =>
    <String, dynamic>{
      'name': instance.name,
      'order': instance.order,
      'rounding': _$MarkRoundingEnumMap[instance.rounding]!,
    };

const _$MarkRoundingEnumMap = {
  MarkRounding.port: 'port',
  MarkRounding.starboard: 'starboard',
};

_CourseConfig _$CourseConfigFromJson(Map<String, dynamic> json) =>
    _CourseConfig(
      id: json['id'] as String,
      courseName: json['courseName'] as String,
      courseNumber: json['courseNumber'] as String,
      description: json['description'] as String,
      diagramUrl: json['diagramUrl'] as String?,
      marks: (json['marks'] as List<dynamic>)
          .map((e) => CourseMark.fromJson(e as Map<String, dynamic>))
          .toList(),
      distanceNm: (json['distanceNm'] as num?)?.toDouble(),
      windRangeMin: (json['windRangeMin'] as num).toInt(),
      windRangeMax: (json['windRangeMax'] as num).toInt(),
      windSpeedMin: (json['windSpeedMin'] as num).toDouble(),
      windSpeedMax: (json['windSpeedMax'] as num).toDouble(),
      isActive: json['isActive'] as bool,
      notes: json['notes'] as String,
    );

Map<String, dynamic> _$CourseConfigToJson(_CourseConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courseName': instance.courseName,
      'courseNumber': instance.courseNumber,
      'description': instance.description,
      'diagramUrl': instance.diagramUrl,
      'marks': instance.marks,
      'distanceNm': instance.distanceNm,
      'windRangeMin': instance.windRangeMin,
      'windRangeMax': instance.windRangeMax,
      'windSpeedMin': instance.windSpeedMin,
      'windSpeedMax': instance.windSpeedMax,
      'isActive': instance.isActive,
      'notes': instance.notes,
    };
