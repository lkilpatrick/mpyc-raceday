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

/// Course sheet page — compact 2-column layout matching the MPYC printed
/// course sheet, with live wind recommendation and detail modals.
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
    final windDir = _windOverride ?? liveWindDir;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MPYC COURSE SHEET',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          )),
                  Text('Monterey Peninsula Yacht Club',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              const Spacer(),
              // Legend
              _legendDot(Colors.green, 'Recommended'),
              const SizedBox(width: 10),
              _legendDot(Colors.orange, 'Possible'),
              const SizedBox(width: 10),
              allCourses.when(
                data: (c) => Text('${c.length} courses',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Wind direction bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _WindDirectionBar(
            windDir: windDir,
            liveWindDir: liveWindDir,
            liveWindSpeed: liveWindSpeed,
            isOverride: _windOverride != null,
            weatherAsync: weatherAsync,
            recommendedCount:
                ref.watch(recommendedCoursesProvider(windDir)).length,
            onChanged: (v) => setState(() => _windOverride = v),
            onReset: () => setState(() => _windOverride = null),
          ),
        ),
        const SizedBox(height: 10),

        // ── 2-column course sheet ──
        Expanded(
          child: allCourses.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (_) {
              if (coursesGrouped.isEmpty) {
                return const Center(child: Text('No courses configured.'));
              }
              // Split groups into 2 columns:
              // Left: S_SW, W, NW   Right: N, INFLATABLE, LONG
              final leftGroups = <({WindGroup group, List<CourseConfig> courses})>[];
              final rightGroups = <({WindGroup group, List<CourseConfig> courses})>[];
              const rightIds = {'N', 'INFLATABLE', 'LONG'};
              for (final g in coursesGrouped) {
                if (rightIds.contains(g.group.id)) {
                  rightGroups.add(g);
                } else {
                  leftGroups.add(g);
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        children: [
                          for (final g in leftGroups) ...[
                            _WindGroupBlock(
                              group: g.group,
                              courses: g.courses,
                              windDir: windDir,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right column
                    Expanded(
                      child: Column(
                        children: [
                          for (final g in rightGroups) ...[
                            _WindGroupBlock(
                              group: g.group,
                              courses: g.courses,
                              windDir: windDir,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Wind Direction Bar — compact
// ═══════════════════════════════════════════════════════════════════

class _WindDirectionBar extends StatelessWidget {
  const _WindDirectionBar({
    required this.windDir,
    required this.liveWindDir,
    required this.liveWindSpeed,
    required this.isOverride,
    required this.weatherAsync,
    required this.recommendedCount,
    required this.onChanged,
    required this.onReset,
  });

  final double windDir;
  final double liveWindDir;
  final double liveWindSpeed;
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
    return dirs[((deg / 22.5) + 0.5).toInt() % 16];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withAlpha(25)),
      ),
      child: Row(
        children: [
          Transform.rotate(
            angle: (windDir * math.pi / 180) + math.pi,
            child: const Icon(Icons.navigation,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            '${_degToCompass(windDir)} ${windDir.toInt()}°',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(width: 8),
          if (isOverride) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text('MANUAL',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onReset,
              child: const Icon(Icons.refresh,
                  size: 14, color: AppColors.primary),
            ),
          ] else
            weatherAsync.when(
              data: (_) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'LIVE · ${liveWindSpeed.toStringAsFixed(1)} kts',
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
              loading: () => const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5)),
              error: (_, __) => const Text('offline',
                  style: TextStyle(fontSize: 9, color: Colors.orange)),
            ),
          const SizedBox(width: 8),
          Text('$recommendedCount rec.',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.primary.withAlpha(25),
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withAlpha(15),
              ),
              child: Slider(
                value: windDir,
                min: 0,
                max: 359,
                divisions: 359,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Wind Group Block — compact table for one wind band
// ═══════════════════════════════════════════════════════════════════

class _WindGroupBlock extends StatelessWidget {
  const _WindGroupBlock({
    required this.group,
    required this.courses,
    required this.windDir,
  });

  final WindGroup group;
  final List<CourseConfig> courses;
  final double windDir;

  @override
  Widget build(BuildContext context) {
    final gc = _parseHex(group.color);
    final bg = _parseHex(group.bgColor);
    final sorted = [...courses]
      ..sort((a, b) {
        final na = int.tryParse(a.courseNumber) ?? 0;
        final nb = int.tryParse(b.courseNumber) ?? 0;
        if (na != nb) return na.compareTo(nb);
        return a.courseNumber.compareTo(b.courseNumber);
      });

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: gc.withAlpha(80), width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Group header — compact colored bar
          Container(
            color: gc,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                Text(
                  group.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                if (group.id != 'INFLATABLE')
                  Text(
                    '${group.windRange[0]}° – ${group.windRange[1]}°',
                    style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),

          // Column headers
          Container(
            color: bg,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Row(
              children: [
                const SizedBox(
                    width: 32,
                    child: Text('#',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey))),
                const Expanded(
                    flex: 5,
                    child: Text('MARKS',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey))),
                const SizedBox(
                    width: 38,
                    child: Text('NM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey))),
                const SizedBox(
                    width: 40,
                    child: Text('FIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey))),
                SizedBox(width: 16), // status dot space
              ],
            ),
          ),

          // Course rows
          ...sorted.asMap().entries.map((entry) {
            final i = entry.key;
            final course = entry.value;
            final rec = getCourseRecommendation(course, windDir);
            return _CompactCourseRow(
              course: course,
              recommendation: rec,
              groupColor: gc,
              isEven: i.isEven,
              windDir: windDir,
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Compact Course Row — dense single-line row like a printed sheet
// ═══════════════════════════════════════════════════════════════════

class _CompactCourseRow extends ConsumerWidget {
  const _CompactCourseRow({
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
    final isRec = recommendation == 'RECOMMENDED';
    final isPoss = recommendation == 'POSSIBLE';
    final dotColor = isRec
        ? Colors.green
        : isPoss
            ? Colors.orange
            : Colors.transparent;

    // Highlight row background for recommended courses
    Color rowBg;
    if (isRec) {
      rowBg = Colors.green.withAlpha(12);
    } else if (isPoss) {
      rowBg = Colors.orange.withAlpha(8);
    } else {
      rowBg = isEven ? Colors.white : Colors.grey.shade50;
    }

    return Material(
      color: rowBg,
      child: InkWell(
        onTap: () => _showCourseDetail(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Course number
              SizedBox(
                width: 32,
                child: Text(
                  course.courseNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: groupColor,
                  ),
                ),
              ),
              // Mark sequence — the main content
              Expanded(
                flex: 5,
                child: Text(
                  course.markSequenceDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.grey.shade800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Distance
              SizedBox(
                width: 38,
                child: Text(
                  course.distanceNm > 0
                      ? course.distanceNm.toString()
                      : '—',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              // Finish
              SizedBox(
                width: 40,
                child: Text(
                  course.finishLocation == 'committee_boat'
                      ? 'CB'
                      : course.finishLocation == 'X'
                          ? 'X'
                          : course.finishLocation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              // Recommendation dot
              SizedBox(
                width: 16,
                child: dotColor != Colors.transparent
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      )
                    : const SizedBox.shrink(),
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
      builder: (dialogContext) => _CourseDetailDialog(
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
