import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_config.freezed.dart';
part 'course_config.g.dart';

enum MarkRounding { port, starboard }

@freezed
class CourseMark with _$CourseMark {
  const factory CourseMark({
    required String name,
    required int order,
    required MarkRounding rounding,
  }) = _CourseMark;

  factory CourseMark.fromJson(Map<String, dynamic> json) =>
      _$CourseMarkFromJson(json);
}

@freezed
class CourseConfig with _$CourseConfig {
  const factory CourseConfig({
    required String id,
    required String courseName,
    required String courseNumber,
    required String description,
    String? diagramUrl,
    required List<CourseMark> marks,
    double? distanceNm,
    required int windRangeMin,
    required int windRangeMax,
    required double windSpeedMin,
    required double windSpeedMax,
    required bool isActive,
    required String notes,
  }) = _CourseConfig;

  factory CourseConfig.fromJson(Map<String, dynamic> json) =>
      _$CourseConfigFromJson(json);
}
