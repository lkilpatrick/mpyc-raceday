import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app_mode/data/app_mode.dart';
import '../../../auth/data/auth_providers.dart';
import '../../../auth/data/models/member.dart';
import '../../../boat_checkin/presentation/boat_checkin_providers.dart';
import '../../../maintenance/presentation/maintenance_providers.dart';
import '../../../courses/data/models/fleet_broadcast.dart';
import '../../../crew_assignment/presentation/crew_assignment_providers.dart';
import '../../../crew_assignment/presentation/crew_assignment_formatters.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load persisted app mode from Firestore on first build
    loadAppMode(ref);

    final memberAsync = ref.watch(currentUserProvider);
    final member = memberAsync.value;
    final isRCChair = member?.isRCChair ?? false;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentUserProvider);
        ref.invalidate(criticalMaintenanceCountProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ── Weather ──
          const _WeatherCard(),
          const SizedBox(height: 8),

          // ── Your Boat ──
          if (member != null) ...[
            _YourBoatCard(member: member),
            const SizedBox(height: 8),
          ],

          // ── Race Mode ──
          const _RaceModeCard(),
          const SizedBox(height: 8),

          // ── Today's Race ──
          const _TodaysRaceCard(),
          const SizedBox(height: 8),

          // ── Fleet Broadcasts ──
          const _BroadcastHistoryCard(),
          const SizedBox(height: 8),

          // ── Race Control (RC Chair only) ──
          if (isRCChair) ...[
            const _RaceControlCard(),
            const SizedBox(height: 8),
          ],

          // ── Upcoming Races ──
          const _UpcomingRacesCard(),
          const SizedBox(height: 8),

          // ── Recent Results ──
          const _RecentResultsCard(),
          const SizedBox(height: 8),

          // ── Maintenance alerts ──
          const _MaintenanceAlertCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Today's Race hero card
// ═══════════════════════════════════════════════════════

class _TodaysRaceCard extends StatelessWidget {
  const _TodaysRaceCard();

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
                  Icon(Icons.sailing,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  const Text('No race today',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final d = docs.first.data() as Map<String, dynamic>;
        final eventId = docs.first.id;
        final name = d['name'] as String? ?? 'Race Day';
        final status = d['status'] as String? ?? 'setup';
        final courseId = d['courseId'] as String? ?? '';

        final (statusLabel, statusColor) = switch (status) {
          'setup' => ('Setup', Colors.orange),
          'racing' => ('Racing', Colors.green),
          'complete' => ('Complete', Colors.blue),
          _ => ('—', Colors.grey),
        };

        return Card(
          color: statusColor.withValues(alpha: 0.08),
          child: InkWell(
            onTap: () => context.push('/schedule/event/$eventId'),
            borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Course
                      _MiniStat(
                        icon: Icons.map,
                        label: courseId.isNotEmpty ? 'Course $courseId' : 'No course',
                      ),
                      const SizedBox(width: 16),
                      // Fleet size
                      _FleetSizeStat(eventId: eventId),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FleetSizeStat extends ConsumerWidget {
  const _FleetSizeStat({required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(checkinCountProvider(eventId));
    return _MiniStat(icon: Icons.directions_boat, label: '$count boats');
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// Weather Card (prominent, always visible)
// ═══════════════════════════════════════════════════════

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  static const _dirs = ['N','NNE','NE','ENE','E','ESE','SE','SSE',
                         'S','SSW','SW','WSW','W','WNW','NW','NNW'];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('weather')
          .doc('mpyc_station')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.grey.shade400, size: 32),
                  const SizedBox(width: 12),
                  const Text('Weather data loading...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }
        final d = snap.data!.data() as Map<String, dynamic>? ?? {};
        final wind = (d['speedKts'] as num?)?.toDouble() ?? 0;
        final gust = (d['gustKts'] as num?)?.toDouble();
        final dir = (d['dirDeg'] as num?)?.toInt() ?? 0;
        final temp = (d['tempF'] as num?)?.toDouble();
        final humidity = (d['humidity'] as num?)?.toInt();
        final pressure = (d['pressureInHg'] as num?)?.toDouble();
        final dirLabel = _dirs[((dir + 11) % 360 ~/ 22.5) % 16];

        return Card(
          color: Colors.blue.shade50,
          child: InkWell(
            onTap: () => context.push('/live-wind'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.air, color: Colors.blue, size: 20),
                      const SizedBox(width: 6),
                      const Text('Current Weather',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Wind direction arrow
                      Transform.rotate(
                        angle: dir * 3.14159 / 180,
                        child: const Icon(Icons.navigation, size: 36, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${wind.toStringAsFixed(0)} kts $dirLabel',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          if (gust != null && gust > 0)
                            Text('Gusts ${gust.toStringAsFixed(0)} kts',
                                style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (temp != null)
                            Text('${temp.toStringAsFixed(0)}°F',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                          if (humidity != null)
                            Text('$humidity% RH',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          if (pressure != null)
                            Text('${pressure.toStringAsFixed(2)} inHg',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Your Boat Card (photo, boat info, skipper/crew)
// ═══════════════════════════════════════════════════════

class _YourBoatCard extends StatefulWidget {
  const _YourBoatCard({required this.member});
  final Member member;

  @override
  State<_YourBoatCard> createState() => _YourBoatCardState();
}

class _YourBoatCardState extends State<_YourBoatCard> {
  String? _boatPhotoUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadBoatPhoto();
  }

  Future<void> _loadBoatPhoto() async {
    final doc = await FirebaseFirestore.instance
        .collection('members')
        .doc(widget.member.id)
        .get();
    if (mounted) {
      setState(() {
        _boatPhotoUrl = doc.data()?['boatPhotoUrl'] as String?;
      });
    }
  }

  Future<void> _uploadBoatPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (xFile == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await xFile.readAsBytes();
      final ref = FirebaseStorage.instance
          .ref('boat_photos/${widget.member.id}.jpg');
      await ref.putData(Uint8List.fromList(bytes),
          SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('members')
          .doc(widget.member.id)
          .update({'boatPhotoUrl': url});

      if (mounted) setState(() => _boatPhotoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final hasBoat = m.boatName != null && m.boatName!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boat photo or placeholder
          InkWell(
            onTap: _uploadBoatPhoto,
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: _uploading
                  ? const Center(child: CircularProgressIndicator())
                  : _boatPhotoUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(_boatPhotoUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _photoPlaceholder()),
                            Positioned(
                              right: 8, bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        )
                      : _photoPlaceholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasBoat) ...[
                  Row(
                    children: [
                      const Icon(Icons.sailing, size: 20, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(m.boatName!,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                      if (m.sailNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(m.sailNumber!,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (m.boatClass != null)
                    Text('${m.boatClass}${m.phrfRating != null ? ' • PHRF ${m.phrfRating}' : ''}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.person, size: 20, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(m.displayName,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(m.displayName,
                    style: const TextStyle(fontSize: 13)),
                if (m.roles.isNotEmpty)
                  Text(
                    m.roles.map((r) => r.name).join(', '),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text('Tap to add boat photo',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Race Control (PRO/Admin during active event)
// ═══════════════════════════════════════════════════════

class _RaceControlCard extends StatelessWidget {
  const _RaceControlCard();

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
        if (docs.isEmpty) return const SizedBox.shrink();

        final eventId = docs.first.id;

        return Card(
          color: Colors.indigo.shade50,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag, color: Colors.indigo),
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
                      icon: Icons.map,
                      label: 'Select Course',
                      onTap: () =>
                          context.push('/courses/select/$eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.timer,
                      label: 'Start Sequence',
                      onTap: () =>
                          context.push('/timing/start/$eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.sports_score,
                      label: 'Record Finishes',
                      onTap: () =>
                          context.push('/timing/$eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.campaign,
                      label: 'Broadcast',
                      onTap: () =>
                          context.push('/courses/broadcast/$eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.how_to_reg,
                      label: 'Check-In',
                      onTap: () =>
                          context.push('/checkin/$eventId'),
                    ),
                    _QuickAction(
                      icon: Icons.report,
                      label: 'Incident',
                      onTap: () =>
                          context.push('/incidents/report/$eventId'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.indigo.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.indigo),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Race Mode Card
// ═══════════════════════════════════════════════════════

class _RaceModeCard extends StatelessWidget {
  const _RaceModeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: InkWell(
        onTap: () => context.push('/race-mode'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.gps_fixed, color: Colors.green.shade800, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Race Mode',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.green.shade900)),
                    Text('Track your race with GPS',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.green.shade700),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Upcoming Races
// ═══════════════════════════════════════════════════════

class _UpcomingRacesCard extends StatelessWidget {
  const _UpcomingRacesCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('date')
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event, color: Colors.teal, size: 20),
                    SizedBox(width: 6),
                    Text('Upcoming Races',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                ...docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = d['name'] as String? ?? '';
                  final ts = d['date'] as Timestamp?;
                  final series = d['series'] as String? ?? '';
                  final dateStr = ts != null
                      ? DateFormat('EEE, MMM d').format(ts.toDate())
                      : '';
                  final daysAway = ts != null
                      ? ts.toDate().difference(DateTime.now()).inDays
                      : 0;

                  return InkWell(
                    onTap: () => context.push('/schedule/event/${doc.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  ts != null ? DateFormat('d').format(ts.toDate()) : '',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade700),
                                ),
                                Text(
                                  ts != null ? DateFormat('MMM').format(ts.toDate()) : '',
                                  style: TextStyle(fontSize: 10, color: Colors.teal.shade700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                                if (series.isNotEmpty)
                                  Text(series,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text(
                            daysAway == 0 ? 'Today' : daysAway == 1 ? 'Tomorrow' : '${daysAway}d',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: daysAway <= 1 ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Maintenance alert badge card
// ═══════════════════════════════════════════════════════

class _MaintenanceAlertCard extends ConsumerWidget {
  const _MaintenanceAlertCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(criticalMaintenanceCountProvider);
    final count = countAsync.value ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Card(
      color: Colors.red.shade50,
      child: InkWell(
        onTap: () => context.push('/maintenance/feed'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count critical maintenance issue${count > 1 ? 's' : ''}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Recent results card
// ═══════════════════════════════════════════════════════

class _RecentResultsCard extends StatelessWidget {
  const _RecentResultsCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .where('date', isLessThan: Timestamp.now())
          .orderBy('date', descending: true)
          .limit(2)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                    SizedBox(width: 6),
                    Text('Recent Results',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                ...docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = d['name'] as String? ?? '';
                  final ts = d['date'] as Timestamp?;
                  final status = d['status'] as String? ?? '';
                  final dateStr = ts != null
                      ? DateFormat('EEE, MMM d').format(ts.toDate())
                      : '';

                  return InkWell(
                    onTap: () => context.push('/schedule/event/${doc.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            status == 'complete' ? Icons.check_circle : Icons.schedule,
                            size: 18,
                            color: status == 'complete' ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(dateStr,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Fleet Broadcast History Card (Skipper view)
// ═══════════════════════════════════════════════════════

class _BroadcastHistoryCard extends StatelessWidget {
  const _BroadcastHistoryCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fleet_broadcasts')
          .orderBy('sentAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final latest = docs.first.data() as Map<String, dynamic>;
        final latestMsg = latest['message'] as String? ?? '';
        final latestType = latest['type'] as String? ?? 'general';
        final latestAt = (latest['sentAt'] as Timestamp?)?.toDate();

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Latest broadcast highlight
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    Icon(_broadcastIcon(latestType),
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Latest Broadcast',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(latestMsg,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (latestAt != null)
                      Text(DateFormat.jm().format(latestAt),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              // Older messages
              if (docs.length > 1)
                ...docs.skip(1).map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final msg = d['message'] as String? ?? '';
                  final type = d['type'] as String? ?? 'general';
                  final at = (d['sentAt'] as Timestamp?)?.toDate();
                  return ListTile(
                    dense: true,
                    leading: Icon(_broadcastIcon(type),
                        size: 16, color: Colors.grey),
                    title: Text(msg,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    trailing: at != null
                        ? Text(DateFormat.jm().format(at),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey))
                        : null,
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  static IconData _broadcastIcon(String type) {
    return switch (type) {
      'courseSelection' => Icons.map,
      'postponement' => Icons.schedule,
      'abandonment' || 'abandonTooMuchWind' || 'abandonTooLittleWind' =>
        Icons.cancel,
      'courseChange' => Icons.swap_horiz,
      'generalRecall' => Icons.replay,
      'shortenedCourse' || 'shortenCourse' => Icons.content_cut,
      'cancellation' => Icons.block,
      'vhfChannelChange' => Icons.radio,
      _ => Icons.campaign,
    };
  }
}
