import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpyc_raceday/core/theme.dart';

import '../../../weather/data/models/live_weather.dart';
import '../../../weather/presentation/live_weather_providers.dart';
import '../../data/models/course_config.dart';
import '../../data/models/mark.dart';
import '../../data/models/mark_distance.dart';
import '../courses_providers.dart';
import '../widgets/course_map_diagram.dart';
import '../widgets/course_map_widget.dart';

/// Course sheet page — read-only view of all courses organized by wind
/// direction band, with live wind recommendation and detail modals.
class CourseSheetPage extends ConsumerStatefulWidget {
  const CourseSheetPage({super.key});

  @override
  ConsumerState<CourseSheetPage> createState() => _CourseSheetPageState();
}

class _CourseSheetPageState extends ConsumerState<CourseSheetPage> {
  double? _windOverride;

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(liveWeatherProvider);
    final coursesGrouped = ref.watch(coursesGroupedByWindProvider);
    final allCourses = ref.watch(allCoursesProvider);

    final liveWindDir = weatherAsync.value?.dirDeg.toDouble() ?? 0;
    final liveWindSpeed = weatherAsync.value?.speedKts ?? 0;
    final liveWindLabel = weatherAsync.value?.windDirectionLabel ?? '';
    final windDir = _windOverride ?? liveWindDir;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Text('MPYC Course Sheet',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              allCourses.when(
                data: (c) => Text('${c.length} courses',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // ── Wind direction bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _WindDirectionBar(
            windDir: windDir,
            liveWindDir: liveWindDir,
            liveWindSpeed: liveWindSpeed,
            liveWindLabel: liveWindLabel,
            isOverride: _windOverride != null,
            weatherAsync: weatherAsync,
            recommendedCount:
                ref.watch(recommendedCoursesProvider(windDir)).length,
            onChanged: (v) => setState(() => _windOverride = v),
            onReset: () => setState(() => _windOverride = null),
          ),
        ),
        const SizedBox(height: 16),

        // ── Course table ──
        Expanded(
          child: allCourses.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (_) {
              if (coursesGrouped.isEmpty) {
                return const Center(child: Text('No courses configured.'));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  for (final group in coursesGrouped) ...[
                    _WindGroupTable(
                      group: group.group,
                      courses: group.courses,
                      windDir: windDir,
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Wind Direction Bar
// ═══════════════════════════════════════════════════════════════════

class _WindDirectionBar extends StatelessWidget {
  const _WindDirectionBar({
    required this.windDir,
    required this.liveWindDir,
    required this.liveWindSpeed,
    required this.liveWindLabel,
    required this.isOverride,
    required this.weatherAsync,
    required this.recommendedCount,
    required this.onChanged,
    required this.onReset,
  });

  final double windDir;
  final double liveWindDir;
  final double liveWindSpeed;
  final String liveWindLabel;
  final bool isOverride;
  final AsyncValue<LiveWeather?> weatherAsync;
  final int recommendedCount;
  final ValueChanged<double> onChanged;
  final VoidCallback onReset;

  String _degToCompass(double deg) {
    const dirs = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    final index = ((deg / 22.5) + 0.5).toInt() % 16;
    return dirs[index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Wind compass icon
              Transform.rotate(
                angle: (windDir * math.pi / 180) + math.pi,
                child: const Icon(Icons.navigation,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              // Wind info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_degToCompass(windDir)} ${windDir.toInt()}°',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      if (isOverride) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('MANUAL',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange)),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: onReset,
                          child: const Icon(Icons.refresh,
                              size: 16, color: AppColors.primary),
                        ),
                      ] else
                        weatherAsync.when(
                          data: (_) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LIVE · ${liveWindSpeed.toStringAsFixed(1)} kts',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ),
                          loading: () => const SizedBox(
                              width: 12,
                              height: 12,
                              child:
                                  CircularProgressIndicator(strokeWidth: 1.5)),
                          error: (_, __) => const Text('(offline)',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.orange)),
                        ),
                    ],
                  ),
                  Text(
                    '$recommendedCount courses recommended for this wind',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const Spacer(),
              // Legend
              _legendDot(Colors.green, 'Recommended'),
              const SizedBox(width: 12),
              _legendDot(Colors.orange, 'Possible'),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withAlpha(30),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withAlpha(20),
            ),
            child: Slider(
              value: windDir,
              min: 0,
              max: 359,
              divisions: 359,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Wind Group Table — one section per wind direction band
// ═══════════════════════════════════════════════════════════════════

class _WindGroupTable extends StatelessWidget {
  const _WindGroupTable({
    required this.group,
    required this.courses,
    required this.windDir,
  });

  final WindGroup group;
  final List<CourseConfig> courses;
  final double windDir;

  @override
  Widget build(BuildContext context) {
    final groupColor = _parseHex(group.color);
    final bgColor = _parseHex(group.bgColor);
    final sorted = [...courses]
      ..sort((a, b) => a.courseNumber.compareTo(b.courseNumber));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: groupColor.withAlpha(60)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Group header
          Container(
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 24,
                  decoration: BoxDecoration(
                    color: groupColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: groupColor,
                        ),
                      ),
                      if (group.id != 'INFLATABLE')
                        Text(
                          'Wind ${group.windRange[0]}° – ${group.windRange[1]}°',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${sorted.length} course${sorted.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // Table header
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Row(
              children: [
                SizedBox(width: 48, child: Text('#', style: _headerStyle)),
                Expanded(flex: 3, child: Text('Course', style: _headerStyle)),
                SizedBox(
                    width: 60,
                    child: Text('Dist', style: _headerStyle)),
                Expanded(
                    flex: 4,
                    child: Text('Mark Sequence', style: _headerStyle)),
                SizedBox(
                    width: 70,
                    child: Text('Finish', style: _headerStyle)),
                SizedBox(
                    width: 80,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('Status', style: _headerStyle),
                    )),
              ],
            ),
          ),

          // Course rows
          ...sorted.asMap().entries.map((entry) {
            final i = entry.key;
            final course = entry.value;
            final rec = getCourseRecommendation(course, windDir);
            final isEven = i % 2 == 0;

            return _CourseRow(
              course: course,
              recommendation: rec,
              groupColor: groupColor,
              isEven: isEven,
              windDir: windDir,
            );
          }),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.grey,
  );
}

// ═══════════════════════════════════════════════════════════════════
// Course Row — single row in the table
// ═══════════════════════════════════════════════════════════════════

class _CourseRow extends ConsumerWidget {
  const _CourseRow({
    required this.course,
    required this.recommendation,
    required this.groupColor,
    required this.isEven,
    required this.windDir,
  });

  final CourseConfig course;
  final String recommendation;
  final Color groupColor;
  final bool isEven;
  final double windDir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (badgeColor, badgeBg, badgeText) = switch (recommendation) {
      'RECOMMENDED' => (
          Colors.green,
          Colors.green.withAlpha(25),
          'RECOMMENDED'
        ),
      'POSSIBLE' => (Colors.orange, Colors.orange.withAlpha(25), 'POSSIBLE'),
      'AVAILABLE' => (Colors.blue, Colors.blue.withAlpha(25), 'AVAILABLE'),
      _ => (Colors.grey.shade400, Colors.grey.withAlpha(10), ''),
    };

    return Material(
      color: isEven ? Colors.white : Colors.grey.shade50,
      child: InkWell(
        onTap: () => _showCourseDetail(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Course number badge
              SizedBox(
                width: 48,
                child: CircleAvatar(
                  backgroundColor: groupColor,
                  radius: 15,
                  child: Text(
                    course.courseNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              // Course name
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.courseName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    if (course.requiresInflatable)
                      Text(
                        'Inflatable: ${course.inflatableType ?? "required"}',
                        style: TextStyle(
                            fontSize: 10, color: Colors.purple.shade400),
                      ),
                  ],
                ),
              ),
              // Distance
              SizedBox(
                width: 60,
                child: Text(
                  course.distanceNm > 0
                      ? '${course.distanceNm} nm'
                      : 'Var',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              // Mark sequence
              Expanded(
                flex: 4,
                child: Text(
                  course.markSequenceDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Finish
              SizedBox(
                width: 70,
                child: Text(
                  course.finishLocation == 'X' ? 'Mark X' : course.finishLocation,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              // Recommendation badge
              SizedBox(
                width: 80,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: badgeText.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: badgeColor.withAlpha(60)),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCourseDetail(BuildContext context, WidgetRef ref) {
    final marks = ref.read(marksProvider).value ?? const <Mark>[];
    final distances =
        ref.read(markDistancesProvider).value ?? const <MarkDistance>[];

    showDialog(
      context: context,
      builder: (_) => _CourseDetailDialog(
        course: course,
        marks: marks,
        distances: distances,
        windDir: windDir,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Course Detail Dialog — map + diagram + full info
// ═══════════════════════════════════════════════════════════════════

class _CourseDetailDialog extends StatelessWidget {
  const _CourseDetailDialog({
    required this.course,
    required this.marks,
    required this.distances,
    required this.windDir,
  });

  final CourseConfig course;
  final List<Mark> marks;
  final List<MarkDistance> distances;
  final double windDir;

  @override
  Widget build(BuildContext context) {
    final groupColor = _parseHex(course.windGroup?.color);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.75).clamp(600.0, 1000.0);

    return Dialog(
      child: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _parseHex(course.windGroup?.bgColor),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: groupColor,
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.courseName,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _chip(Icons.explore,
                                '${course.windGroup?.label ?? course.windDirectionBand}'),
                            _chip(Icons.straighten,
                                '${course.distanceNm} nm'),
                            _chip(Icons.pin_drop,
                                'Wind ${course.windDirMin}°–${course.windDirMax}°'),
                            _chip(Icons.flag,
                                'Finish: ${course.finishLocation}'),
                            if (course.canMultiply)
                              _chip(Icons.repeat, 'Can multiply (x2)'),
                            if (course.requiresInflatable)
                              _chip(Icons.circle,
                                  'Inflatable: ${course.inflatableType ?? "yes"}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Body — scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mark sequence
                    Text('Mark Sequence',
                        style: theme.textTheme.titleSmall
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
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Marks detail
                    ...course.marks.map((m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text('${m.order}.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600)),
                              ),
                              if (m.isStart || m.isFinish)
                                Icon(
                                  m.isStart
                                      ? Icons.flag
                                      : Icons.sports_score,
                                  size: 12,
                                  color:
                                      m.isStart ? Colors.blue : Colors.green,
                                )
                              else
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color:
                                      m.rounding == MarkRounding.port
                                          ? Colors.red
                                          : Colors.green,
                                ),
                              const SizedBox(width: 6),
                              Text(
                                m.isStart
                                    ? 'START (at Mark 1)'
                                    : m.isFinish
                                        ? 'FINISH (at ${m.markName})'
                                        : '${m.markName} (${m.rounding.name})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: (m.isStart || m.isFinish)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 20),

                    // Map + Diagram side by side
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _mapSection(theme)),
                              const SizedBox(width: 16),
                              Expanded(child: _diagramSection(theme)),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _mapSection(theme),
                            const SizedBox(height: 16),
                            _diagramSection(theme),
                          ],
                        );
                      },
                    ),

                    if (course.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Notes',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(course.notes,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade700)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Race Area Map',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        CourseMapWidget(
          marks: marks,
          course: course,
          height: 350,
        ),
      ],
    );
  }

  Widget _diagramSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Course Diagram',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CourseMapDiagram(
            course: course,
            distances: distances,
            windDirectionDeg: windDir,
            size: const Size(350, 350),
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════

Color _parseHex(String? hex) {
  if (hex != null && hex.startsWith('#') && hex.length == 7) {
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }
  return AppColors.primary;
}
