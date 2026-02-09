import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/course_config.dart';
import '../../data/models/mark_distance.dart';
import '../courses_providers.dart';
import '../widgets/course_map_diagram.dart';
import '../../../weather/presentation/weather_providers.dart';

class CourseDisplayScreen extends ConsumerWidget {
  const CourseDisplayScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(allCoursesProvider);
    final distancesAsync = ref.watch(markDistancesProvider);
    final conditionsAsync = ref.watch(currentConditionsProvider);

    final windDir = conditionsAsync.valueOrNull?.windDirectionDeg ?? 0;
    final windSpeed = conditionsAsync.valueOrNull?.windSpeedKts ?? 0;
    final windLabel = conditionsAsync.valueOrNull?.windDirectionLabel ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Course')),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (courses) {
          final course = courses
              .where((c) => c.id == courseId)
              .firstOrNull;
          if (course == null) {
            return const Center(child: Text('Course not found'));
          }

          final distances = distancesAsync.valueOrNull ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentConditionsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Course header
                Text(
                  'Course ${course.courseNumber}',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  course.markSequenceDisplay,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${course.distanceNm} nm',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Weather overlay
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.air, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${windSpeed.toStringAsFixed(0)} kts from ${windDir.toStringAsFixed(0)}° ($windLabel)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Full-screen course diagram
                Center(
                  child: CourseMapDiagram(
                    course: course,
                    distances: distances,
                    windDirectionDeg: windDir,
                    size: Size(
                      MediaQuery.of(context).size.width - 32,
                      MediaQuery.of(context).size.width - 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mark sequence
                Text('Mark Sequence',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...course.marks.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  final roundLabel = m.rounding == MarkRounding.port
                      ? 'Round to Port'
                      : 'Round to Starboard';

                  // Find distances to next/prev
                  String? legInfo;
                  if (i < course.marks.length - 1) {
                    final next = course.marks[i + 1];
                    final dist = distances
                        .where((d) =>
                            d.fromMarkId == m.markId &&
                            d.toMarkId == next.markId)
                        .firstOrNull;
                    if (dist != null) {
                      legInfo =
                          '→ ${dist.distanceNm} nm / ${dist.headingMagnetic.toStringAsFixed(0)}°M';
                    }
                  }

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: m.rounding == MarkRounding.port
                            ? Colors.red
                            : Colors.green,
                        child: Text('${m.order}',
                            style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(m.markName,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(roundLabel),
                          if (legInfo != null)
                            Text(legInfo,
                                style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      trailing: m.isFinish
                          ? const Icon(Icons.flag, color: Colors.green)
                          : null,
                    ),
                  );
                }),

                // Warnings
                if (course.finishLocation == 'mark_x')
                  Card(
                    color: Colors.amber.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'This course finishes at Mark X, not the Committee Boat.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (course.requiresInflatable)
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Requires ${course.inflatableType ?? "inflatable"} marks.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
