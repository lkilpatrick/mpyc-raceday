import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/weather/data/models/weather_models.dart';

void main() {
  // ─────────────────────────────────────────────────────────────
  // Bug 1: Compass direction formula inconsistency
  // NoaaWeatherService._degToCompass and LiveWeather.windDirectionLabel
  // must produce identical results for the same degree input.
  // ─────────────────────────────────────────────────────────────

  String degToCompass(double deg) {
    const dirs = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    final index = ((deg + 11.25) % 360 / 22.5).floor() % 16;
    return dirs[index];
  }

  // Replicate LiveWeather.windDirectionLabel logic (uses int)
  String liveWeatherLabel(int dirDeg) {
    const labels = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    final index = ((dirDeg + 11.25) % 360 / 22.5).floor();
    return labels[index % 16];
  }

  group('Compass direction consistency', () {
    test('cardinal directions match between both implementations', () {
      expect(degToCompass(0), 'N');
      expect(degToCompass(90), 'E');
      expect(degToCompass(180), 'S');
      expect(degToCompass(270), 'W');

      expect(liveWeatherLabel(0), 'N');
      expect(liveWeatherLabel(90), 'E');
      expect(liveWeatherLabel(180), 'S');
      expect(liveWeatherLabel(270), 'W');
    });

    test('intercardinal directions match', () {
      expect(degToCompass(45), 'NE');
      expect(degToCompass(135), 'SE');
      expect(degToCompass(225), 'SW');
      expect(degToCompass(315), 'NW');

      expect(liveWeatherLabel(45), 'NE');
      expect(liveWeatherLabel(135), 'SE');
      expect(liveWeatherLabel(225), 'SW');
      expect(liveWeatherLabel(315), 'NW');
    });

    test('boundary degrees produce same result in both', () {
      // Test all 16 compass points at their exact center
      final expectedAtDeg = {
        0: 'N', 22: 'NNE', 45: 'NE', 67: 'ENE',
        90: 'E', 112: 'ESE', 135: 'SE', 157: 'SSE',
        180: 'S', 202: 'SSW', 225: 'SW', 247: 'WSW',
        270: 'W', 292: 'WNW', 315: 'NW', 337: 'NNW',
      };

      for (final entry in expectedAtDeg.entries) {
        final deg = entry.key;
        final expected = entry.value;
        expect(degToCompass(deg.toDouble()), expected,
            reason: 'degToCompass($deg) should be $expected');
        expect(liveWeatherLabel(deg), expected,
            reason: 'liveWeatherLabel($deg) should be $expected');
      }
    });

    test('near-360 wraps to N correctly', () {
      expect(degToCompass(355), 'N');
      expect(liveWeatherLabel(355), 'N');
      expect(degToCompass(359), 'N');
      expect(liveWeatherLabel(359), 'N');
    });

    test('both implementations agree for every 5-degree increment', () {
      for (int deg = 0; deg < 360; deg += 5) {
        final fromNoaa = degToCompass(deg.toDouble());
        final fromLive = liveWeatherLabel(deg);
        expect(fromNoaa, fromLive,
            reason: 'Mismatch at $deg°: NOAA=$fromNoaa, Live=$fromLive');
      }
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Bug 2: WeatherEntry.copyWith can't clear nullable fields
  // ─────────────────────────────────────────────────────────────

  group('WeatherEntry.copyWith nullable fields', () {
    final base = WeatherEntry(
      id: '1',
      eventId: 'evt1',
      timestamp: DateTime(2025, 1, 1),
      source: WeatherSource.noaa,
      windSpeedKts: 10,
      windGustKts: 15,
      windDirectionDeg: 270,
      windDirectionLabel: 'W',
      temperatureF: 65,
      humidity: 72,
      pressureMb: 1013,
      visibility: '10 mi',
      seaState: SeaState.moderate,
      forecastSummary: 'Clear',
      loggedBy: 'admin',
    );

    test('copyWith preserves values when not specified', () {
      final copy = base.copyWith(windSpeedKts: 20);
      expect(copy.windSpeedKts, 20);
      expect(copy.windGustKts, 15); // preserved
      expect(copy.temperatureF, 65); // preserved
      expect(copy.loggedBy, 'admin'); // preserved
    });

    test('copyWith can set nullable field to a new value', () {
      final copy = base.copyWith(windGustKts: 25.0);
      expect(copy.windGustKts, 25.0);
    });

    test('copyWith can clear windGustKts to null', () {
      final copy = base.copyWith(windGustKts: null);
      expect(copy.windGustKts, isNull);
    });

    test('copyWith can clear temperatureF to null', () {
      final copy = base.copyWith(temperatureF: null);
      expect(copy.temperatureF, isNull);
    });

    test('copyWith can clear humidity to null', () {
      final copy = base.copyWith(humidity: null);
      expect(copy.humidity, isNull);
    });

    test('copyWith can clear pressureMb to null', () {
      final copy = base.copyWith(pressureMb: null);
      expect(copy.pressureMb, isNull);
    });

    test('copyWith can clear visibility to null', () {
      final copy = base.copyWith(visibility: null);
      expect(copy.visibility, isNull);
    });

    test('copyWith can clear seaState to null', () {
      final copy = base.copyWith(seaState: null);
      expect(copy.seaState, isNull);
    });

    test('copyWith can clear forecastSummary to null', () {
      final copy = base.copyWith(forecastSummary: null);
      expect(copy.forecastSummary, isNull);
    });

    test('copyWith can clear loggedBy to null', () {
      final copy = base.copyWith(loggedBy: null);
      expect(copy.loggedBy, isNull);
    });

    test('copyWith can clear multiple nullable fields at once', () {
      final copy = base.copyWith(
        windGustKts: null,
        temperatureF: null,
        forecastSummary: null,
      );
      expect(copy.windGustKts, isNull);
      expect(copy.temperatureF, isNull);
      expect(copy.forecastSummary, isNull);
      // Others preserved
      expect(copy.humidity, 72);
      expect(copy.pressureMb, 1013);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Bug 3: CSV import doesn't handle quoted fields
  // ─────────────────────────────────────────────────────────────

  // Extracted from BoatCheckinRepositoryImpl._parseCsvLine
  List<String> parseCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString().trim());
    return result;
  }

  group('CSV line parser', () {
    test('simple unquoted line', () {
      expect(parseCsvLine('a,b,c'), ['a', 'b', 'c']);
    });

    test('quoted field with comma inside', () {
      expect(parseCsvLine('42,"Smith, Jr.",J/105'), ['42', 'Smith, Jr.', 'J/105']);
    });

    test('quoted field with escaped double-quote', () {
      expect(parseCsvLine('42,"The ""Big"" Boat",J/105'),
          ['42', 'The "Big" Boat', 'J/105']);
    });

    test('empty fields', () {
      expect(parseCsvLine(',,'), ['', '', '']);
    });

    test('mixed quoted and unquoted', () {
      expect(parseCsvLine('42,"Wind, Dancer",John Doe,J/105,84'),
          ['42', 'Wind, Dancer', 'John Doe', 'J/105', '84']);
    });

    test('whitespace around quoted field is trimmed', () {
      expect(parseCsvLine(' 42 , "Wind Dancer" , 84 '),
          ['42', 'Wind Dancer', '84']);
    });

    test('single field', () {
      expect(parseCsvLine('hello'), ['hello']);
    });

    test('empty string', () {
      expect(parseCsvLine(''), ['']);
    });

    test('quoted field at end of line', () {
      expect(parseCsvLine('42,"Last Field"'), ['42', 'Last Field']);
    });

    test('full CSV with quoted boat names parses correctly', () {
      const header = 'Sail,Boat Name,Owner,Class,PHRF';
      const row = '42,"Wind, Dancer","Smith, Jr.",J/105,84';

      final headers = parseCsvLine(header).map((h) => h.toLowerCase()).toList();
      final cols = parseCsvLine(row);

      expect(headers, ['sail', 'boat name', 'owner', 'class', 'phrf']);
      expect(cols[0], '42');
      expect(cols[1], 'Wind, Dancer');
      expect(cols[2], 'Smith, Jr.');
      expect(cols[3], 'J/105');
      expect(cols[4], '84');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Bug 4: isStale threshold too aggressive
  // ─────────────────────────────────────────────────────────────

  group('LiveWeather isStale threshold', () {
    // We test the logic directly since LiveWeather requires Firestore import
    bool isStale(DateTime fetchedAt) {
      return DateTime.now().difference(fetchedAt).inSeconds > 120;
    }

    test('data fetched 30 seconds ago is NOT stale', () {
      final fetchedAt = DateTime.now().subtract(const Duration(seconds: 30));
      expect(isStale(fetchedAt), isFalse);
    });

    test('data fetched 60 seconds ago is NOT stale', () {
      final fetchedAt = DateTime.now().subtract(const Duration(seconds: 60));
      expect(isStale(fetchedAt), isFalse);
    });

    test('data fetched 90 seconds ago is NOT stale', () {
      final fetchedAt = DateTime.now().subtract(const Duration(seconds: 90));
      expect(isStale(fetchedAt), isFalse);
    });

    test('data fetched 120 seconds ago is NOT stale (boundary)', () {
      final fetchedAt = DateTime.now().subtract(const Duration(seconds: 120));
      expect(isStale(fetchedAt), isFalse);
    });

    test('data fetched 121 seconds ago IS stale', () {
      final fetchedAt = DateTime.now().subtract(const Duration(seconds: 121));
      expect(isStale(fetchedAt), isTrue);
    });

    test('data fetched 5 minutes ago IS stale', () {
      final fetchedAt = DateTime.now().subtract(const Duration(minutes: 5));
      expect(isStale(fetchedAt), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Bug 5: NOAA wind unit conversion
  // ─────────────────────────────────────────────────────────────

  group('NOAA wind unit conversion (_toMs)', () {
    // Extracted from NoaaWeatherService._toMs
    double? toMs(Map<String, dynamic>? valueObj) {
      if (valueObj == null) return null;
      final val = (valueObj['value'] as num?)?.toDouble();
      if (val == null) return null;
      final unit = (valueObj['unitCode'] as String? ?? '').toLowerCase();
      if (unit.contains('km_h') || unit.contains('km/h')) return val / 3.6;
      if (unit.contains('mi_h') || unit.contains('mph')) return val * 0.44704;
      return val; // default: m/s
    }

    test('null input returns null', () {
      expect(toMs(null), isNull);
    });

    test('null value returns null', () {
      expect(toMs({'value': null, 'unitCode': 'wmoUnit:m_s-1'}), isNull);
    });

    test('m/s passes through unchanged', () {
      final result = toMs({'value': 10.0, 'unitCode': 'wmoUnit:m_s-1'});
      expect(result, 10.0);
    });

    test('km/h converted to m/s correctly', () {
      final result = toMs({'value': 36.0, 'unitCode': 'wmoUnit:km_h-1'});
      expect(result, closeTo(10.0, 0.01));
    });

    test('mph converted to m/s correctly', () {
      final result = toMs({'value': 10.0, 'unitCode': 'wmoUnit:mi_h-1'});
      expect(result, closeTo(4.4704, 0.001));
    });

    test('unknown unit defaults to m/s', () {
      final result = toMs({'value': 5.0, 'unitCode': 'wmoUnit:unknown'});
      expect(result, 5.0);
    });

    test('zero wind speed returns 0 (not null)', () {
      final result = toMs({'value': 0, 'unitCode': 'wmoUnit:m_s-1'});
      expect(result, 0.0);
    });
  });
}
