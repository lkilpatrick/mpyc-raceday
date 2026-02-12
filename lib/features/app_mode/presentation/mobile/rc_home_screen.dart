import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

/// RC-specific home screen — focused on Race Control, Fleet Broadcast, and Live Map.
class RcHomeScreen extends ConsumerStatefulWidget {
  const RcHomeScreen({super.key});

  @override
  ConsumerState<RcHomeScreen> createState() => _RcHomeScreenState();
}

class _RcHomeScreenState extends ConsumerState<RcHomeScreen> {
  String? _eventId;
  String _eventName = '';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _loadTodaysEvent();
  }

  Future<void> _loadTodaysEvent() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    try {
      final snap = await FirebaseFirestore.instance
          .collection('race_events')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        final d = snap.docs.first.data();
        setState(() {
          _eventId = snap.docs.first.id;
          _eventName = d['name'] as String? ?? 'Race Day';
          _status = d['status'] as String? ?? 'setup';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_eventId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No race event today',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    final (statusLabel, statusColor) = switch (_status) {
      'setup' => ('Setup', Colors.orange),
      'checkin_open' => ('Check-In Open', Colors.teal),
      'start_pending' => ('Start Pending', Colors.amber),
      'running' => ('Racing', Colors.green),
      'scoring' => ('Scoring', Colors.blue),
      'review' => ('Review', Colors.purple),
      'finalized' => ('Complete', Colors.indigo),
      'abandoned' => ('Abandoned', Colors.red),
      _ => ('—', Colors.grey),
    };

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Event header
        Card(
          color: statusColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.sailing, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_eventName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(DateFormat.yMMMd().format(DateTime.now()),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
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
          ),
        ),
        const SizedBox(height: 12),

        // Run Race — primary action
        Card(
          color: Colors.indigo.shade50,
          child: InkWell(
            onTap: () => context.push('/rc-race/$_eventId'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.flag,
                        color: Colors.indigo, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Run Race',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.indigo.shade800)),
                        const Text(
                          'Setup → Check-In → Start → Score → Review',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.indigo, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Race Control quick actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag, color: Colors.indigo, size: 20),
                    SizedBox(width: 8),
                    Text('Race Control',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickAction(
                      icon: Icons.how_to_reg,
                      label: 'Check-In',
                      onTap: () => context.push('/checkin/$_eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.timer,
                      label: 'Start Sequence',
                      onTap: () =>
                          context.push('/timing/start/$_eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.sports_score,
                      label: 'Record Finishes',
                      onTap: () => context.push('/timing/$_eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.map,
                      label: 'Select Course',
                      onTap: () =>
                          context.push('/courses/select/$_eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.report,
                      label: 'Incident',
                      onTap: () =>
                          context.push('/incidents/report/$_eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.history,
                      label: 'Race History',
                      onTap: () => context.push('/rc-race-history'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Fleet Broadcast
        Card(
          color: Colors.red.shade50,
          child: InkWell(
            onTap: () => context.push('/courses/broadcast/$_eventId'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.campaign,
                        color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fleet Broadcast',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.red.shade800)),
                        const Text(
                          'Send messages to all racers, skippers, or onshore',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.red),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Live Race Map (expandable to fullscreen)
        _RcLiveMapCard(eventId: _eventId!),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.indigo.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.indigo),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Live Race Map card with fullscreen toggle
// ═══════════════════════════════════════════════════════════════════

class _RcLiveMapCard extends StatelessWidget {
  const _RcLiveMapCard({required this.eventId});
  final String eventId;

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
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                _LiveBoatCount(),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.fullscreen, size: 22),
                  tooltip: 'Fullscreen',
                  onPressed: () => _openFullscreen(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: _buildMap(),
          ),
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
                _LegendDot(color: Colors.grey, label: 'Stale'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const _FullscreenMapPage(),
    ));
  }

  Widget _buildMap() {
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
                        const Icon(Icons.sailing,
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
                  Text('${speed.toStringAsFixed(1)} kn',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color:
                              isStale ? Colors.grey : Colors.black87)),
                ],
              ),
            ));
          }
        }

        // Course marks
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('marks')
              .snapshots(),
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
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ));
              }
            }

            if (liveDocs.isEmpty && markDocs.isEmpty) {
              return Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _mpycCenter,
                      initialZoom: 13.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                        style:
                            TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              );
            }

            return FlutterMap(
              options: MapOptions(
                initialCenter: _mpycCenter,
                initialZoom: 13.5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
          return Text('No boats',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500));
        }
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count live',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
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
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Fullscreen Live Map
// ═══════════════════════════════════════════════════════════════════

class _FullscreenMapPage extends StatelessWidget {
  const _FullscreenMapPage();

  static const _mpycCenter = LatLng(36.6022, -121.8899);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Race Map'),
        actions: [
          _LiveBoatCount(),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            final speed =
                (d['speedKnots'] as num?)?.toDouble() ?? 0;
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
                width: 90,
                height: 50,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isStale
                            ? null
                            : [
                                BoxShadow(
                                  color:
                                      color.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sailing,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    Text('${speed.toStringAsFixed(1)} kn',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isStale
                                ? Colors.grey
                                : Colors.black87)),
                  ],
                ),
              ));
            }
          }

          // Marks
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('marks')
                .snapshots(),
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
                    width: 50,
                    height: 50,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.orange, size: 24),
                        Text(name,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ));
                }
              }

              return FlutterMap(
                options: MapOptions(
                  initialCenter: _mpycCenter,
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  if (markers.isNotEmpty)
                    MarkerLayer(markers: markers),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
