import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/models/race_track.dart';

/// Race Replay Viewer — plays back GPS tracks from a completed race.
/// Works on both mobile and web. Shows all boats' tracks with a time
/// scrubber to replay the race.
class RaceReplayViewer extends StatefulWidget {
  const RaceReplayViewer({
    super.key,
    required this.eventId,
    this.eventName = 'Race Replay',
    this.embedded = false,
    this.delayDuration,
  });

  final String eventId;
  final String eventName;
  final bool embedded;
  /// If set, shows a delayed live view instead of a replay.
  final Duration? delayDuration;

  @override
  State<RaceReplayViewer> createState() => _RaceReplayViewerState();
}

class _RaceReplayViewerState extends State<RaceReplayViewer> {
  final _mapController = MapController();
  final _fs = FirebaseFirestore.instance;

  // All boat tracks
  final List<_ReplayBoat> _boats = [];
  bool _loading = true;
  String? _error;

  // Replay state
  DateTime? _raceStart;
  Duration _totalDuration = Duration.zero;
  double _playbackPosition = 0; // 0.0 to 1.0
  bool _playing = false;
  Timer? _playTimer;
  double _playbackSpeed = 1.0;

  // Delayed live mode
  Timer? _delayedPollTimer;

  static const _defaultCenter = LatLng(36.6022, -121.8899);

