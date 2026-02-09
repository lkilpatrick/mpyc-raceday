import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/courses_repository_impl.dart';
import '../data/models/course_config.dart';
import '../data/models/fleet_broadcast.dart';
import '../data/models/mark.dart';
import '../data/models/mark_distance.dart';
import '../domain/courses_repository.dart';

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepositoryImpl();
});

final allCoursesProvider = StreamProvider<List<CourseConfig>>((ref) {
  return ref.watch(coursesRepositoryProvider).watchAllCourses();
});

final coursesByWindBandProvider =
    Provider.family<List<CourseConfig>, String>((ref, band) {
  final courses = ref.watch(allCoursesProvider).value ?? [];
  return courses.where((c) => c.windDirectionBand == band).toList();
});

final selectedCourseProvider =
    StreamProvider.family<String?, String>((ref, eventId) {
  return ref.watch(coursesRepositoryProvider).watchSelectedCourse(eventId);
});

final marksProvider = FutureProvider<List<Mark>>((ref) {
  return ref.watch(coursesRepositoryProvider).getMarks();
});

final watchMarksProvider = StreamProvider<List<Mark>>((ref) {
  return ref.watch(coursesRepositoryProvider).watchMarks();
});

final markDistancesProvider = FutureProvider<List<MarkDistance>>((ref) {
  return ref.watch(coursesRepositoryProvider).getMarkDistances();
});

final broadcastsProvider =
    StreamProvider.family<List<FleetBroadcast>, String?>((ref, eventId) {
  return ref.watch(coursesRepositoryProvider).watchBroadcasts(eventId: eventId);
});

final inflatableCoursesProvider = Provider<List<CourseConfig>>((ref) {
  final courses = ref.watch(allCoursesProvider).value ?? [];
  return courses.where((c) => c.windDirectionBand == 'INFLATABLE').toList();
});

final longRaceCoursesProvider = Provider<List<CourseConfig>>((ref) {
  final courses = ref.watch(allCoursesProvider).value ?? [];
  return courses.where((c) => c.windDirectionBand == 'LONG').toList();
});

/// Returns courses recommended for the given wind direction (degrees magnetic).
/// Handles 360° wraparound for northerly bands.
final recommendedCoursesProvider =
    Provider.family<List<CourseConfig>, double>((ref, windDirDeg) {
  final courses = ref.watch(allCoursesProvider).value ?? [];
  final results = <_ScoredCourse>[];

  for (final c in courses) {
    if (c.windDirectionBand == 'INFLATABLE') continue; // always available
    final inBand = _isInWindBand(windDirDeg, c.windDirMin, c.windDirMax);
    final nearBand =
        _isInWindBand(windDirDeg, c.windDirMin - 15, c.windDirMax + 15);

    if (inBand) {
      results.add(_ScoredCourse(c, 'RECOMMENDED'));
    } else if (nearBand) {
      results.add(_ScoredCourse(c, 'POSSIBLE'));
    }
  }

  results.sort((a, b) {
    if (a.label == 'RECOMMENDED' && b.label != 'RECOMMENDED') return -1;
    if (a.label != 'RECOMMENDED' && b.label == 'RECOMMENDED') return 1;
    return a.course.distanceNm.compareTo(b.course.distanceNm);
  });

  return results.map((s) => s.course).toList();
});

bool _isInWindBand(double windDir, int min, int max) {
  // Normalize
  final normMin = ((min % 360) + 360) % 360;
  final normMax = ((max % 360) + 360) % 360;
  final normWind = ((windDir.toInt() % 360) + 360) % 360;

  if (normMin <= normMax) {
    return normWind >= normMin && normWind <= normMax;
  } else {
    // Wraps around 360 (e.g., 320-020)
    return normWind >= normMin || normWind <= normMax;
  }
}

class _ScoredCourse {
  const _ScoredCourse(this.course, this.label);
  final CourseConfig course;
  final String label;
}

/// Get recommendation label for a specific course given wind direction.
String getCourseRecommendation(CourseConfig course, double windDirDeg) {
  if (course.windDirectionBand == 'INFLATABLE') return 'AVAILABLE';
  if (_isInWindBand(windDirDeg, course.windDirMin, course.windDirMax)) {
    return 'RECOMMENDED';
  }
  if (_isInWindBand(
      windDirDeg, course.windDirMin - 15, course.windDirMax + 15)) {
    return 'POSSIBLE';
  }
  return 'NOT RECOMMENDED';
}
