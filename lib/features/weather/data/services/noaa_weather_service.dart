import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_models.dart';

class NoaaWeatherService {
  NoaaWeatherService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // Monterey Bay area — NOAA marine forecast point
  static const _lat = 36.6002;
  static const _lon = -121.8947;
  static const _baseUrl = 'https://api.weather.gov';
  static const _userAgent = 'MPYCRaceDay/1.0 (contact@mpyc.org)';

  Map<String, String> get _headers => {
        'User-Agent': _userAgent,
        'Accept': 'application/geo+json',
      };

  /// Fetch current conditions from the nearest observation station.
  Future<WeatherEntry?> fetchCurrentConditions({String eventId = ''}) async {
    try {
      // Get the nearest observation station
      final pointUrl = Uri.parse('$_baseUrl/points/$_lat,$_lon');
      final pointResp = await _client.get(pointUrl, headers: _headers);
      if (pointResp.statusCode != 200) return null;

      final pointData = json.decode(pointResp.body) as Map<String, dynamic>;
      final properties = pointData['properties'] as Map<String, dynamic>?;
      if (properties == null) return null;

      final stationUrl =
          properties['observationStations'] as String? ?? '';
      if (stationUrl.isEmpty) return null;

      // Get station list
      final stationsResp =
          await _client.get(Uri.parse(stationUrl), headers: _headers);
      if (stationsResp.statusCode != 200) return null;

      final stationsData =
          json.decode(stationsResp.body) as Map<String, dynamic>;
      final features = stationsData['features'] as List<dynamic>?;
      if (features == null || features.isEmpty) return null;

      final stationId = (features[0] as Map<String, dynamic>)['properties']
              ?['stationIdentifier'] as String? ??
          '';
      if (stationId.isEmpty) return null;

      // Get latest observation
      final obsUrl =
          Uri.parse('$_baseUrl/stations/$stationId/observations/latest');
      final obsResp = await _client.get(obsUrl, headers: _headers);
      if (obsResp.statusCode != 200) return null;

      final obsData = json.decode(obsResp.body) as Map<String, dynamic>;
      final obs = obsData['properties'] as Map<String, dynamic>?;
      if (obs == null) return null;

      // Parse values — NOAA uses SI units (wind can be m/s or km/h)
      final windSpeedMs = _toMs(obs['windSpeed']);
      final windGustMs = _toMs(obs['windGust']);
      final windDirDeg =
          (obs['windDirection']?['value'] as num?)?.toDouble() ?? 0;
      final tempC =
          (obs['temperature']?['value'] as num?)?.toDouble();
      final humidity =
          (obs['relativeHumidity']?['value'] as num?)?.toDouble();
      final pressurePa =
          (obs['barometricPressure']?['value'] as num?)?.toDouble();
      final visibilityM =
          (obs['visibility']?['value'] as num?)?.toDouble();

      // Convert
      final windSpeedKts = (windSpeedMs ?? 0) * 1.94384;
      final windGustKts =
          windGustMs != null ? windGustMs * 1.94384 : null;
      final tempF = tempC != null ? tempC * 9 / 5 + 32 : null;
      final pressureMb =
          pressurePa != null ? pressurePa / 100 : null;
      final visStr = visibilityM != null
          ? '${(visibilityM / 1609.34).toStringAsFixed(1)} mi'
          : null;

      return WeatherEntry(
        id: '',
        eventId: eventId,
        timestamp: DateTime.now(),
        source: WeatherSource.noaa,
        windSpeedKts: windSpeedKts,
        windGustKts: windGustKts,
        windDirectionDeg: windDirDeg,
        windDirectionLabel: _degToCompass(windDirDeg),
        temperatureF: tempF,
        humidity: humidity,
        pressureMb: pressureMb,
        visibility: visStr,
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetch marine forecast for the Monterey Bay area.
  Future<MarineForecast?> fetchMarineForecast() async {
    try {
      final pointUrl = Uri.parse('$_baseUrl/points/$_lat,$_lon');
      final pointResp = await _client.get(pointUrl, headers: _headers);
      if (pointResp.statusCode != 200) return null;

      final pointData = json.decode(pointResp.body) as Map<String, dynamic>;
      final forecastUrl =
          pointData['properties']?['forecast'] as String? ?? '';
      if (forecastUrl.isEmpty) return null;

      final forecastResp =
          await _client.get(Uri.parse(forecastUrl), headers: _headers);
      if (forecastResp.statusCode != 200) return null;

      final forecastData =
          json.decode(forecastResp.body) as Map<String, dynamic>;
      final periods =
          forecastData['properties']?['periods'] as List<dynamic>? ?? [];

      final forecastPeriods = periods.take(6).map((p) {
        final pd = p as Map<String, dynamic>;
        return ForecastPeriod(
          name: pd['name'] as String? ?? '',
          startTime: DateTime.tryParse(pd['startTime'] as String? ?? '') ??
              DateTime.now(),
          endTime: DateTime.tryParse(pd['endTime'] as String? ?? '') ??
              DateTime.now(),
          windSpeed: pd['windSpeed'] as String? ?? '',
          windDirection: pd['windDirection'] as String? ?? '',
          shortForecast: pd['shortForecast'] as String? ?? '',
          detailedForecast: pd['detailedForecast'] as String? ?? '',
        );
      }).toList();

      return MarineForecast(periods: forecastPeriods);
    } catch (e) {
      return null;
    }
  }

  /// Convert NOAA wind value object to m/s, handling km/h unitCode.
  /// NOAA uses unitCode like "wmoUnit:km_h-1" (km/h) or "wmoUnit:m_s-1" (m/s).
  static double? _toMs(Map<String, dynamic>? valueObj) {
    if (valueObj == null) return null;
    final val = (valueObj['value'] as num?)?.toDouble();
    if (val == null) return null;
    final unit = (valueObj['unitCode'] as String? ?? '').toLowerCase();
    if (unit.contains('km_h') || unit.contains('km/h')) return val / 3.6;
    if (unit.contains('mi_h') || unit.contains('mph')) return val * 0.44704;
    return val; // default: m/s
  }

  static String _degToCompass(double deg) {
    const dirs = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    final index = ((deg / 22.5) + 0.5).toInt() % 16;
    return dirs[index];
  }
}
