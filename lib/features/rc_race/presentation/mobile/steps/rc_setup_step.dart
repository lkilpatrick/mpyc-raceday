import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../courses/domain/courses_repository.dart';
import '../../../../courses/presentation/courses_providers.dart';
import '../../../data/models/race_session.dart';
import '../../rc_race_providers.dart';

/// Step 1: Select course for the race session.
class RcSetupStep extends ConsumerStatefulWidget {
  const RcSetupStep({super.key, required this.session});

  final RaceSession session;

  @override
  ConsumerState<RcSetupStep> createState() => _RcSetupStepState();
}

class _RcSetupStepState extends ConsumerState<RcSetupStep> {
  double _windDir = 0;

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(allCoursesProvider);
    final recommended = ref.watch(recommendedCoursesProvider(_windDir));
    final session = widget.session;

    return Column(
      children: [
        // Course already selected?
        if (session.courseId != null && session.courseId!.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Course Selected',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        'Course ${session.courseNumber ?? ''} — ${session.courseName ?? ''}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Wind direction slider
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.explore, size: 20),
              const SizedBox(width: 8),
              Text('Wind: ${_windDir.toInt()}°',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
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

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: sorted.length,
                itemBuilder: (_, i) {
                  final course = sorted[i];
                  final isSelected = course.id == session.courseId;

                  return Card(
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isSelected ? Colors.blue : Colors.grey.shade300,
                        child: Text(course.courseNumber,
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            )),
                      ),
                      title: Text(course.courseName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14)),
                      subtitle: Text(
                        '${course.windDirectionBand} · ${course.distanceNm} nm',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: Colors.blue)
                          : null,
                      onTap: () => _selectCourse(course),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Proceed button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: (session.courseId != null &&
                      session.courseId!.isNotEmpty)
                  ? _proceedToCheckin
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Proceed to Check-In',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectCourse(dynamic course) async {
    await ref.read(rcRaceRepositoryProvider).setCourse(
          widget.session.id,
          courseId: course.id,
          courseName: course.courseName,
          courseNumber: course.courseNumber,
        );
    // Also update via courses repository for fleet broadcast
    await ref
        .read(coursesRepositoryProvider)
        .selectCourseForEvent(widget.session.id, course.id);
  }

  Future<void> _proceedToCheckin() async {
    await ref
        .read(rcRaceRepositoryProvider)
        .updateStatus(widget.session.id, RaceSessionStatus.checkinOpen);
  }
}
