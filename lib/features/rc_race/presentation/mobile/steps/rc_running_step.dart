import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/race_session.dart';
import '../../rc_race_providers.dart';

/// Step 4: Race running — live map with checked-in boat positions.
class RcRunningStep extends ConsumerStatefulWidget {
  const RcRunningStep({super.key, required this.session});

  final RaceSession session;

  @override
  ConsumerState<RcRunningStep> createState() => _RcRunningStepState();
}

class _RcRunningStepState extends ConsumerState<RcRunningStep> {
  final _mapController = MapController();

  // MPYC harbor center
  static const _mpycCenter = LatLng(36.6002, -121.8947);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Race clock
        if (widget.session.startTime != null)
          _RaceClock(startTime: widget.session.startTime!),

        // Live map
        Expanded(
          child: Stack(
            children: [
              _buildLiveMap(),
              // Boat count overlay
              Positioned(
                top: 8,
                right: 8,
                child: _BoatCountBadge(eventId: widget.session.id),
              ),
            ],
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Abandon button
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmAbandon(context),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Abandon',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Move to scoring
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => _moveToScoring(),
                    icon: const Icon(Icons.sports_score),
                    label: const Text('Begin Scoring',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMap() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('live_positions')
          .where('eventId', isEqualTo: widget.session.id)
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

          if (lat != null && lon != null) {
            markers.add(Marker(
              point: LatLng(lat, lon),
              width: 80,
              height: 44,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sailing,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            sail.isNotEmpty ? sail : boat,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${speed.toStringAsFixed(1)} kn',
                    style: TextStyle(
                      fontSize: 8,
                      color: isStale ? Colors.grey : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ));
          }
        }

        // Add course marks
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

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mpycCenter,
                initialZoom: 13.5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.mpyc.raceday',
                ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAbandon(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Abandon Race?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will end the race and mark it as abandoned. '
                'No further finishes will be recorded.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                  dialogContext, controller.text.trim()),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('ABANDON RACE'),
            ),
          ],
        );
      },
    );
    if (reason != null) {
      await ref
          .read(rcRaceRepositoryProvider)
          .abandonRace(widget.session.id, reason);
    }
  }

  Future<void> _moveToScoring() async {
    await ref
        .read(rcRaceRepositoryProvider)
        .moveToScoring(widget.session.id);
  }
}

class _RaceClock extends StatelessWidget {
  const _RaceClock({required this.startTime});

  final DateTime startTime;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final elapsed = DateTime.now().difference(startTime);
        final m = elapsed.inMinutes;
        final s = elapsed.inSeconds % 60;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.black,
          child: Text(
            '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }
}

class _BoatCountBadge extends StatelessWidget {
  const _BoatCountBadge({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('live_positions')
          .where('eventId', isEqualTo: eventId)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sailing, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text('$count live',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}
