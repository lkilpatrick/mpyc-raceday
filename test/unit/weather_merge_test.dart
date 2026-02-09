import 'package:flutter_test/flutter_test.dart';

void main() {
  // Test the weather merge logic used in currentConditionsProvider
  // (extracted logic, not the actual provider)

  Map<String, dynamic>? mergeWeather(
    Map<String, dynamic>? noaa,
    Map<String, dynamic>? ow,
  ) {
    if (noaa == null && ow == null) return null;
    return {
      'windSpeedKts': noaa?['windSpeedKts'] ?? ow?['windSpeedKts'] ?? 0,
      'windGustKts': noaa?['windGustKts'] ?? ow?['windGustKts'],
      'windDirectionDeg':
          noaa?['windDirectionDeg'] ?? ow?['windDirectionDeg'] ?? 0,
      'windDirectionLabel':
          noaa?['windDirectionLabel'] ?? ow?['windDirectionLabel'] ?? '',
      'temperatureF': noaa?['temperatureF'] ?? ow?['temperatureF'],
      'humidity': noaa?['humidity'] ?? ow?['humidity'],
      'pressureMb': noaa?['pressureMb'] ?? ow?['pressureMb'],
      'visibility': noaa?['visibility'] ?? ow?['visibility'],
      'forecastSummary': ow?['forecastSummary'],
    };
  }

  group('Weather merge logic', () {
    test('both null returns null', () {
      expect(mergeWeather(null, null), isNull);
    });

    test('NOAA only — uses NOAA values', () {
      final result = mergeWeather({
        'windSpeedKts': 12.0,
        'windGustKts': 18.0,
        'windDirectionDeg': 270.0,
        'windDirectionLabel': 'W',
        'temperatureF': 65.0,
        'humidity': 72,
        'pressureMb': 1013.0,
        'visibility': 10.0,
      }, null);

      expect(result, isNotNull);
      expect(result!['windSpeedKts'], 12.0);
      expect(result['windGustKts'], 18.0);
      expect(result['windDirectionLabel'], 'W');
      expect(result['forecastSummary'], isNull);
    });

    test('OpenWeather only — uses OW values', () {
      final result = mergeWeather(null, {
        'windSpeedKts': 10.0,
        'windGustKts': 15.0,
        'windDirectionDeg': 180.0,
        'windDirectionLabel': 'S',
        'temperatureF': 70.0,
        'forecastSummary': 'Partly cloudy',
      });

      expect(result, isNotNull);
      expect(result!['windSpeedKts'], 10.0);
      expect(result['windDirectionLabel'], 'S');
      expect(result['forecastSummary'], 'Partly cloudy');
    });

    test('both present — NOAA takes priority, OW fills gaps', () {
      final result = mergeWeather({
        'windSpeedKts': 12.0,
        'windGustKts': 18.0,
        'windDirectionDeg': 270.0,
        'windDirectionLabel': 'W',
        'temperatureF': 65.0,
        'humidity': null, // NOAA missing humidity
        'pressureMb': 1013.0,
        'visibility': null, // NOAA missing visibility
      }, {
        'windSpeedKts': 10.0,
        'windGustKts': 14.0,
        'windDirectionDeg': 260.0,
        'windDirectionLabel': 'WSW',
        'temperatureF': 68.0,
        'humidity': 75,
        'pressureMb': 1012.0,
        'visibility': 8.0,
        'forecastSummary': 'Clear skies',
      });

      expect(result, isNotNull);
      // NOAA values take priority
      expect(result!['windSpeedKts'], 12.0);
      expect(result['windGustKts'], 18.0);
      expect(result['windDirectionDeg'], 270.0);
      expect(result['windDirectionLabel'], 'W');
      expect(result['temperatureF'], 65.0);
      expect(result['pressureMb'], 1013.0);
      // OW fills gaps
      expect(result['humidity'], 75);
      expect(result['visibility'], 8.0);
      // Forecast always from OW
      expect(result['forecastSummary'], 'Clear skies');
    });

    test('NOAA wind with OW forecast', () {
      final result = mergeWeather({
        'windSpeedKts': 20.0,
        'windDirectionDeg': 315.0,
        'windDirectionLabel': 'NW',
      }, {
        'forecastSummary': 'Small craft advisory',
      });

      expect(result!['windSpeedKts'], 20.0);
      expect(result['windDirectionLabel'], 'NW');
      expect(result['forecastSummary'], 'Small craft advisory');
    });

    test('zero wind speed is preserved (not treated as null)', () {
      final result = mergeWeather({
        'windSpeedKts': 0,
        'windDirectionDeg': 0,
        'windDirectionLabel': 'Calm',
      }, {
        'windSpeedKts': 5.0,
      });

      // NOAA's 0 should NOT fall through to OW's 5.0
      // But with ?? operator, 0 is falsy in Dart? No — 0 is NOT null in Dart
      expect(result!['windSpeedKts'], 0);
    });
  });
}
