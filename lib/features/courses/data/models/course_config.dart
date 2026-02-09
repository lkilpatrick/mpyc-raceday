enum MarkRounding { port, starboard }

class CourseMark {
  const CourseMark({
    required this.markId,
    required this.markName,
    required this.order,
    required this.rounding,
    this.isFinish = false,
  });

  final String markId;
  final String markName;
  final int order;
  final MarkRounding rounding;
  final bool isFinish;
}

class CourseConfig {
  const CourseConfig({
    required this.id,
    required this.courseNumber,
    required this.courseName,
    required this.marks,
    required this.distanceNm,
    required this.windDirectionBand,
    required this.windDirMin,
    required this.windDirMax,
    required this.finishLocation,
    this.canMultiply = false,
    this.requiresInflatable = false,
    this.inflatableType,
    this.isActive = true,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String courseNumber;
  final String courseName;
  final List<CourseMark> marks;
  final double distanceNm;
  final String windDirectionBand;
  final int windDirMin;
  final int windDirMax;
  final String finishLocation;
  final bool canMultiply;
  final bool requiresInflatable;
  final String? inflatableType;
  final bool isActive;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get markSequenceDisplay =>
      marks.map((m) => '${m.markName}${m.rounding == MarkRounding.port ? 'p' : 's'}${m.isFinish ? ' (Finish)' : ''}').join(' – ');
}
