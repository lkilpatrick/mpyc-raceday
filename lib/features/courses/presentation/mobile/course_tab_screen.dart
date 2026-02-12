import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/core/theme.dart';

import '../../../weather/presentation/live_weather_providers.dart';
import '../../data/models/course_config.dart';
import '../courses_providers.dart';

/// Course tab: shows active course prominently, then course library
/// with live wind direction from weather (adjustable).
class CourseTabScreen extends ConsumerStatefulWidget {
  const CourseTabScreen({super.key});

  @override
  ConsumerState<CourseTabScreen> createState() => _CourseTabScreenState();
}

class _CourseTabScreenState extends ConsumerState<CourseTabScreen> {
  double? _windOverride;

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(liveWeatherProvider);
    final coursesAsync = ref.watch(allCoursesProvider);

    // Use live wind direction, allow manual override
    final liveWindDir =
        weatherAsync.value?.dirDeg.toDouble() ?? 0;
    final windDir = _windOverride ?? liveWindDir;

    final recommended = ref.watch(recommendedCoursesProvider(windDir));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ── Active Course Card ──
        const _ActiveCourseCard(),
        const SizedBox(height: 16),

        // ── Wind Direction Bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.explore, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Wind: ${windDir.toInt()}°',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (_windOverride != null) ...[
                    const SizedBox(width: 6),
                    const Text('(manual)',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _windOverride = null),
                      child: const Icon(Icons.refresh,
                          size: 16, color: AppColors.primary),
                    ),
                  ] else ...[
                    const SizedBox(width: 6),
                    weatherAsync.when(
                      data: (_) => const Text('(live)',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600)),
                      loading: () => const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5)),
                      error: (_, __) => const Text('(offline)',
                          style: TextStyle(fontSize: 11, color: Colors.orange)),
                    ),
                  ],
                  const Spacer(),
                  Text('${recommended.length} recommended',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              Slider(
                value: windDir,
                min: 0,
                max: 359,
                divisions: 359,
                onChanged: (v) => setState(() => _windOverride = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Course Library ──
        Text('Course Library',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        coursesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (courses) {
            final recommendedIds =
                recommended.map((c) => c.id).toSet();

            // Sort: recommended first, then by course number
            final sorted = [...courses]..sort((a, b) {
                final aRec = recommendedIds.contains(a.id) ? 0 : 1;
                final bRec = recommendedIds.contains(b.id) ? 0 : 1;
                if (aRec != bRec) return aRec.compareTo(bRec);
                final aNum = int.tryParse(a.courseNumber) ?? 9999;
                final bNum = int.tryParse(b.courseNumber) ?? 9999;
                return aNum.compareTo(bNum);
              });

            if (sorted.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No courses configured.')),
              );
            }

            return Column(
              children: sorted.map((course) {
                final rec = getCourseRecommendation(course, windDir);
                return _CourseListItem(
                  course: course,
                  recommendation: rec,
                  onTap: () =>
                      context.push('/courses/display/${course.id}'),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/// Shows the currently active course for today's event (if any).
class _ActiveCourseCard extends ConsumerWidget {
  const _ActiveCourseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.map, size: 32, color: Colors.grey.shade400),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('No race today — browse the course library below',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          );
        }

        final d = docs.first.data() as Map<String, dynamic>;
        final courseId = d['courseId'] as String? ?? '';
        final eventName = d['name'] as String? ?? 'Race Day';

        if (courseId.isEmpty) {
          return Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.pending, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(eventName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const Text('Course not yet set',
                            style:
                                TextStyle(fontSize: 13, color: Colors.orange)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show the active course
        return _ActiveCourseDetail(courseId: courseId, eventName: eventName);
      },
    );
  }
}

class _ActiveCourseDetail extends ConsumerWidget {
  const _ActiveCourseDetail(
      {required this.courseId, required this.eventName});
  final String courseId;
  final String eventName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(allCoursesProvider);

    return coursesAsync.when(
      loading: () => const Card(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()))),
      error: (_, __) => const SizedBox.shrink(),
      data: (courses) {
        final course = courses.cast<CourseConfig?>().firstWhere(
              (c) => c!.id == courseId,
              orElse: () => null,
            );
        if (course == null) return const SizedBox.shrink();

        return Card(
          color: AppColors.primary.withAlpha(15),
          child: InkWell(
            onTap: () => context.push('/courses/display/$courseId'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _parseHexColor(course.windGroup?.color),
                        radius: 20,
                        child: Text(
                          course.courseNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(eventName,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                            Text(
                              'Course ${course.courseNumber}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('ACTIVE',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(course.courseName,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${course.windDirectionBand} · ${course.distanceNm} nm · ${course.marks.length} marks',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.markSequenceDisplay,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CourseListItem extends StatelessWidget {
  const _CourseListItem({
    required this.course,
    required this.recommendation,
    required this.onTap,
  });

  final CourseConfig course;
  final String recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeBg) = switch (recommendation) {
      'RECOMMENDED' => (Colors.green, Colors.green.withAlpha(25)),
      'POSSIBLE' => (Colors.orange, Colors.orange.withAlpha(25)),
      'AVAILABLE' => (Colors.blue, Colors.blue.withAlpha(25)),
      _ => (Colors.grey, Colors.grey.withAlpha(15)),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: _parseHexColor(course.windGroup?.color),
          radius: 18,
          child: Text(
            course.courseNumber,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        title: Text(course.courseName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${course.windGroup?.label ?? course.windDirectionBand} · ${course.distanceNm > 0 ? "${course.distanceNm} nm" : "Variable"}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            recommendation,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Parse a hex color string like "#DC2626" to a Flutter Color.
Color _parseHexColor(String? hex) {
  if (hex != null && hex.startsWith('#') && hex.length == 7) {
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }
  return AppColors.primary;
}
