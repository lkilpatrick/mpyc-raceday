import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../auth/data/auth_providers.dart';
import '../../data/models/race_track.dart';

class RaceModeScreen extends ConsumerStatefulWidget {
  const RaceModeScreen({super.key, this.embedded = false});

  /// When true, omits the Scaffold/AppBar (used inside MobileShell tabs).
  final bool embedded;

  @override
  ConsumerState<RaceModeScreen> createState() => _RaceModeScreenState();
}

class _RaceModeScreenState extends ConsumerState<RaceModeScreen> {
  // State
  _RaceState _state = _RaceState.idle;
  DateTime? _startTime;
  DateTime? _finishTime;
  final List<TrackPoint> _trackPoints = [];
  StreamSubscription<Position>? _positionSub;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  bool _uploading = false;

  // Race metadata
  String _eventId = '';
  String _eventName = '';
  String _courseId = '';

  // Stats
  double _currentSpeedKnots = 0;
  double _maxSpeedKnots = 0;
  double _totalDistanceNm = 0;

  @override
  void initState() {
    super.initState();
    _loadTodaysEvent();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _elapsedTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
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
          _courseId = d['courseId'] as String? ?? '';
        });
      }
    } catch (_) {}
  }

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
      }
      return false;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required for race tracking')),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _startRace() async {
    if (!await _ensureLocationPermission()) return;

    HapticFeedback.heavyImpact();
    WakelockPlus.enable();

    setState(() {
      _state = _RaceState.racing;
      _startTime = DateTime.now();
      _trackPoints.clear();
      _totalDistanceNm = 0;
      _maxSpeedKnots = 0;
      _elapsed = Duration.zero;
    });

    // Start elapsed timer
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _startTime != null) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime!);
        });
      }
    });

    // Start GPS stream — high accuracy, every ~3 seconds
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // meters
      ),
    ).listen(_onPosition);
  }

  void _onPosition(Position pos) {
    final speedKnots = pos.speed * 1.94384; // m/s to knots
    final point = TrackPoint(
      lat: pos.latitude,
      lon: pos.longitude,
      timestamp: DateTime.now(),
      speedKnots: speedKnots,
      heading: pos.heading,
      accuracy: pos.accuracy,
    );

    // Calculate distance from last point
    if (_trackPoints.isNotEmpty) {
      final last = _trackPoints.last;
      final distMeters = Geolocator.distanceBetween(
        last.lat, last.lon, pos.latitude, pos.longitude,
      );
      _totalDistanceNm += distMeters / 1852.0; // meters to nautical miles
    }

    setState(() {
      _trackPoints.add(point);
      _currentSpeedKnots = speedKnots;
      if (speedKnots > _maxSpeedKnots) _maxSpeedKnots = speedKnots;
    });

    // Write live position to Firestore for spectator map (throttled)
    _writeLivePosition(pos, speedKnots);
  }

  DateTime? _lastLiveWrite;

  void _writeLivePosition(Position pos, double speedKnots) {
    final now = DateTime.now();
    // Throttle to once every 10 seconds
    if (_lastLiveWrite != null &&
        now.difference(_lastLiveWrite!).inSeconds < 10) return;
    _lastLiveWrite = now;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty || _eventId.isEmpty) return;

    final member = ref.read(currentUserProvider).value;

    FirebaseFirestore.instance
        .collection('live_positions')
        .doc(uid)
        .set({
      'lat': pos.latitude,
      'lon': pos.longitude,
      'speedKnots': speedKnots,
      'heading': pos.heading,
      'accuracy': pos.accuracy,
      'eventId': _eventId,
      'memberId': uid,
      'boatName': member?.boatName ?? '',
      'sailNumber': member?.sailNumber ?? '',
      'source': 'skipper',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _finishRace() async {
    HapticFeedback.heavyImpact();

    // Confirm finish
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finish Race?'),
        content: Text(
          'Elapsed: ${_formatDuration(_elapsed)}\n'
          'Distance: ${_totalDistanceNm.toStringAsFixed(2)} NM\n'
          'Points recorded: ${_trackPoints.length}',
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

    _positionSub?.cancel();
    _elapsedTimer?.cancel();
    WakelockPlus.disable();

    // Remove live position
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('live_positions')
          .doc(uid)
          .delete()
          .catchError((_) {});
    }

    setState(() {
      _state = _RaceState.finished;
      _finishTime = DateTime.now();
    });
  }

  Future<void> _uploadTrack() async {
    if (_trackPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No GPS data to upload')),
      );
      return;
    }

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
        eventId: _eventId,
        eventName: _eventName,
        courseId: _courseId,
        date: _startTime ?? DateTime.now(),
        startTime: _startTime!,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Track uploaded! ${_trackPoints.length} points, '
              '${_totalDistanceNm.toStringAsFixed(2)} NM',
            ),
          ),
        );
        setState(() => _state = _RaceState.uploaded);
      }
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

  void _resetRace() {
    setState(() {
      _state = _RaceState.idle;
      _startTime = null;
      _finishTime = null;
      _trackPoints.clear();
      _totalDistanceNm = 0;
      _maxSpeedKnots = 0;
      _currentSpeedKnots = 0;
      _elapsed = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  Widget _buildBody(bool isRacing) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Event info
          if (_eventName.isNotEmpty)
            Card(
              color: isRacing ? Colors.white.withValues(alpha: 0.1) : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.sailing,
                        color: isRacing ? Colors.white70 : Colors.indigo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_eventName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isRacing ? Colors.white : null,
                              )),
                          if (_courseId.isNotEmpty)
                            Text('Course: $_courseId',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isRacing
                                      ? Colors.white60
                                      : Colors.grey,
                                )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Timer display
          if (_state != _RaceState.idle) ...[
            Text(
              _formatDuration(_elapsed),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: isRacing ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 8),
            if (_startTime != null)
              Text(
                'Started ${DateFormat.jm().format(_startTime!)}',
                style: TextStyle(
                  fontSize: 13,
                  color: isRacing ? Colors.white60 : Colors.grey,
                ),
              ),
            if (_finishTime != null)
              Text(
                'Finished ${DateFormat.jm().format(_finishTime!)}',
                style: const TextStyle(fontSize: 13, color: Colors.green),
              ),
          ],

          const SizedBox(height: 24),

          // Stats grid
          if (_state != _RaceState.idle)
            Row(
              children: [
                _StatTile(
                  label: 'Speed',
                  value: '${_currentSpeedKnots.toStringAsFixed(1)}',
                  unit: 'kts',
                  isRacing: isRacing,
                ),
                const SizedBox(width: 8),
                _StatTile(
                  label: 'Max',
                  value: '${_maxSpeedKnots.toStringAsFixed(1)}',
                  unit: 'kts',
                  isRacing: isRacing,
                ),
                const SizedBox(width: 8),
                _StatTile(
                  label: 'Distance',
                  value: _totalDistanceNm.toStringAsFixed(2),
                  unit: 'NM',
                  isRacing: isRacing,
                ),
                const SizedBox(width: 8),
                _StatTile(
                  label: 'Points',
                  value: '${_trackPoints.length}',
                  unit: '',
                  isRacing: isRacing,
                ),
              ],
            ),

          const Spacer(),

          // Action buttons
          if (_state == _RaceState.idle) ...[
            SizedBox(
              width: double.infinity,
              height: 80,
              child: FilledButton.icon(
                onPressed: _startRace,
                icon: const Icon(Icons.play_arrow, size: 32),
                label: const Text('Start GPS Tracking',
                    style: TextStyle(fontSize: 20)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'GPS tracking will begin when you start',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],

          if (_state == _RaceState.racing) ...[
            // GPS indicator
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
                      ? 'GPS tracking active — ${_trackPoints.length} points'
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 80,
              child: FilledButton.icon(
                onPressed: _finishRace,
                icon: const Icon(Icons.stop, size: 32),
                label: const Text('STOP TRACKING',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],

          if (_state == _RaceState.finished) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _uploading ? null : _uploadTrack,
                icon: _uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload),
                label: Text(_uploading ? 'Uploading...' : 'Upload Track'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _resetRace,
              child: const Text('Discard & Start Over'),
            ),
          ],

          if (_state == _RaceState.uploaded) ...[
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 8),
            const Text('Track uploaded successfully!',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _resetRace,
              child: const Text('New Race'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                if (widget.embedded) {
                  _resetRace();
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Done'),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRacing = _state == _RaceState.racing;
    final bgColor = isRacing ? const Color(0xFF0D1B2A) : null;
    final body = _buildBody(isRacing);

    if (widget.embedded) {
      return Container(color: bgColor, child: SafeArea(child: body));
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Race Mode'),
        backgroundColor: isRacing ? const Color(0xFF0D1B2A) : null,
        foregroundColor: isRacing ? Colors.white : null,
      ),
      body: body,
    );
  }
}

enum _RaceState { idle, racing, finished, uploaded }

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.isRacing,
  });

  final String label;
  final String value;
  final String unit;
  final bool isRacing;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isRacing ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: isRacing ? Colors.white60 : Colors.grey,
                )),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isRacing ? Colors.white : null,
                )),
            if (unit.isNotEmpty)
              Text(unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: isRacing ? Colors.white60 : Colors.grey,
                  )),
          ],
        ),
      ),
    );
  }
}
