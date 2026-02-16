import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpyc_raceday/core/theme.dart';

import '../../data/models/course_config.dart';
import '../courses_providers.dart';

class CourseSelectionScreen extends ConsumerStatefulWidget {
  const CourseSelectionScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<CourseSelectionScreen> createState() =>
      _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends ConsumerState<CourseSelectionScreen> {
  double _windDir = 0;

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(allCoursesProvider);
    final selectedAsync = ref.watch(selectedCourseProvider(widget.eventId));
    final recommended = ref.watch(recommendedCoursesProvider(_windDir));

    return Scaffold(
      appBar: AppBar(title: const Text('Select Course')),
      body: Column(
        children: [
          // Wind direction input
          Container(
            color: AppColors.primary.withAlpha(15),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.explore, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text('Wind Direction:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('${_windDir.toInt()}°',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Expanded(
                  child: Slider(
                    value: _windDir,
                    min: 0,
                    max: 359,
                    divisions: 359,
                    onChanged: (v) => setState(() => _windDir = v),
                  ),
                ),
              ],
            ),
          ),

          // Course list
          Expanded(
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (courses) {
                final selectedId = selectedAsync.value;

                // Sort: recommended first
                final recommendedIds =
                    recommended.map((c) => c.id).toSet();
                final sorted = [...courses]..sort((a, b) {
                    final aRec = recommendedIds.contains(a.id) ? 0 : 1;
                    final bRec = recommendedIds.contains(b.id) ? 0 : 1;
                    if (aRec != bRec) return aRec.compareTo(bRec);
                    final aNum = int.tryParse(a.courseNumber) ?? 9999;
                    final bNum = int.tryParse(b.courseNumber) ?? 9999;
                    return aNum.compareTo(bNum);
                  });

                if (sorted.isEmpty) {
                  return const Center(child: Text('No courses configured.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final course = sorted[i];
                    final isSelected = course.id == selectedId;
                    final rec =
                        getCourseRecommendation(course, _windDir);

                    return Card(
                      color: isSelected
                          ? AppColors.primary.withAlpha(20)
                          : null,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          child: Text(
                            course.courseNumber,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          course.courseName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${course.windDirectionBand} · ${course.distanceNm.toStringAsFixed(1)} nm · ${course.marks.length} marks',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RecBadge(label: rec),
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(Icons.check_circle,
                                    color: AppColors.primary, size: 18),
                              ),
                          ],
                        ),
                        onTap: () => _selectCourse(course),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectCourse(CourseConfig course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Select Course ${course.courseNumber}?'),
        content: Text(
            'Set "${course.courseName}" as the course for this event?\n\n'
            'This will notify the fleet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await ref
        .read(coursesRepositoryProvider)
        .selectCourseForEvent(widget.eventId, course.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Course ${course.courseNumber} selected for event.')),
      );
    }
  }
}

class _RecBadge extends StatelessWidget {
  const _RecBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = switch (label) {
      'RECOMMENDED' => (Colors.green, Colors.green.withAlpha(25)),
      'POSSIBLE' => (Colors.orange, Colors.orange.withAlpha(25)),
      'AVAILABLE' => (Colors.blue, Colors.blue.withAlpha(25)),
      _ => (Colors.grey, Colors.grey.withAlpha(25)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
