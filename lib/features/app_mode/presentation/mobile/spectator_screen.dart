import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../weather/data/models/live_weather.dart';
import '../../../weather/presentation/live_weather_providers.dart';

// ─────────────────────────────────────────────────────────────────
// Spectator Mode — read-only home: Weather · Next Event ·
// Live Leaderboard · Live Race Map
// ─────────────────────────────────────────────────────────────────

class SpectatorScreen extends ConsumerStatefulWidget {
  const SpectatorScreen({super.key});

  @override
  ConsumerState<SpectatorScreen> createState() => _SpectatorScreenState();
}

class _SpectatorScreenState extends ConsumerState<SpectatorScreen> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // 1) Weather Card
        const _WeatherCard(),
        const SizedBox(height: 10),

        // 2) Next Event Card
        const _NextEventCard(),
        const SizedBox(height: 10),

        // 3) Race Status + Live Leaderboard
        const _LeaderboardCard(),
        const SizedBox(height: 10),

        // 4) Live Race Map
        _LiveMapCard(mapController: _mapController),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 1) WEATHER CARD
// ═══════════════════════════════════════════════════════════════════

class _WeatherCard extends ConsumerWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(liveWeatherProvider);

    return weatherAsync.when(
      loading: () => _cardShell(
        icon: Icons.cloud,
        title: 'Weather',
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, __) => _emptyWeather(),
      data: (weather) {
        if (weather == null) return _emptyWeather();
        return _weatherContent(context, weather);
      },
    );
  }

  Widget _emptyWeather() {
    return _cardShell(
      icon: Icons.cloud_off,
      title: 'Weather',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            const Text('Weather feed unavailable',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _weatherContent(BuildContext context, LiveWeather w) {
    final age = w.staleness;
    final ageLabel = age.inMinutes < 1
        ? 'Just now'
        : age.inMinutes < 60
            ? '${age.inMinutes}m ago'
            : '${age.inHours}h ago';
    final isStale = w.isStale;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/live-wind'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.air,
                      color: isStale ? Colors.orange : Colors.blue, size: 20),
                  const SizedBox(width: 6),
                  const Text('Weather',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  if (isStale)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber,
                              size: 12, color: Colors.orange),
                          const SizedBox(width: 3),
                          Text('Stale',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right,
                      size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),

              // Wind hero
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Direction arrow
                  Transform.rotate(
                    angle: (w.dirDeg + 180) * 3.14159 / 180,
                    child: Icon(Icons.navigation,
                        size: 32,
                        color: isStale ? Colors.grey : Colors.blue),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            w.speedKts.toStringAsFixed(0),
                            style: const TextStyle(
                                fontSize: 36, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 3),
                          const Text('kts',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                      Text(
                        '${w.dirDeg}° ${w.windDirectionLabel}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Gust + temp column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (w.gustKts != null && w.gustKts! > 0)
                        Text(
                          'Gust ${w.gustKts!.toStringAsFixed(0)} kts',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600),
                        ),
                      if (w.tempF != null)
                        Text('${w.tempF!.toStringAsFixed(0)}°F',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      if (w.humidity != null)
                        Text('${w.humidity!.toStringAsFixed(0)}% humidity',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Footer: station + freshness
              Row(
                children: [
                  Icon(Icons.cell_tower,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(w.station.name,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                  const Spacer(),
                  Icon(Icons.access_time,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text(ageLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: isStale
                              ? Colors.orange
                              : Colors.grey.shade500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardShell(
      {required IconData icon,
      required String title,
      required Widget child}) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.blue),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 2) NEXT EVENT CARD
// ═══════════════════════════════════════════════════════════════════

class _NextEventCard extends StatelessWidget {
  const _NextEventCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .orderBy('date')
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.event_busy,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  const Text('No events scheduled',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
          );
        }

        final doc = docs.first;
        final d = doc.data() as Map<String, dynamic>;
        final name = d['name'] as String? ?? 'Race Day';
        final date = (d['date'] as Timestamp?)?.toDate() ?? now;
        final status = d['status'] as String? ?? 'setup';
        final courseName = d['courseName'] as String?;
        final courseNumber = d['courseNumber'] as String?;
        final startTime = (d['startTime'] as Timestamp?)?.toDate();
        final isToday = date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

        // Map status to display
        final (statusLabel, statusColor, statusIcon) = switch (status) {
          'setup' => ('Setting Up', Colors.orange, Icons.settings),
          'checkin_open' => ('Check-In Open', Colors.teal, Icons.how_to_reg),
          'start_pending' => ('Start Pending', Colors.amber, Icons.timer),
          'running' => ('RACING', Colors.green, Icons.sailing),
          'scoring' => ('Scoring', Colors.blue, Icons.sports_score),
          'review' => ('Review', Colors.purple, Icons.rate_review),
          'finalized' => ('Complete', Colors.indigo, Icons.check_circle),
          'abandoned' => ('Abandoned', Colors.red, Icons.cancel),
          _ => ('Upcoming', Colors.blue, Icons.event),
        };

        return Card(
          color: statusColor.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(statusLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      isToday
                          ? 'Today'
                          : DateFormat.MMMEd().format(date),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday
                              ? Colors.green.shade700
                              : Colors.grey.shade700),
                    ),
                    if (startTime != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('Started ${DateFormat.jm().format(startTime)}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700)),
                    ],
                  ],
                ),
                if (courseName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.map,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Course ${courseNumber ?? ''} — $courseName',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
                // Race elapsed clock when running
                if (status == 'running' && startTime != null) ...[
                  const SizedBox(height: 8),
                  _RaceElapsedBanner(startTime: startTime),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RaceElapsedBanner extends StatelessWidget {
  const _RaceElapsedBanner({required this.startTime});
  final DateTime startTime;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final elapsed = DateTime.now().difference(startTime);
        final h = elapsed.inHours;
        final m = elapsed.inMinutes % 60;
        final s = elapsed.inSeconds % 60;
        final label = h > 0
            ? '${h}h ${m.toString().padLeft(2, '0')}m'
            : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text('Race Time: $label',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 3) LIVE LEADERBOARD CARD
// ═══════════════════════════════════════════════════════════════════

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Find today's event and its raceStartId
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .limit(1)
          .snapshots(),
      builder: (context, eventSnap) {
        final eventDocs = eventSnap.data?.docs ?? [];
        if (eventDocs.isEmpty) {
          return _noRaceCard();
        }

        final eventData =
            eventDocs.first.data() as Map<String, dynamic>;
        final raceStartId = eventData['raceStartId'] as String?;
        final status = eventData['status'] as String? ?? 'setup';
        final isActive = ['running', 'scoring'].contains(status);
        final isComplete =
            ['review', 'finalized'].contains(status);

        if (raceStartId == null || raceStartId.isEmpty) {
          if (isActive) {
            return _inProgressNoFinishes();
          }
          return _noRaceCard();
        }

        // Stream finish records for this race
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('finish_records')
              .where('raceStartId', isEqualTo: raceStartId)
              .orderBy('position')
              .snapshots(),
          builder: (context, finishSnap) {
            final finishDocs = finishSnap.data?.docs ?? [];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.leaderboard,
                            color: isActive
                                ? Colors.green
                                : Colors.amber,
                            size: 20),
                        const SizedBox(width: 6),
                        Text(
                          isActive
                              ? 'Live Leaderboard'
                              : isComplete
                                  ? 'Race Results'
                                  : 'Leaderboard',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Spacer(),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('LIVE',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        TextButton(
                          onPressed: () =>
                              context.push('/leaderboard'),
                          child: const Text('Full Results',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),

                    if (finishDocs.isEmpty) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.hourglass_empty,
                                size: 32,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 6),
                            Text(
                              isActive
                                  ? 'Finish order will appear as boats finish'
                                  : 'No results available',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      const SizedBox(height: 6),
                      // Results header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                                width: 30,
                                child: Text('#',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Colors.grey))),
                            Expanded(
                                child: Text('Boat',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Colors.grey))),
                            SizedBox(
                                width: 60,
                                child: Text('Time',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Colors.grey))),
                            SizedBox(
                                width: 40,
                                child: Text('',
                                    style: TextStyle(fontSize: 11))),
                          ],
                        ),
                      ),
                      // Show top 8 finishes
                      ...finishDocs.take(8).map((doc) {
                        final f =
                            doc.data() as Map<String, dynamic>;
                        final pos = f['position'] as int? ?? 0;
                        final sail =
                            f['sailNumber'] as String? ?? '';
                        final boat =
                            f['boatName'] as String? ?? '';
                        final elapsed =
                            (f['elapsedSeconds'] as num?)
                                    ?.toDouble() ??
                                0;
                        final letterScore =
                            f['letterScore'] as String? ??
                                'finished';
                        final isFinished =
                            letterScore == 'finished';
                        final dur =
                            Duration(seconds: elapsed.toInt());
                        final timeStr = isFinished
                            ? '${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}'
                            : letterScore.toUpperCase();

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Colors.grey.shade100),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Text(
                                  isFinished ? '$pos' : '—',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: pos <= 3 && isFinished
                                        ? Colors.amber.shade800
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(sail,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 13)),
                                    if (boat.isNotEmpty)
                                      Text(boat,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors
                                                  .grey.shade600)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 60,
                                child: Text(timeStr,
                                    style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        color: isFinished
                                            ? Colors.black87
                                            : Colors.orange)),
                              ),
                              SizedBox(
                                width: 40,
                                child: pos <= 3 && isFinished
                                    ? Icon(
                                        Icons.emoji_events,
                                        size: 16,
                                        color: pos == 1
                                            ? Colors.amber
                                            : pos == 2
                                                ? Colors.grey
                                                : Colors
                                                    .brown.shade300,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (finishDocs.length > 8)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Center(
                            child: Text(
                              '+ ${finishDocs.length - 8} more',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _noRaceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.sailing, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            const Text('No active race',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Results will appear when a race is in progress.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _inProgressNoFinishes() {
    return Card(
      color: Colors.green.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.sailing, size: 40, color: Colors.green),
            const SizedBox(height: 8),
            const Text('Race In Progress',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green)),
            const SizedBox(height: 4),
            Text('Finish order will appear as boats cross the line.',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 4) LIVE RACE MAP CARD
// ═══════════════════════════════════════════════════════════════════

class _LiveMapCard extends StatelessWidget {
  const _LiveMapCard({required this.mapController});
  final MapController mapController;

  static const _mpycCenter = LatLng(36.6022, -121.8899);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.blue, size: 20),
                const SizedBox(width: 6),
                const Text('Live Race Map',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                // Live boat count badge
                _LiveBoatCount(),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: _buildMap(),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _LegendDot(color: Colors.blue, label: 'Boats'),
                const SizedBox(width: 12),
                _LegendDot(color: Colors.red, label: 'RC'),
                const SizedBox(width: 12),
                _LegendDot(color: Colors.orange, label: 'Marks'),
                const SizedBox(width: 12),
                _LegendDot(color: Colors.grey, label: 'Stale (>60s)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    // Layer 1: live positions
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('live_positions')
          .snapshots(),
      builder: (context, liveSnap) {
        final markers = <Marker>[];
        final liveDocs = liveSnap.data?.docs ?? [];

        for (final doc in liveDocs) {
          final d = doc.data() as Map<String, dynamic>;
          final lat = (d['lat'] as num?)?.toDouble();
          final lon = (d['lon'] as num?)?.toDouble();
          final sail = d['sailNumber'] as String? ?? '';
          final boat = d['boatName'] as String? ?? '';
          final speed = (d['speedKnots'] as num?)?.toDouble() ?? 0;
          final updatedAt = d['updatedAt'] as Timestamp?;
          final age = updatedAt != null
              ? DateTime.now().difference(updatedAt.toDate())
              : const Duration(hours: 1);
          final isStale = age.inSeconds > 60;
          final source = d['source'] as String? ?? 'skipper';
          final color = source == 'rc'
              ? Colors.red
              : isStale
                  ? Colors.grey
                  : Colors.blue;
          final label = sail.isNotEmpty ? sail : boat;

          if (lat != null && lon != null) {
            markers.add(Marker(
              point: LatLng(lat, lon),
              width: 80,
              height: 46,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isStale
                          ? null
                          : [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 5,
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sailing,
                            color: Colors.white, size: 11),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(label,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${speed.toStringAsFixed(1)} kn',
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: isStale
                                  ? Colors.grey
                                  : Colors.black87)),
                      if (isStale) ...[
                        const SizedBox(width: 3),
                        Text('${age.inMinutes}m',
                            style: const TextStyle(
                                fontSize: 8, color: Colors.orange)),
                      ],
                    ],
                  ),
                ],
              ),
            ));
          }
        }

        // Layer 2: course marks
        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('marks').snapshots(),
          builder: (context, markSnap) {
            final markDocs = markSnap.data?.docs ?? [];
            for (final doc in markDocs) {
              final md = doc.data() as Map<String, dynamic>;
              final lat = (md['lat'] as num?)?.toDouble();
              final lon = (md['lon'] as num?)?.toDouble();
              final name = md['name'] as String? ?? doc.id;
              if (lat != null && lon != null) {
                markers.add(Marker(
                  point: LatLng(lat, lon),
                  width: 40,
                  height: 40,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.orange, size: 20),
                      Text(name,
                          style: const TextStyle(
                              fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ));
              }
            }

            // Empty state overlay
            if (liveDocs.isEmpty && markDocs.isEmpty) {
              return Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: _mpycCenter,
                      initialZoom: 13.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                      ),
                    ],
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Waiting for boats to transmit positions',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              );
            }

            return FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: _mpycCenter,
                initialZoom: 13.5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            );
          },
        );
      },
    );
  }
}

class _LiveBoatCount extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('live_positions')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        if (count == 0) {
          return Text('No boats transmitting',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500));
        }
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sailing, size: 12, color: Colors.blue),
              const SizedBox(width: 4),
              Text('$count live',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
