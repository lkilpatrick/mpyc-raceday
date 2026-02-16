import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../race_mode/data/gps_track_service.dart';
import '../race_mode/data/models/race_track.dart';

/// Generates and streams mock GPS data for the 6 demo boats
/// when a demo race starts. Simulates boats sailing a triangular
/// course with realistic speed variations and headings.
class DemoGpsService {
  DemoGpsService({GpsTrackService? trackService})
      : _trackService = trackService ?? GpsTrackService();

  final GpsTrackService _trackService;
  Timer? _streamTimer;
  bool _running = false;

  /// The 6 checked-in demo boats (first 6 from DemoModeService._sampleBoats)
  static const _demoBoats = [
    _DemoBoat('101', 'Salty Dog', 'DEMO_101'),
    _DemoBoat('107', 'Sea Breeze', 'DEMO_107'),
    _DemoBoat('112', 'Windward', 'DEMO_112'),
    _DemoBoat('22', 'Tequila Sunrise', 'DEMO_22'),
    _DemoBoat('44', 'Margarita', 'DEMO_44'),
    _DemoBoat('747', 'Fast Forward', 'DEMO_747'),
  ];

  /// Course waypoints — a triangular course near a typical yacht club.
  /// Using coordinates near Monterey Peninsula YC area.
  /// Start/Finish → Windward Mark → Leeward Mark → Finish
  static const _baseLat = 36.6002;
  static const _baseLon = -121.8947;

  /// Each boat gets a slightly different path with speed variation.
  final _rand = Random();

  /// Boat simulation states
  final Map<String, _BoatSimState> _states = {};

  /// Start streaming mock GPS for all 6 demo boats.
  void startStreaming(String eventId) {
    if (_running) return;
    _running = true;

    // Initialize boat states with staggered positions
    for (var i = 0; i < _demoBoats.length; i++) {
      final boat = _demoBoats[i];
      _states[boat.boatKey] = _BoatSimState(
        lat: _baseLat + (i * 0.0002) + (_rand.nextDouble() * 0.0001),
        lon: _baseLon + (i * 0.0003) + (_rand.nextDouble() * 0.0001),
        heading: 45.0 + (i * 5.0), // Slightly different initial headings
        speedKnots: 4.0 + _rand.nextDouble() * 2.0,
        waypointIndex: 0,
      );
    }

    // Write initial positions to live_positions for the map markers
    _writeAllLivePositions(eventId);

    // Stream updates every 3 seconds
    _streamTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _advanceAllBoats(eventId);
    });
  }

  /// Stop streaming.
  void stopStreaming() {
    _running = false;
    _streamTimer?.cancel();
    _streamTimer = null;
    _states.clear();
  }

  bool get isRunning => _running;

  /// Course waypoints relative to base position.
  /// Triangular course: Start → Upwind → Reach → Downwind → Finish
  static const _waypoints = [
    [0.008, 0.002],    // Windward mark (north)
    [0.003, -0.008],   // Offset mark (west)
    [-0.002, 0.001],   // Leeward mark (south)
    [0.0, 0.0],        // Back to start/finish
  ];

  void _advanceAllBoats(String eventId) {
    if (!_running) return;

    for (final boat in _demoBoats) {
      final state = _states[boat.boatKey];
      if (state == null) continue;

      // Target waypoint
      final wp = _waypoints[state.waypointIndex % _waypoints.length];
      final targetLat = _baseLat + wp[0];
      final targetLon = _baseLon + wp[1];

      // Calculate bearing to target
      final dLat = targetLat - state.lat;
      final dLon = targetLon - state.lon;
      final targetHeading = (atan2(dLon, dLat) * 180 / pi) % 360;

      // Smooth heading change (simulate realistic turning)
      var headingDiff = targetHeading - state.heading;
      if (headingDiff > 180) headingDiff -= 360;
      if (headingDiff < -180) headingDiff += 360;
      state.heading += headingDiff.clamp(-15, 15); // Max 15° turn per tick
      state.heading = state.heading % 360;

      // Speed variation — faster boats, gusts, lulls
      final baseSpeed = 4.0 + (_demoBoats.indexOf(boat) * 0.3);
      final gust = (_rand.nextDouble() - 0.3) * 1.5;
      state.speedKnots = (baseSpeed + gust).clamp(2.0, 8.0);

      // Add some random lateral drift for realism
      final drift = (_rand.nextDouble() - 0.5) * 0.0001;

      // Advance position based on speed and heading
      // ~1 knot = 0.00028 degrees lat per 3 seconds
      final speedFactor = state.speedKnots * 0.00009; // per 3-second tick
      final headingRad = state.heading * pi / 180;
      state.lat += cos(headingRad) * speedFactor + drift;
      state.lon += sin(headingRad) * speedFactor + drift;

      // Check if close to waypoint — advance to next
      final distToWp = sqrt(pow(state.lat - targetLat, 2) +
          pow(state.lon - targetLon, 2));
      if (distToWp < 0.001) {
        state.waypointIndex++;
      }

      // Write track point
      final point = TrackPoint(
        lat: state.lat,
        lon: state.lon,
        timestamp: DateTime.now(),
        speedKnots: state.speedKnots,
        heading: state.heading,
        accuracy: 3.0 + _rand.nextDouble() * 2.0,
      );

      _trackService.writeTrackPoint(
        eventId: eventId,
        boatKey: boat.boatKey,
        point: point,
        sailNumber: boat.sailNumber,
        boatName: boat.boatName,
      );
    }

    // Also update live_positions for the map markers
    _writeAllLivePositions(eventId);
  }

  void _writeAllLivePositions(String eventId) {
    final fs = FirebaseFirestore.instance;
    for (final boat in _demoBoats) {
      final state = _states[boat.boatKey];
      if (state == null) continue;

      fs.collection('live_positions').doc(boat.boatKey).set({
        'lat': state.lat,
        'lon': state.lon,
        'speedKnots': state.speedKnots,
        'heading': state.heading,
        'accuracy': 5.0,
        'eventId': eventId,
        'memberId': boat.boatKey,
        'boatName': boat.boatName,
        'sailNumber': boat.sailNumber,
        'source': 'demo',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Clean up live positions for demo boats.
  Future<void> cleanupLivePositions() async {
    final fs = FirebaseFirestore.instance;
    for (final boat in _demoBoats) {
      await fs.collection('live_positions').doc(boat.boatKey).delete();
    }
  }
}

class _DemoBoat {
  const _DemoBoat(this.sailNumber, this.boatName, this.boatKey);
  final String sailNumber;
  final String boatName;
  final String boatKey;
}

class _BoatSimState {
  _BoatSimState({
    required this.lat,
    required this.lon,
    required this.heading,
    required this.speedKnots,
    required this.waypointIndex,
  });

  double lat;
  double lon;
  double heading;
  double speedKnots;
  int waypointIndex;
}