  static const _boatColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.delayDuration != null) {
      _startDelayedLiveMode();
    } else {
      _loadTracks();
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _delayedPollTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ── Replay Mode ──

  Future<void> _loadTracks() async {
    try {
      // Load from race_tracks collection (uploaded full tracks)
      final tracksSnap = await _fs
          .collection('race_tracks')
          .where('eventId', isEqualTo: widget.eventId)
          .get();

      if (tracksSnap.docs.isNotEmpty) {
        _loadFromRaceTracks(tracksSnap.docs);
        return;
      }

      // Fallback: load from live_tracks (real-time streamed data)
      final boatsSnap = await _fs
          .collection('live_tracks')
          .doc(widget.eventId)
          .collection('boats')
          .get();

      if (boatsSnap.docs.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No track data found for this race';
        });
        return;
      }

      await _loadFromLiveTracks(boatsSnap.docs);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Error loading tracks: $e';
        });
      }
    }
  }

  void _loadFromRaceTracks(List<QueryDocumentSnapshot> docs) {
    DateTime? earliest;
    DateTime? latest;

    for (var i = 0; i < docs.length; i++) {
      final data = docs[i].data() as Map<String, dynamic>;
      final track = RaceTrack.fromDoc(docs[i].id, data);
      if (track.points.isEmpty) continue;

      final boat = _ReplayBoat(
        key: track.memberId,
        sailNumber: track.sailNumber ?? '',
        boatName: track.boatName ?? '',
        color: _boatColors[i % _boatColors.length],
        points: track.points,
      );
      _boats.add(boat);

      final first = track.points.first.timestamp;
      final last = track.points.last.timestamp;
      if (earliest == null || first.isBefore(earliest)) earliest = first;
      if (latest == null || last.isAfter(latest)) latest = last;
    }

    _finalizeLoad(earliest, latest);
  }

  Future<void> _loadFromLiveTracks(List<QueryDocumentSnapshot> boatDocs) async {
    DateTime? earliest;
    DateTime? latest;

    for (var i = 0; i < boatDocs.length; i++) {
      final boatData = boatDocs[i].data() as Map<String, dynamic>;
      final pointsSnap = await _fs
          .collection('live_tracks')
          .doc(widget.eventId)
          .collection('boats')
          .doc(boatDocs[i].id)
          .collection('points')
          .orderBy('timestamp')
          .get();

      final points = pointsSnap.docs
          .map((d) => TrackPoint.fromMap(d.data()))
          .toList();

      if (points.isEmpty) continue;

      _boats.add(_ReplayBoat(
        key: boatDocs[i].id,
        sailNumber: boatData['sailNumber'] as String? ?? '',
        boatName: boatData['boatName'] as String? ?? '',
        color: _boatColors[i % _boatColors.length],
        points: points,
      ));

      final first = points.first.timestamp;
      final last = points.last.timestamp;
      if (earliest == null || first.isBefore(earliest)) earliest = first;
      if (latest == null || last.isAfter(latest)) latest = last;
    }

    _finalizeLoad(earliest, latest);
  }

  void _finalizeLoad(DateTime? earliest, DateTime? latest) {
    if (!mounted) return;
    if (_boats.isEmpty || earliest == null) {
      setState(() {
        _loading = false;
        _error = 'No track data found';
      });
      return;
    }

    setState(() {
      _raceStart = earliest;
      _totalDuration = latest!.difference(earliest);
      _loading = false;
    });
  }

  void _togglePlayback() {
    if (_playing) {
      _playTimer?.cancel();
      setState(() => _playing = false);
    } else {
      if (_playbackPosition >= 1.0) {
        setState(() => _playbackPosition = 0);
      }
      setState(() => _playing = true);
      _playTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (!mounted) return;
        final increment = (0.05 * _playbackSpeed) / _totalDuration.inSeconds;
        setState(() {
          _playbackPosition += increment;
          if (_playbackPosition >= 1.0) {
            _playbackPosition = 1.0;
            _playing = false;
            _playTimer?.cancel();
          }
        });
      });
    }
  }

  // ── Delayed Live Mode ──

  void _startDelayedLiveMode() {
    setState(() => _loading = false);
    _delayedPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollDelayedTracks(),
    );
    _pollDelayedTracks();
  }

  Future<void> _pollDelayedTracks() async {
    if (!mounted) return;
    final cutoff = DateTime.now().subtract(widget.delayDuration!);

    try {
      final boatsSnap = await _fs
          .collection('live_tracks')
          .doc(widget.eventId)
          .collection('boats')
          .get();

      final newBoats = <_ReplayBoat>[];
      for (var i = 0; i < boatsSnap.docs.length; i++) {
        final boatDoc = boatsSnap.docs[i];
        final boatData = boatDoc.data();
        final pointsSnap = await _fs
            .collection('live_tracks')
            .doc(widget.eventId)
            .collection('boats')
            .doc(boatDoc.id)
            .collection('points')
            .where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(cutoff))
            .orderBy('timestamp')
            .limitToLast(500)
            .get();

        final points = pointsSnap.docs
            .map((d) => TrackPoint.fromMap(d.data()))
            .toList();

        newBoats.add(_ReplayBoat(
          key: boatDoc.id,
          sailNumber: boatData['sailNumber'] as String? ?? '',
          boatName: boatData['boatName'] as String? ?? '',
          color: _boatColors[i % _boatColors.length],
          points: points,
        ));
      }

      if (mounted) {
        setState(() {
          _boats.clear();
          _boats.addAll(newBoats);
        });
      }
    } catch (_) {}
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final isDelayed = widget.delayDuration != null;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    } else {
      body = Column(
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDelayed ? Colors.red.shade50 : Colors.indigo.shade50,
            child: Row(
              children: [
                Icon(
                  isDelayed ? Icons.live_tv : Icons.replay,
                  size: 18,
                  color: isDelayed ? Colors.red : Colors.indigo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDelayed
                        ? 'DELAYED LIVE — ${widget.delayDuration!.inMinutes}min delay'
                        : widget.eventName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDelayed ? Colors.red : Colors.indigo,
                    ),
                  ),
                ),
                // Boat count
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_boats.length} boat${_boats.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Map
          Expanded(child: _buildMap(isDelayed)),
          // Playback controls (replay mode only)
          if (!isDelayed) _buildPlaybackControls(),
          // Legend
          _buildLegend(),
        ],
      );
    }

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDelayed ? 'Delayed Live View' : 'Race Replay'),
      ),
      body: body,
    );
  }

  Widget _buildMap(bool isDelayed) {
    final polylines = <Polyline>[];
    final markers = <Marker>[];

    for (final boat in _boats) {
      List<TrackPoint> visiblePoints;

      if (isDelayed) {
        visiblePoints = boat.points;
      } else if (_raceStart != null && _totalDuration.inSeconds > 0) {
        final currentTime = _raceStart!.add(Duration(
          milliseconds:
              (_totalDuration.inMilliseconds * _playbackPosition).round(),
        ));
        visiblePoints = boat.points
            .where((p) => !p.timestamp.isAfter(currentTime))
            .toList();
      } else {
        visiblePoints = boat.points;
      }

      if (visiblePoints.length >= 2) {
        polylines.add(Polyline(
          points: visiblePoints
              .map((p) => LatLng(p.lat, p.lon))
              .toList(),
          color: boat.color.withValues(alpha: 0.7),
          strokeWidth: 3.0,
        ));
      }

      // Current position marker
      if (visiblePoints.isNotEmpty) {
        final last = visiblePoints.last;
        final label =
            boat.sailNumber.isNotEmpty ? boat.sailNumber : boat.boatName;
        markers.add(Marker(
          point: LatLng(last.lat, last.lon),
          width: 80,
          height: 44,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: boat.color,
                  borderRadius: BorderRadius.circular(8),
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
              Text(
                '${(last.speedKnots ?? 0).toStringAsFixed(1)} kn',
                style: const TextStyle(
                    fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ));
      }
    }

    // Determine center from data
    LatLng center = _defaultCenter;
    if (_boats.isNotEmpty && _boats.first.points.isNotEmpty) {
      final p = _boats.first.points.first;
      center = LatLng(p.lat, p.lon);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    final currentTime = _raceStart?.add(Duration(
      milliseconds:
          (_totalDuration.inMilliseconds * _playbackPosition).round(),
    ));
    final elapsed = currentTime != null
        ? currentTime.difference(_raceStart!)
        : Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Time scrubber
          Row(
            children: [
              Text(_formatDuration(elapsed),
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: _playbackPosition,
                  onChanged: (v) {
                    setState(() => _playbackPosition = v);
                  },
                ),
              ),
              Text(_formatDuration(_totalDuration),
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey)),
            ],
          ),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () => setState(() => _playbackPosition = 0),
              ),
              IconButton(
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow,
                    size: 32),
                onPressed: _togglePlayback,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () => setState(() => _playbackPosition = 1.0),
              ),
              const SizedBox(width: 16),
              // Speed selector
              SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 1.0, label: Text('1x')),
                  ButtonSegment(value: 5.0, label: Text('5x')),
                  ButtonSegment(value: 10.0, label: Text('10x')),
                  ButtonSegment(value: 30.0, label: Text('30x')),
                ],
                selected: {_playbackSpeed},
                onSelectionChanged: (v) =>
                    setState(() => _playbackSpeed = v.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(
                      const TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    if (_boats.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: _boats.map((b) {
          final label =
              b.sailNumber.isNotEmpty ? b.sailNumber : b.boatName;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 3,
                color: b.color,
              ),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _ReplayBoat {
  const _ReplayBoat({
    required this.key,
    required this.sailNumber,
    required this.boatName,
    required this.color,
    required this.points,
  });

  final String key;
  final String sailNumber;
  final String boatName;
  final Color color;
  final List<TrackPoint> points;
}
