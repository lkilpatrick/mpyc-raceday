import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/weather_models.dart';
import 'noaa_weather_service.dart';
import 'openweather_service.dart';

class WeatherPollingService {
  WeatherPollingService({
    required this.noaaService,
    required this.openWeatherService,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final NoaaWeatherService noaaService;
  final OpenWeatherService openWeatherService;
  final FirebaseFirestore _firestore;

  Timer? _pollTimer;
  String? _activeEventId;
  bool get isLogging => _pollTimer != null && _activeEventId != null;
  String? get activeEventId => _activeEventId;

  CollectionReference<Map<String, dynamic>> get _entriesCol =>
      _firestore.collection('weather_entries');

  /// Start polling for an active event. Polls every 5 minutes.
  void startPolling(String eventId) {
    stopPolling();
    _activeEventId = eventId;
    // Immediate first poll
    _poll();
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) => _poll());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _activeEventId = null;
  }

  /// Tag the next entry with a special marker.
  Future<void> logTaggedEntry(WeatherEntryTag tag) async {
    if (_activeEventId == null) return;
    final entry = await _fetchMerged();
    if (entry != null) {
      await _save(entry.copyWith(tag: tag));
    }
  }

  /// Save a manual entry.
  Future<void> saveManualEntry(WeatherEntry entry) async {
    await _save(entry);
  }

  /// Get all entries for an event.
  Stream<List<WeatherEntry>> watchEntries(String eventId) {
    return _entriesCol
        .where('eventId', isEqualTo: eventId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  /// Get all entries across all events for analytics.
  Future<List<WeatherEntry>> getAllEntries() async {
    final snap =
        await _entriesCol.orderBy('timestamp', descending: true).get();
    return snap.docs.map(_fromDoc).toList();
  }

  Future<void> _poll() async {
    if (_activeEventId == null) return;
    final entry = await _fetchMerged();
    if (entry != null) {
      await _save(entry);
    }
  }

  /// Fetch from both sources and merge. Prefer NOAA for marine data.
  Future<WeatherEntry?> _fetchMerged() async {
    final noaa =
        await noaaService.fetchCurrentConditions(eventId: _activeEventId ?? '');
    final ow = await openWeatherService.fetchCurrentWeather(
        eventId: _activeEventId ?? '');

    if (noaa == null && ow == null) return null;

    // Prefer NOAA wind data (marine-grade), fill gaps from OpenWeather
    return WeatherEntry(
      id: '',
      eventId: _activeEventId ?? '',
      timestamp: DateTime.now(),
      source: WeatherSource.merged,
      windSpeedKts: noaa?.windSpeedKts ?? ow?.windSpeedKts ?? 0,
      windGustKts: noaa?.windGustKts ?? ow?.windGustKts,
      windDirectionDeg:
          noaa?.windDirectionDeg ?? ow?.windDirectionDeg ?? 0,
      windDirectionLabel:
          noaa?.windDirectionLabel ?? ow?.windDirectionLabel ?? '',
      temperatureF: noaa?.temperatureF ?? ow?.temperatureF,
      humidity: noaa?.humidity ?? ow?.humidity,
      pressureMb: noaa?.pressureMb ?? ow?.pressureMb,
      visibility: noaa?.visibility ?? ow?.visibility,
      forecastSummary: ow?.forecastSummary,
    );
  }

  Future<void> _save(WeatherEntry entry) async {
    await _entriesCol.add(_toMap(entry));
  }

  Map<String, dynamic> _toMap(WeatherEntry e) => {
        'eventId': e.eventId,
        'timestamp': Timestamp.fromDate(e.timestamp),
        'source': e.source.name,
        'tag': e.tag.name,
        'windSpeedKts': e.windSpeedKts,
        'windGustKts': e.windGustKts,
        'windDirectionDeg': e.windDirectionDeg,
        'windDirectionLabel': e.windDirectionLabel,
        'temperatureF': e.temperatureF,
        'humidity': e.humidity,
        'pressureMb': e.pressureMb,
        'visibility': e.visibility,
        'seaState': e.seaState?.name,
        'forecastSummary': e.forecastSummary,
        'notes': e.notes,
        'loggedBy': e.loggedBy,
      };

  WeatherEntry _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return WeatherEntry(
      id: doc.id,
      eventId: d['eventId'] as String? ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      source: WeatherSource.values.firstWhere(
        (s) => s.name == (d['source'] as String? ?? ''),
        orElse: () => WeatherSource.merged,
      ),
      tag: WeatherEntryTag.values.firstWhere(
        (t) => t.name == (d['tag'] as String? ?? ''),
        orElse: () => WeatherEntryTag.routine,
      ),
      windSpeedKts: (d['windSpeedKts'] as num?)?.toDouble() ?? 0,
      windGustKts: (d['windGustKts'] as num?)?.toDouble(),
      windDirectionDeg: (d['windDirectionDeg'] as num?)?.toDouble() ?? 0,
      windDirectionLabel: d['windDirectionLabel'] as String? ?? '',
      temperatureF: (d['temperatureF'] as num?)?.toDouble(),
      humidity: (d['humidity'] as num?)?.toDouble(),
      pressureMb: (d['pressureMb'] as num?)?.toDouble(),
      visibility: d['visibility'] as String?,
      seaState: d['seaState'] != null
          ? SeaState.values.firstWhere(
              (s) => s.name == d['seaState'],
              orElse: () => SeaState.moderate,
            )
          : null,
      forecastSummary: d['forecastSummary'] as String?,
      notes: d['notes'] as String? ?? '',
      loggedBy: d['loggedBy'] as String?,
    );
  }
}
