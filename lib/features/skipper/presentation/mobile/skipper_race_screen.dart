import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../auth/data/auth_providers.dart';
import '../../../race_mode/data/models/race_track.dart';
import '../widgets/weather_header.dart';

/// Skipper Race screen — live timer from RC start, GPS tracking,
/// finish zone detection, finish/DNF actions.
class SkipperRaceScreen extends ConsumerStatefulWidget {
  const SkipperRaceScreen({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<SkipperRaceScreen> createState() => _SkipperRaceScreenState();
}

class _SkipperRaceScreenState extends ConsumerState<SkipperRaceScreen> {
  // Tracking state
  StreamSubscription<Position>? _positionSub;
  Timer? _elapsedTimer;
  final List<TrackPoint> _trackPoints = [];
  Duration _elapsed = Duration.zero;
  double _currentSpeedKnots = 0;
  double _maxSpeedKnots = 0;
  double _totalDistanceNm = 0;
  DateTime? _lastLiveWrite;
  bool _trackingActive = false;

  // Race state from Firestore
  DateTime? _raceStartTime;
  String _raceStatus = '';
  bool _finished = false;
  DateTime? _finishTime;
  bool _uploading = false;
  bool _uploaded = false;

  // Finish zone
  bool _inFinishZone = false;
  static const _defaultFinishZoneRadius = 200.0; // meters

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _elapsedTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }

    WakelockPlus.enable();
    setState(() => _trackingActive = true);

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _raceStartTime != null && !_finished) {
        setState(() {
          _elapsed = DateTime.now().difference(_raceStartTime!);
        });
      }
    });
  }

  void _onPosition(Position pos) {
    if (_finished) return;

    final speedKnots = pos.speed * 1.94384;
    final point = TrackPoint(
      lat: pos.latitude,
      lon: pos.longitude,
      timestamp: DateTime.now(),
      speedKnots: speedKnots,
      heading: pos.heading,
      accuracy: pos.accuracy,
    );

    if (_trackPoints.isNotEmpty) {
      final last = _trackPoints.last;
      final distMeters = Geolocator.distanceBetween(
        last.lat, last.lon, pos.latitude, pos.longitude,
      );
      _totalDistanceNm += distMeters / 1852.0;
    }

    setState(() {
      _trackPoints.add(point);
      _currentSpeedKnots = speedKnots;
      if (speedKnots > _maxSpeedKnots) _maxSpeedKnots = speedKnots;
    });

    _writeLivePosition(pos, speedKnots);
    _checkFinishZone(pos.latitude, pos.longitude);
  }

  void _writeLivePosition(Position pos, double speedKnots) {
    final now = DateTime.now();
    final interval = _raceStartTime != null ? 5 : 15;
    if (_lastLiveWrite != null &&
        now.difference(_lastLiveWrite!).inSeconds < interval) {
      return;
    }
    _lastLiveWrite = now;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final member = ref.read(currentUserProvider).value;

    FirebaseFirestore.instance.collection('live_positions').doc(uid).set({
      'lat': pos.latitude,
      'lon': pos.longitude,
      'speedKnots': speedKnots,
      'heading': pos.heading,
      'accuracy': pos.accuracy,
      'eventId': widget.eventId,
      'memberId': uid,
      'boatName': member?.boatName ?? '',
      'sailNumber': member?.sailNumber ?? '',
      'source': 'skipper',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _checkFinishZone(double lat, double lon) {
    // Check against finish zone stored on the race event
    // For now use a simple approach: if race_event has finishLat/finishLon
    // we check proximity. This will be enhanced later.
    // The _inFinishZone flag is also set from the Firestore stream below.
  }

  Future<void> _finishRace() async {
    HapticFeedback.heavyImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finish Race?'),
        content: Text(
          'Elapsed: ${_formatDuration(_elapsed)}\n'
          'Distance: ${_totalDistanceNm.toStringAsFixed(2)} NM\n'
          'Points: ${_trackPoints.length}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Racing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _stopTracking();
    setState(() {
      _finished = true;
      _finishTime = DateTime.now();
    });

    // Update check-in status
    _updateCheckinStatus('finished');
  }

  Future<void> _withdrawDNF() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw / DNF?'),
        content: const Text(
          'This will mark you as Did Not Finish and stop GPS tracking. '
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Withdraw (DNF)'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _stopTracking();
    setState(() {
      _finished = true;
      _finishTime = DateTime.now();
    });
    _updateCheckinStatus('dnf');
  }

  void _stopTracking() {
    _positionSub?.cancel();
    _elapsedTimer?.cancel();
    WakelockPlus.disable();
    setState(() => _trackingActive = false);

    // Remove live position
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('live_positions')
          .doc(uid)
          .delete()
          .catchError((_) {});
    }
  }

  Future<void> _updateCheckinStatus(String status) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('boat_checkins')
          .where('eventId', isEqualTo: widget.eventId)
          .where('memberId', isEqualTo: uid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({
          'status': status,
          'finishedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  Future<void> _uploadTrack() async {
    if (_trackPoints.isEmpty) return;
    setState(() => _uploading = true);

    try {
      final member = ref.read(currentUserProvider).value;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      final avgSpeed = _trackPoints.isNotEmpty
          ? _trackPoints
                  .map((p) => p.speedKnots ?? 0)
                  .reduce((a, b) => a + b) /
              _trackPoints.length
          : 0.0;

      final track = RaceTrack(
        id: '',
        memberId: member?.id ?? uid,
        eventId: widget.eventId,
        eventName: '',
        courseId: '',
        date: _raceStartTime ?? DateTime.now(),
        startTime: _raceStartTime ?? DateTime.now(),
        finishTime: _finishTime,
        points: _trackPoints,
        boatName: member?.boatName,
        sailNumber: member?.sailNumber,
        boatClass: member?.boatClass,
        distanceNm: _totalDistanceNm,
        avgSpeedKnots: avgSpeed,
        maxSpeedKnots: _maxSpeedKnots,
      );

      await FirebaseFirestore.instance
          .collection('race_tracks')
          .add(track.toMap());

      if (mounted) {
        setState(() {
          _uploading = false;
          _uploaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Track uploaded! ${_trackPoints.length} points, '
              '${_totalDistanceNm.toStringAsFixed(2)} NM',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isRacing = !_finished && _raceStartTime != null;
    final bgColor = isRacing ? const Color(0xFF0D1B2A) : null;
    final textColor = isRacing ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Race Mode'),
        backgroundColor: isRacing ? const Color(0xFF0D1B2A) : null,
        foregroundColor: isRacing ? Colors.white : null,
      ),
      body: Column(
        children: [
          const WeatherHeader(),
          // Listen to race event for start time and status changes
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('race_events')
                .doc(widget.eventId)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasData && snap.data!.exists) {
                final d = snap.data!.data() as Map<String, dynamic>;
                final st = (d['startTime'] as Timestamp?)?.toDate();
                final status = d['status'] as String? ?? '';

                // Check for finish zone coordinates
                final finishLat =
                    (d['finishLat'] as num?)?.toDouble();
                final finishLon =
                    (d['finishLon'] as num?)?.toDouble();
                final finishRadius =
                    (d['finishZoneRadius'] as num?)?.toDouble() ??
                        _defaultFinishZoneRadius;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    if (st != null && _raceStartTime != st) {
                      setState(() => _raceStartTime = st);
                    }
                    if (status != _raceStatus) {
                      setState(() => _raceStatus = status);
                      // Auto-stop if race abandoned by RC
                      if (status == 'abandoned' && !_finished) {
                        _stopTracking();
                        setState(() => _finished = true);
                      }
                    }
                    // Update finish zone check
                    if (finishLat != null &&
                        finishLon != null &&
                        _trackPoints.isNotEmpty) {
                      final last = _trackPoints.last;
                      final dist = Geolocator.distanceBetween(
                        last.lat, last.lon, finishLat, finishLon,
                      );
                      final inZone = dist <= finishRadius;
                      if (inZone != _inFinishZone) {
                        setState(() => _inFinishZone = inZone);
                      }
                    }
                  }
                });
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Timer
                  if (_raceStartTime == null && !_finished) ...[
                    const SizedBox(height: 24),
                    Icon(Icons.hourglass_empty,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Waiting for race start...',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text('Timer will start automatically when RC starts the race.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                        textAlign: TextAlign.center),
                  ],

                  if (_raceStartTime != null || _finished) ...[
                    Text(
                      _formatDuration(_elapsed),
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_raceStartTime != null)
                      Text(
                        'Started ${DateFormat.jm().format(_raceStartTime!)}',
                        style: TextStyle(
                            fontSize: 13,
                            color: isRacing
                                ? Colors.white60
                                : Colors.grey),
                      ),
                    if (_finishTime != null)
                      Text(
                        'Finished ${DateFormat.jm().format(_finishTime!)}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.green),
                      ),
                  ],

                  const SizedBox(height: 20),

                  // Stats grid
                  if (_trackPoints.isNotEmpty)
                    Row(
                      children: [
                        _StatTile('Speed',
                            _currentSpeedKnots.toStringAsFixed(1), 'kts',
                            dark: isRacing),
                        const SizedBox(width: 6),
                        _StatTile('Max',
                            _maxSpeedKnots.toStringAsFixed(1), 'kts',
                            dark: isRacing),
                        const SizedBox(width: 6),
                        _StatTile('Dist',
                            _totalDistanceNm.toStringAsFixed(2), 'NM',
                            dark: isRacing),
                        const SizedBox(width: 6),
                        _StatTile(
                            'Pts', '${_trackPoints.length}', '',
                            dark: isRacing),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // Tracking indicator
                  if (_trackingActive)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gps_fixed,
                            size: 14,
                            color: _trackPoints.isNotEmpty
                                ? Colors.green
                                : Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          _trackPoints.isNotEmpty
                              ? 'Transmitting — ${_trackPoints.length} pts'
                              : 'Acquiring GPS...',
                          style: TextStyle(
                            fontSize: 12,
                            color: _trackPoints.isNotEmpty
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),

                  // Finish zone indicator
                  if (_inFinishZone && !_finished) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text('In Finish Zone',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.amber)),
                        ],
                      ),
                    ),
                  ],

                  // Abandoned by RC
                  if (_raceStatus == 'abandoned') ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.red.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Race has been abandoned by RC. '
                                'Tracking stopped.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Action buttons
                  if (!_finished && _raceStartTime != null) ...[
                    // Finish button — prominent when in finish zone
                    SizedBox(
                      width: double.infinity,
                      height: _inFinishZone ? 72 : 56,
                      child: FilledButton.icon(
                        onPressed: _finishRace,
                        icon: Icon(Icons.flag,
                            size: _inFinishZone ? 28 : 22),
                        label: Text(
                          'FINISH RACE',
                          style: TextStyle(
                              fontSize: _inFinishZone ? 22 : 18,
                              fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _inFinishZone
                              ? Colors.green
                              : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // DNF / Withdraw
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _withdrawDNF,
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Withdraw / DNF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],

                  // Post-finish actions
                  if (_finished) ...[
                    if (!_uploaded)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed:
                              _uploading || _trackPoints.isEmpty
                                  ? null
                                  : _uploadTrack,
                          icon: _uploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.cloud_upload),
                          label: Text(_uploading
                              ? 'Uploading...'
                              : 'Upload Track'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (_uploaded) ...[
                      const Icon(Icons.check_circle,
                          size: 40, color: Colors.green),
                      const SizedBox(height: 4),
                      const Text('Track uploaded!',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to Home'),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value, this.unit, {this.dark = false});
  final String label;
  final String value;
  final String unit;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: dark ? Colors.white60 : Colors.grey)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : null)),
            if (unit.isNotEmpty)
              Text(unit,
                  style: TextStyle(
                      fontSize: 10,
                      color: dark ? Colors.white60 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
