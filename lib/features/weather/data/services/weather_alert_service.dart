import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/weather_models.dart';

class WeatherAlertService {
  WeatherAlertService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  WeatherAlertConfig _config = const WeatherAlertConfig();
  final List<WeatherEntry> _recentEntries = [];

  /// Load alert thresholds from Firestore settings.
  Future<void> loadConfig() async {
    try {
      final doc =
          await _firestore.collection('settings').doc('weather_alerts').get();
      if (doc.exists) {
        final d = doc.data()!;
        _config = WeatherAlertConfig(
          highWindKts: (d['highWindKts'] as num?)?.toDouble() ?? 30,
          gustAlertKts: (d['gustAlertKts'] as num?)?.toDouble() ?? 35,
          lightningRadiusMiles:
              (d['lightningRadiusMiles'] as num?)?.toDouble() ?? 10,
          rapidWindShiftDeg:
              (d['rapidWindShiftDeg'] as num?)?.toDouble() ?? 30,
          rapidWindShiftMinutes:
              (d['rapidWindShiftMinutes'] as int?) ?? 15,
        );
      }
    } catch (_) {}
  }

  /// Save alert thresholds to Firestore.
  Future<void> saveConfig(WeatherAlertConfig config) async {
    _config = config;
    await _firestore.collection('settings').doc('weather_alerts').set({
      'highWindKts': config.highWindKts,
      'gustAlertKts': config.gustAlertKts,
      'lightningRadiusMiles': config.lightningRadiusMiles,
      'rapidWindShiftDeg': config.rapidWindShiftDeg,
      'rapidWindShiftMinutes': config.rapidWindShiftMinutes,
    });
  }

  WeatherAlertConfig get config => _config;

  /// Check a new weather entry against thresholds.
  /// Returns list of alert messages (empty if no alerts).
  List<String> checkEntry(WeatherEntry entry) {
    final alerts = <String>[];

    // High wind
    if (entry.windSpeedKts >= _config.highWindKts) {
      alerts.add(
        'HIGH WIND ALERT: ${entry.windSpeedKts.toStringAsFixed(0)} kts '
        '(threshold: ${_config.highWindKts.toStringAsFixed(0)} kts). '
        'Consider postponing or shortening course.',
      );
    }

    // Gust alert
    if (entry.windGustKts != null &&
        entry.windGustKts! >= _config.gustAlertKts) {
      alerts.add(
        'GUST ALERT: ${entry.windGustKts!.toStringAsFixed(0)} kts gusts '
        '(threshold: ${_config.gustAlertKts.toStringAsFixed(0)} kts). '
        'Monitor conditions closely.',
      );
    }

    // Rapid wind shift
    if (_recentEntries.isNotEmpty) {
      final cutoff = entry.timestamp.subtract(
        Duration(minutes: _config.rapidWindShiftMinutes),
      );
      final recent = _recentEntries.where(
        (e) => e.timestamp.isAfter(cutoff),
      );
      if (recent.isNotEmpty) {
        final oldDir = recent.first.windDirectionDeg;
        final newDir = entry.windDirectionDeg;
        var shift = (newDir - oldDir).abs();
        if (shift > 180) shift = 360 - shift;
        if (shift >= _config.rapidWindShiftDeg) {
          alerts.add(
            'WIND SHIFT ALERT: ${shift.toStringAsFixed(0)}° shift in '
            '${_config.rapidWindShiftMinutes} minutes '
            '(${recent.first.windDirectionLabel} → ${entry.windDirectionLabel}). '
            'Course adjustment may be needed.',
          );
        }
      }
    }

    // Track recent entries for shift detection
    _recentEntries.add(entry);
    if (_recentEntries.length > 20) _recentEntries.removeAt(0);

    // Send push notifications for alerts
    if (alerts.isNotEmpty) {
      _sendAlertNotifications(alerts);
    }

    return alerts;
  }

  Future<void> _sendAlertNotifications(List<String> alerts) async {
    // Store alert in Firestore for Cloud Function to pick up and send push
    for (final alert in alerts) {
      await _firestore.collection('weather_alerts').add({
        'message': alert,
        'timestamp': FieldValue.serverTimestamp(),
        'sent': false,
      });
    }
  }
}
