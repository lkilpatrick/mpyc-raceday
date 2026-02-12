import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../shared/utils/web_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../courses/data/models/course_config.dart';
import '../../../courses/data/models/mark_distance.dart';
import '../../../courses/presentation/courses_providers.dart';
import '../../../courses/presentation/widgets/course_map_diagram.dart';
import '../../../crew_assignment/domain/crew_assignment_repository.dart';
import '../../../crew_assignment/presentation/crew_assignment_providers.dart';
import '../../../weather/data/models/live_weather.dart';
import '../../../weather/presentation/live_weather_providers.dart';

/// Register the Windy.app forecast widget iframe as a platform view.
bool _windyViewRegistered = false;
void _ensureWindyViewRegistered() {
  if (_windyViewRegistered || !kIsWeb) return;
  _windyViewRegistered = true;
  registerPlatformViewFactory(
    'windy-forecast-widget',
    (int viewId) => createIFrameElement(src: 'windy_widget.html'),
  );
}

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  static const _sections = <_NavSection>[
    _NavSection(
      title: 'Race Operations',
      items: [
        _NavItem(Icons.calendar_month, 'Season Calendar', '/season-calendar',
            'View and manage the race season schedule'),
        _NavItem(Icons.sailing, 'Race Events', '/race-events',
            'Upcoming races, results, and event details'),
        _NavItem(Icons.groups, 'Crew Management', '/crew-management',
            'Assign and track race committee crew'),
        _NavItem(Icons.map, 'Courses', '/courses',
            'Course configurations, marks, and diagrams'),
        _NavItem(Icons.checklist, 'Checklists', '/checklists-admin',
            'Pre-race and safety checklists'),
        _NavItem(Icons.report_problem, 'Incidents & Protests',
            '/incidents', 'File and review incidents'),
        _NavItem(Icons.gavel, 'Racing Rules', '/rules-reference',
            'Browse and search the Racing Rules of Sailing'),
      ],
    ),
    _NavSection(
      title: 'Fleet Maintenance',
      items: [
        _NavItem(Icons.build, 'Maintenance', '/maintenance',
            'Track maintenance requests and repairs'),
      ],
    ),
    _NavSection(
      title: 'Administration',
      items: [
        _NavItem(Icons.people, 'Members', '/members',
            'Club membership directory'),
        _NavItem(Icons.sync, 'Sync Dashboard', '/sync-dashboard',
            'ClubSpot sync status and logs'),
        _NavItem(Icons.settings, 'System Settings', '/system-settings',
            'App configuration and preferences'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(liveWeatherProvider);
    final stationsAsync = ref.watch(allStationsWeatherProvider);
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final allCourses = ref.watch(allCoursesProvider);
    final distancesAsync = ref.watch(markDistancesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Welcome to MPYC Race Day',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),

          // ── Hero Cards Row ──
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final children = <Widget>[
              _WeatherCard(
                weather: weatherAsync,
                stations: stationsAsync,
              ),
              _NextRaceCard(eventsAsync: eventsAsync),
              _FeaturedCourseCard(
                coursesAsync: allCourses,
                distancesAsync: distancesAsync,
              ),
            ];
            if (wide) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children
                      .map((c) => Expanded(child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: c,
                          )))
                      .toList(),
                ),
              );
            }
            return Column(
              children: children
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: c,
                      ))
                  .toList(),
            );
          }),

          const SizedBox(height: 24),

          // ── Wind Forecast Widget ──
          const _WindyForecastCard(),

          const SizedBox(height: 32),

          // ── Quick Navigation ──
          for (final section in _sections) ...[
            Text(section.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                )),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 500
                        ? 2
                        : 1;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: section.items.map((item) {
                    final cardWidth =
                        (constraints.maxWidth - (crossCount - 1) * 12) /
                            crossCount;
                    return SizedBox(
                      width: cardWidth,
                      child: _NavCard(item: item),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Weather Card — primary station + station list
// ═══════════════════════════════════════════════════════════════════

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather, required this.stations});
  final AsyncValue<LiveWeather?> weather;
  final AsyncValue<List<LiveWeather>> stations;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B3A5C), Color(0xFF2A5A8C)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: weather.when(
            loading: () => const SizedBox(
              height: 180,
              child: Center(
                  child: CircularProgressIndicator(color: Colors.white70)),
            ),
            error: (_, __) => const SizedBox(
              height: 180,
              child: Center(
                  child: Text('Weather unavailable',
                      style: TextStyle(color: Colors.white70))),
            ),
            data: (w) {
              if (w == null) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                      child: Text('No weather data',
                          style: TextStyle(color: Colors.white70))),
                );
              }
              final stationList = stations.value ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.cloud, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text('CURRENT CONDITIONS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          )),
                      const Spacer(),
                      if (w.isStale)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(50),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('STALE',
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 10)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Primary station — big wind display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WindCompass(dirDeg: w.dirDeg, size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${w.speedKts.round()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    )),
                                const SizedBox(width: 3),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text('kts',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13)),
                                ),
                                if (w.gustKts != null) ...[
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text('G ${w.gustKts!.round()}',
                                        style: TextStyle(
                                          color: Colors.amber.shade300,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('${w.windDirectionLabel} (${w.dirDeg}°)',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Temp + conditions
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (w.tempF != null)
                            Text('${w.tempF!.round()}°F',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600)),
                          if (w.textDescription != null &&
                              w.textDescription!.isNotEmpty)
                            Text(w.textDescription!,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),

                  // Station list
                  if (stationList.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 8),
                    Text('NEARBY STATIONS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        )),
                    const SizedBox(height: 6),
                    ...stationList.take(5).map((s) => _stationRow(s)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _stationRow(LiveWeather s) {
    final typeColor = switch (s.stationType) {
      'ambient' => Colors.greenAccent.shade100,
      'coops' => Colors.tealAccent.shade100,
      'wunderground' => Colors.orange.shade200,
      _ => Colors.lightBlue.shade200,
    };
    final hasWind = s.speedKts > 0 || s.dirDeg > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: s.isStale ? Colors.orange : Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              s.station.name,
              style: TextStyle(color: typeColor, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasWind) ...[
            Text(
              '${s.windDirectionLabel} ${s.speedKts.round()} kts',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            if (s.gustKts != null && s.gustKts! > 0)
              Text(' G${s.gustKts!.round()}',
                  style: TextStyle(
                      color: Colors.amber.shade300,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
          ],
          if (!hasWind && s.waterTempF != null)
            Text('Water ${s.waterTempF!.round()}°F',
                style: TextStyle(color: Colors.cyan.shade200, fontSize: 11)),
          if (s.tempF != null) ...[
            const SizedBox(width: 8),
            Text('${s.tempF!.round()}°F',
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Windy.app Forecast Widget (embedded iframe)
// ═══════════════════════════════════════════════════════════════════

class _WindyForecastCard extends StatefulWidget {
  const _WindyForecastCard();

  @override
  State<_WindyForecastCard> createState() => _WindyForecastCardState();
}

class _WindyForecastCardState extends State<_WindyForecastCard> {
  @override
  void initState() {
    super.initState();
    _ensureWindyViewRegistered();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(Icons.air, color: Colors.blue.shade400, size: 18),
                const SizedBox(width: 8),
                Text('WIND FORECAST — MPYC',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    )),
                const Spacer(),
                Text('Powered by Windy.app',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 420,
            child: HtmlElementView(viewType: 'windy-forecast-widget'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Wind Compass
// ═══════════════════════════════════════════════════════════════════

class _WindCompass extends StatelessWidget {
  const _WindCompass({required this.dirDeg, required this.size});
  final int dirDeg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CompassPainter(dirDeg: dirDeg),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.dirDeg});
  final int dirDeg;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withAlpha(30)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Cardinal labels
    const labels = ['N', 'E', 'S', 'W'];
    const angles = [0.0, 90.0, 180.0, 270.0];
    for (var i = 0; i < 4; i++) {
      final angle = (angles[i] - 90) * math.pi / 180;
      final labelRadius = radius - 10;
      final pos = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    // Arrow (points in the direction wind is coming FROM)
    final arrowAngle = (dirDeg - 90) * math.pi / 180;
    final arrowLen = radius - 16;
    final tip = Offset(
      center.dx + arrowLen * math.cos(arrowAngle),
      center.dy + arrowLen * math.sin(arrowAngle),
    );
    final tail = Offset(
      center.dx - (arrowLen * 0.4) * math.cos(arrowAngle),
      center.dy - (arrowLen * 0.4) * math.sin(arrowAngle),
    );

    canvas.drawLine(
      tail,
      tip,
      Paint()
        ..color = Colors.amber
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Arrowhead
    final headAngle1 = arrowAngle + 2.6;
    final headAngle2 = arrowAngle - 2.6;
    final headLen = 8.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - headLen * math.cos(headAngle1),
          tip.dy - headLen * math.sin(headAngle1))
      ..lineTo(tip.dx - headLen * math.cos(headAngle2),
          tip.dy - headLen * math.sin(headAngle2))
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.amber);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => old.dirDeg != dirDeg;
}

// ═══════════════════════════════════════════════════════════════════
// Next Race Card
// ═══════════════════════════════════════════════════════════════════

class _NextRaceCard extends StatelessWidget {
  const _NextRaceCard({required this.eventsAsync});
  final AsyncValue<List<RaceEvent>> eventsAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: eventsAsync.when(
          loading: () => const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(
            height: 140,
            child: Center(child: Text('Unable to load events')),
          ),
          data: (events) {
            final now = DateTime.now();
            final upcoming = events
                .where((e) =>
                    e.status != EventStatus.cancelled &&
                    e.date.isAfter(now.subtract(const Duration(hours: 12))))
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));

            if (upcoming.isEmpty) {
              return SizedBox(
                height: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(context, Icons.sailing, 'NEXT RACE'),
                    const Spacer(),
                    Center(
                      child: Text('No upcoming races',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14)),
                    ),
                    const Spacer(),
                  ],
                ),
              );
            }

            final next = upcoming.first;
            final daysUntil = next.date
                .difference(DateTime(now.year, now.month, now.day))
                .inDays;
            final countdownText = daysUntil == 0
                ? 'Today'
                : daysUntil == 1
                    ? 'Tomorrow'
                    : '$daysUntil days away';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(context, Icons.sailing, 'NEXT RACE'),
                const SizedBox(height: 16),
                Text(next.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(next.seriesName,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _infoPill(Icons.calendar_today,
                        DateFormat('EEE, MMM d').format(next.date)),
                    const SizedBox(width: 8),
                    if (next.startTime != null)
                      _infoPill(Icons.access_time,
                          '${next.startTime!.format(context)}'),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: daysUntil <= 1
                            ? Colors.orange.withAlpha(30)
                            : Colors.blue.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        countdownText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: daysUntil <= 1
                              ? Colors.orange.shade800
                              : Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.group, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${next.confirmedCount}/${next.crewSlots.length} crew',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => context.go('/race-events'),
                      child: Text('View all →',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ),
                if (upcoming.length > 1) ...[
                  const SizedBox(height: 12),
                  ...upcoming.skip(1).take(2).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.circle,
                                size: 6, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('MMM d').format(e.date)} — ${e.name}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Featured Course Card — random course with diagram + turn list
// ═══════════════════════════════════════════════════════════════════

class _FeaturedCourseCard extends StatefulWidget {
  const _FeaturedCourseCard({
    required this.coursesAsync,
    required this.distancesAsync,
  });
  final AsyncValue<List<CourseConfig>> coursesAsync;
  final AsyncValue<List<MarkDistance>> distancesAsync;

  @override
  State<_FeaturedCourseCard> createState() => _FeaturedCourseCardState();
}

class _FeaturedCourseCardState extends State<_FeaturedCourseCard> {
  CourseConfig? _featured;
  int? _lastSeed;

  void _pickRandom(List<CourseConfig> courses) {
    if (courses.isEmpty) return;
    // Use day-of-year as seed so it changes daily but stays stable per session
    final seed = DateTime.now().difference(DateTime(2024)).inDays;
    if (_lastSeed == seed && _featured != null) return;
    _lastSeed = seed;
    final rng = math.Random(seed);
    _featured = courses[rng.nextInt(courses.length)];
  }

  void _shuffle(List<CourseConfig> courses) {
    if (courses.isEmpty) return;
    final rng = math.Random();
    setState(() {
      _featured = courses[rng.nextInt(courses.length)];
      _lastSeed = -1; // force override
    });
  }

  @override
  Widget build(BuildContext context) {
    final courses = widget.coursesAsync.value ?? [];
    final distances = widget.distancesAsync.value ?? [];
    _pickRandom(courses);
    final featured = _featured;
    final wg = featured?.windGroup;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: featured != null && wg != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_parseHex(wg.bgColor), Colors.white],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.school, color: Colors.grey.shade500, size: 16),
                  const SizedBox(width: 6),
                  Text('LEARN A COURSE',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      )),
                  const Spacer(),
                  if (courses.isNotEmpty)
                    InkWell(
                      onTap: () => _shuffle(courses),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('Shuffle',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (featured == null)
                const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // Course title + wind group badge
                Row(
                  children: [
                    Text('Course ${featured.courseNumber}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (wg != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              _parseHex(wg.color).withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: _parseHex(wg.color).withAlpha(80)),
                        ),
                        child: Text(wg.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _parseHex(wg.color),
                            )),
                      ),
                  ],
                ),
                if (featured.courseName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(featured.courseName,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ),

                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${featured.distanceNm} nm',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700)),
                    const SizedBox(width: 12),
                    Text('Finish: ${featured.finishLocation}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),

                const SizedBox(height: 12),

                // Course diagram
                if (distances.isNotEmpty)
                  Center(
                    child: CourseMapDiagram(
                      course: featured,
                      distances: distances,
                      size: const Size(220, 180),
                    ),
                  ),

                const SizedBox(height: 12),

                // Turn-by-turn list
                ..._buildTurnList(featured),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => context.go('/courses'),
                    child: Text('View all courses →',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTurnList(CourseConfig course) {
    final seq = course.sequenceMarks;
    if (seq.isEmpty) return [];

    Widget row(IconData icon, Color color, String label, String detail) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 12, color: color),
              ),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text(detail,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final items = <Widget>[
      row(Icons.flag, Colors.green, 'Start', 'Cross the start line'),
    ];

    for (final m in seq) {
      final rounding = m.rounding == MarkRounding.port ? 'port' : 'starboard';
      items.add(row(
        m.rounding == MarkRounding.port ? Icons.turn_left : Icons.turn_right,
        m.rounding == MarkRounding.port ? Colors.red : Colors.green,
        'Mark ${m.markName}',
        'Leave to $rounding',
      ));
    }

    final finishDetail = course.finishType == 'club_mark' && course.finishMarkId != null
        ? 'Finish at Mark ${course.finishMarkId}'
        : 'Finish at committee boat';
    items.add(row(Icons.sports_score, Colors.green, 'Finish', finishDetail));

    return items;
  }

  static Color _parseHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ═══════════════════════════════════════════════════════════════════
// Quick Nav Helpers
// ═══════════════════════════════════════════════════════════════════

class _NavSection {
  const _NavSection({required this.title, required this.items});
  final String title;
  final List<_NavItem> items;
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.route, this.description);
  final IconData icon;
  final String label;
  final String route;
  final String description;
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.item});
  final _NavItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(item.icon, size: 28, color: Theme.of(context).primaryColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(item.description,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
