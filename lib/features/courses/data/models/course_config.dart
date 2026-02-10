enum MarkRounding { port, starboard }

class CourseMark {
  const CourseMark({
    required this.markId,
    required this.markName,
    required this.order,
    required this.rounding,
    this.isStart = false,
    this.isFinish = false,
  });

  final String markId;
  final String markName;
  final int order;
  final MarkRounding rounding;
  final bool isStart;
  final bool isFinish;
}

class WindGroup {
  const WindGroup({
    required this.id,
    required this.label,
    required this.windRange,
    required this.color,
    required this.bgColor,
  });

  final String id;
  final String label;
  final List<int> windRange; // [fromDeg, toDeg]
  final String color;        // Hex color
  final String bgColor;      // Light background hex

  static const all = <WindGroup>[
    WindGroup(id: 'S_SW', label: 'Southerly & South Westerly', windRange: [200, 260], color: '#DC2626', bgColor: '#FEF2F2'),
    WindGroup(id: 'W', label: 'Westerly', windRange: [260, 295], color: '#2563EB', bgColor: '#EFF6FF'),
    WindGroup(id: 'NW', label: 'North Westerly', windRange: [295, 320], color: '#059669', bgColor: '#ECFDF5'),
    WindGroup(id: 'N', label: 'Northerly', windRange: [320, 20], color: '#D97706', bgColor: '#FFFBEB'),
    WindGroup(id: 'INFLATABLE', label: 'Inflatable Mark Courses', windRange: [0, 360], color: '#7C3AED', bgColor: '#F5F3FF'),
    WindGroup(id: 'LONG', label: 'Long Races (NW)', windRange: [295, 320], color: '#0F766E', bgColor: '#F0FDFA'),
  ];

  static WindGroup? byId(String id) {
    try {
      return all.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
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

  WindGroup? get windGroup => WindGroup.byId(windDirectionBand);

  String get markSequenceDisplay {
    final parts = <String>[];
    for (final m in marks) {
      if (m.isStart) {
        parts.add('START');
      } else if (m.isFinish) {
        if (finishLocation == 'X') {
          parts.add('FINISH(X)');
        } else {
          parts.add('FINISH');
        }
      } else {
        final r = m.rounding == MarkRounding.port ? 'p' : 's';
        parts.add('${m.markName}$r');
      }
    }
    return parts.join(' → ');
  }
}
