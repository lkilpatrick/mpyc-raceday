import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/course_config.dart';
import '../../data/models/mark_distance.dart';
import '../courses_providers.dart';
import '../widgets/course_map_diagram.dart';
import '../../../weather/presentation/weather_providers.dart';

class CourseSelectionScreen extends ConsumerStatefulWidget {
  const CourseSelectionScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<CourseSelectionScreen> createState() =>
      _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends ConsumerState<CourseSelectionScreen> {
  String _selectedBand = 'NW';
  String _sortBy = 'distance';

  static const _bands = [
    ('S_SW', 'S/SW'),
    ('W', 'W'),
    ('NW', 'NW'),
    ('N', 'N'),
    ('N_EXT', 'N+'),
    ('INFLATABLE', 'Infl.'),
    ('LONG', 'Long'),
  ];

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(allCoursesProvider);
    final conditionsAsync = ref.watch(currentConditionsProvider);
    final distancesAsync = ref.watch(markDistancesProvider);

    final windDir = conditionsAsync.valueOrNull?.windDirectionDeg ?? 0;
    final windSpeed = conditionsAsync.valueOrNull?.windSpeedKts ?? 0;
    final windLabel = conditionsAsync.valueOrNull?.windDirectionLabel ?? '';

    // Auto-select band based on wind
    if (conditionsAsync.hasValue && conditionsAsync.valueOrNull != null) {
      final autoBand = _bandForWind(windDir);
      if (autoBand != _selectedBand && _selectedBand == 'NW') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedBand = autoBand);
        });
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Course')),
      body: Column(
        children: [
          // Current conditions card
          Card(
            margin: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.air,
                      size: 32,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wind from ${windDir.toStringAsFixed(0)}° ($windLabel)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        Text(
                          '${windSpeed.toStringAsFixed(0)} kts',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Wind band selector
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _bands.map((b) {
                final (id, label) = b;
                final isSelected = _selectedBand == id;
                final isWindBand = _bandForWind(windDir) == id;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label),
                        if (isWindBand) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.air, size: 14),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedBand = id),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),

          // Multi-fleet warning
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.orange.shade50,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Multiple fleets: Do NOT select courses where fleets may converge from different directions at marks.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Course list
          Expanded(
            child: coursesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (allCourses) {
                var filtered = allCourses
                    .where((c) => c.windDirectionBand == _selectedBand)
                    .toList();
                // Also include N_EXT in N tab and vice versa
                if (_selectedBand == 'N') {
                  filtered.addAll(allCourses
                      .where((c) => c.windDirectionBand == 'N_EXT'));
                }

                if (_sortBy == 'distance') {
                  filtered.sort(
                      (a, b) => a.distanceNm.compareTo(b.distanceNm));
                } else {
                  filtered.sort((a, b) {
                    final aNum = int.tryParse(a.courseNumber) ?? 999;
                    final bNum = int.tryParse(b.courseNumber) ?? 999;
                    return aNum.compareTo(bNum);
                  });
                }

                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No courses for this wind band'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final rec = getCourseRecommendation(c, windDir);
                    return _CourseCard(
                      course: c,
                      recommendation: rec,
                      distances:
                          distancesAsync.valueOrNull ?? [],
                      windDir: windDir,
                      onTap: () => _showCourseDetail(
                          c, distancesAsync.valueOrNull ?? [], windDir),
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

  String _bandForWind(double dir) {
    if (dir >= 200 && dir < 260) return 'S_SW';
    if (dir >= 260 && dir < 295) return 'W';
    if (dir >= 295 && dir < 320) return 'NW';
    if (dir >= 320 || dir < 35) return 'N';
    return 'NW'; // default
  }

  void _showCourseDetail(
    CourseConfig course,
    List<MarkDistance> distances,
    double windDir,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _CourseDetailSheet(
          course: course,
          distances: distances,
          windDir: windDir,
          eventId: widget.eventId,
          ref: ref,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.recommendation,
    required this.distances,
    required this.windDir,
    required this.onTap,
  });

  final CourseConfig course;
  final String recommendation;
  final List<MarkDistance> distances;
  final double windDir;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final recColor = switch (recommendation) {
      'RECOMMENDED' => Colors.green,
      'POSSIBLE' => Colors.orange,
      'AVAILABLE' => Colors.blue,
      _ => Colors.red,
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Course number
              SizedBox(
                width: 48,
                child: Text(
                  course.courseNumber,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.markSequenceDisplay,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${course.distanceNm} nm',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          course.finishLocation == 'mark_x'
                              ? Icons.location_on
                              : Icons.flag,
                          size: 14,
                          color: Colors.grey,
                        ),
                        Text(
                          course.finishLocation == 'mark_x'
                              ? 'Mark X'
                              : 'CB',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (course.canMultiply) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('x2/x3',
                                style: TextStyle(fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                    if (course.requiresInflatable)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Requires ${course.inflatableType ?? "inflatable"} mark',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Recommendation badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: recColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recommendation,
                  style: TextStyle(
                    color: recColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseDetailSheet extends StatelessWidget {
  const _CourseDetailSheet({
    required this.course,
    required this.distances,
    required this.windDir,
    required this.eventId,
    required this.ref,
    required this.scrollController,
  });

  final CourseConfig course;
  final List<MarkDistance> distances;
  final double windDir;
  final String eventId;
  final WidgetRef ref;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Course ${course.courseNumber}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(course.markSequenceDisplay),
        Text('${course.distanceNm} nm'),
        const SizedBox(height: 16),

        // Course diagram
        Center(
          child: CourseMapDiagram(
            course: course,
            distances: distances,
            windDirectionDeg: windDir,
            size: const Size(280, 280),
          ),
        ),
        const SizedBox(height: 16),

        // Mark sequence detail
        Text('Mark Sequence',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...course.marks.map((m) {
          final roundLabel =
              m.rounding == MarkRounding.port ? 'Port' : 'Starboard';
          final roundColor =
              m.rounding == MarkRounding.port ? Colors.red : Colors.green;
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: roundColor,
              child: Text('${m.order}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12)),
            ),
            title: Text(m.markName),
            subtitle: Text('Round to $roundLabel'),
            trailing: m.isFinish
                ? const Chip(
                    label: Text('FINISH', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.green,
                  )
                : null,
          );
        }),

        // Warnings
        if (course.finishLocation == 'mark_x')
          Card(
            color: Colors.amber.shade50,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This course finishes at Mark X. Ensure finish boat is positioned.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (course.requiresInflatable)
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This course requires ${course.inflatableType ?? "inflatable"} marks to be set before the start.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Select button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: () => _selectCourse(context),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'SELECT THIS COURSE',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _selectCourse(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Set Course ${course.courseNumber}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.markSequenceDisplay),
            Text('Distance: ${course.distanceNm} nm'),
            const SizedBox(height: 8),
            const Text('This will notify all checked-in boats.'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;

    await ref
        .read(coursesRepositoryProvider)
        .selectCourseForEvent(eventId, course.id);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Course ${course.courseNumber} selected and fleet notified')),
      );
    }
  }
}
