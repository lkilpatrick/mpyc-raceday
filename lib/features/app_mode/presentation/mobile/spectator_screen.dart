import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

/// Spectator Live Race screen — shows a live map with GPS tracks from
/// skippers and RC, plus quick links to leaderboard and past results.
class SpectatorScreen extends ConsumerStatefulWidget {
  const SpectatorScreen({super.key});

  @override
  ConsumerState<SpectatorScreen> createState() => _SpectatorScreenState();
}

class _SpectatorScreenState extends ConsumerState<SpectatorScreen> {
  final _mapController = MapController();

  // MPYC harbor center
  static const _mpycCenter = LatLng(36.6022, -121.8899);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Race status
        const _RaceStatusCard(),
        const SizedBox(height: 12),

        // Live Race Map
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text('Live Race Map',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    Text('GPS tracks from fleet',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              SizedBox(
                height: 280,
                child: _LiveRaceMap(mapController: _mapController),
              ),
              // Legend
              Padding(
                padding: const EdgeInsets.all(10),
                child: Wrap(
                  spacing: 12,
                  children: [
                    _LegendDot(color: Colors.blue, label: 'Boats'),
                    _LegendDot(color: Colors.red, label: 'RC'),
                    _LegendDot(color: Colors.orange, label: 'Marks'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Quick links row
        Row(
          children: [
            Expanded(
              child: _QuickLink(
                icon: Icons.leaderboard,
                label: 'Leaderboard',
                color: Colors.amber,
                onTap: () => context.push('/leaderboard'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickLink(
                icon: Icons.history,
                label: 'Past Races',
                color: Colors.purple,
                onTap: () => context.push('/leaderboard'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Weather mini
        const _WeatherMini(),
        const SizedBox(height: 12),

        // Checked-in boats
        const _CheckedInBoatsMini(),
      ],
    );
  }
}

class _RaceStatusCard extends StatelessWidget {
  const _RaceStatusCard();

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.sailing, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  const Text('No race today',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final d = docs.first.data() as Map<String, dynamic>;
        final name = d['name'] as String? ?? 'Race Day';
        final status = d['status'] as String? ?? 'setup';
        final courseId = d['courseId'] as String? ?? '';

        final (statusLabel, statusColor) = switch (status) {
          'setup' => ('Setting Up', Colors.orange),
          'racing' => ('RACING', Colors.green),
          'complete' => ('Complete', Colors.blue),
          _ => ('—', Colors.grey),
        };

        return Card(
          color: statusColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sailing, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(statusLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (courseId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Course: $courseId',
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Live race map showing GPS tracks from race_tracks collection.
class _LiveRaceMap extends StatelessWidget {
  const _LiveRaceMap({required this.mapController});
  final MapController mapController;

  static const _mpycCenter = LatLng(36.6022, -121.8899);

  // Boat-specific colors for track lines
  static const _boatColors = [
    Colors.blue,
    Colors.teal,
    Colors.indigo,
    Colors.cyan,
    Colors.lightBlue,
    Colors.blueAccent,
    Colors.deepPurple,
    Colors.green,
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_tracks')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .orderBy('date', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        // Build polylines and markers from tracks
        final polylines = <Polyline>[];
        final markers = <Marker>[];

        for (var i = 0; i < docs.length; i++) {
          final d = docs[i].data() as Map<String, dynamic>;
          final points = d['points'] as List<dynamic>? ?? [];
          final boatName = d['boatName'] as String? ?? 'Boat ${i + 1}';
          final sailNumber = d['sailNumber'] as String? ?? '';
          final color = _boatColors[i % _boatColors.length];

          if (points.isEmpty) continue;

          final latLngs = <LatLng>[];
          for (final p in points) {
            if (p is Map<String, dynamic>) {
              final lat = (p['lat'] as num?)?.toDouble();
              final lon = (p['lon'] as num?)?.toDouble();
              if (lat != null && lon != null) {
                latLngs.add(LatLng(lat, lon));
              }
            }
          }

          if (latLngs.isEmpty) continue;

          polylines.add(Polyline(
            points: latLngs,
            color: color,
            strokeWidth: 3,
          ));

          // Latest position marker
          markers.add(Marker(
            point: latLngs.last,
            width: 60,
            height: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                sailNumber.isNotEmpty ? sailNumber : boatName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ));
        }

        // Add course marks from Firestore
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('marks').snapshots(),
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
                          color: Colors.orange, size: 22),
                      Text(name,
                          style: const TextStyle(
                              fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ));
              }
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
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            );
          },
        );
      },
    );
  }
}

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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows today's checked-in boats count
class _CheckedInBoatsMini extends StatelessWidget {
  const _CheckedInBoatsMini();

  @override
  Widget build(BuildContext context) {
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
      builder: (context, eventSnap) {
        final eventDocs = eventSnap.data?.docs ?? [];
        if (eventDocs.isEmpty) return const SizedBox.shrink();

        final eventId = eventDocs.first.id;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('boat_checkins')
              .where('eventId', isEqualTo: eventId)
              .snapshots(),
          builder: (context, snap) {
            final count = snap.data?.docs.length ?? 0;
            if (count == 0) return const SizedBox.shrink();

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.sailing, color: Colors.teal),
                    const SizedBox(width: 10),
                    Text('$count boats checked in',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    Text('Racing today',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WeatherMini extends StatelessWidget {
  const _WeatherMini();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('weather')
          .doc('mpyc_station')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }
        final d = snap.data!.data() as Map<String, dynamic>? ?? {};
        final wind = (d['speedKts'] as num?)?.toDouble() ?? 0;
        final dir = (d['dirDeg'] as num?)?.toInt() ?? 0;
        final temp = (d['tempF'] as num?)?.toDouble();

        return Card(
          color: Colors.blue.shade50,
          child: InkWell(
            onTap: () => context.push('/live-wind'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.air, color: Colors.blue, size: 24),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${wind.toStringAsFixed(0)} kts from $dir°',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (temp != null)
                        Text('${temp.toStringAsFixed(0)}°F',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
