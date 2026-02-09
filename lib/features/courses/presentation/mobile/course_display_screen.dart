import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpyc_raceday/core/theme.dart';

import '../../data/models/course_config.dart';
import '../courses_providers.dart';
import '../widgets/course_map_diagram.dart';
import '../widgets/nautical_chart_widget.dart';

class CourseDisplayScreen extends ConsumerWidget {
  const CourseDisplayScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(allCoursesProvider);
    final distancesAsync = ref.watch(markDistancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (courses) {
          final course = courses.cast<CourseConfig?>().firstWhere(
                (c) => c!.id == courseId,
                orElse: () => null,
              );

          if (course == null) {
            return const Center(
              child: Text('Course not found.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          final distances = distancesAsync.valueOrNull ?? const [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 24,
                      child: Text(
                        course.courseNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.courseName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${course.windDirectionBand} · ${course.distanceNm} nm',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Info row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Wind ${course.windDirMin}°–${course.windDirMax}°'),
                    _chip('Finish: ${course.finishLocation}'),
                    if (course.canMultiply) _chip('Can x2'),
                    if (course.requiresInflatable)
                      _chip('Inflatable: ${course.inflatableType ?? "yes"}'),
                  ],
                ),
                const SizedBox(height: 20),

                // Mark sequence
                Text('Mark Sequence',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    course.markSequenceDisplay,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Marks list
                ...course.marks.map((m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${m.order}.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: m.rounding == MarkRounding.port
                                ? Colors.red
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${m.markName} (${m.rounding.name})',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (m.isFinish)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FINISH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),

                // Nautical chart
                Text('Nautical Chart',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                NauticalChartWidget(
                  marks: ref.watch(marksProvider).valueOrNull?.cast() ?? const [],
                  course: course,
                  height: 300,
                ),
                const SizedBox(height: 20),

                // Course diagram
                Text('Course Diagram',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CourseMapDiagram(
                      course: course,
                      distances: distances.cast(),
                      size: const Size(320, 320),
                    ),
                  ),
                ),

                if (course.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Notes',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(course.notes,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade700)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
