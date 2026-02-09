import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_models.dart';

class OpenWeatherService {
  OpenWeatherService({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  // Monterey Bay area
  static const _lat = 36.6002;
  static const _lon = -121.8947;
  static const _baseUrl = 'https://api.openweathermap.org/data/3.0';

  /// Fetch current weather conditions.
  Future<WeatherEntry?> fetchCurrentWeather({String eventId = ''}) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/onecall?lat=$_lat&lon=$_lon&units=imperial&exclude=minutely,daily,alerts&appid=$apiKey',
      );
      final resp = await _client.get(url);
      if (resp.statusCode != 200) return null;

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      final windSpeedMph = (current['wind_speed'] as num?)?.toDouble() ?? 0;
      final windGustMph = (current['wind_gust'] as num?)?.toDouble();
      final windDeg = (current['wind_deg'] as num?)?.toDouble() ?? 0;
      final temp = (current['temp'] as num?)?.toDouble();
      final humidity = (current['humidity'] as num?)?.toDouble();
      final pressure = (current['pressure'] as num?)?.toDouble();
      final visibilityM = (current['visibility'] as num?)?.toDouble();

      // Convert mph to knots
      final windSpeedKts = windSpeedMph * 0.868976;
      final windGustKts =
          windGustMph != null ? windGustMph * 0.868976 : null;
      final visStr = visibilityM != null
          ? '${(visibilityM / 1609.34).toStringAsFixed(1)} mi'
          : null;

      final weatherDesc = (current['weather'] as List<dynamic>?)
              ?.map((w) => (w as Map<String, dynamic>)['description'] ?? '')
              .join(', ') ??
          '';

      return WeatherEntry(
        id: '',
        eventId: eventId,
        timestamp: DateTime.now(),
        source: WeatherSource.openWeather,
        windSpeedKts: windSpeedKts,
        windGustKts: windGustKts,
        windDirectionDeg: windDeg,
        windDirectionLabel: _degToCompass(windDeg),
        temperatureF: temp,
        humidity: humidity,
        pressureMb: pressure,
        visibility: visStr,
        forecastSummary: weatherDesc,
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetch 48-hour hourly forecast.
  Future<List<WeatherEntry>> fetchHourlyForecast(
      {String eventId = ''}) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/onecall?lat=$_lat&lon=$_lon&units=imperial&exclude=minutely,daily,alerts,current&appid=$apiKey',
      );
      final resp = await _client.get(url);
      if (resp.statusCode != 200) return [];

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final hourly = data['hourly'] as List<dynamic>? ?? [];

      return hourly.take(48).map((h) {
        final hr = h as Map<String, dynamic>;
        final dt = DateTime.fromMillisecondsSinceEpoch(
            (hr['dt'] as int) * 1000);
        final windMph = (hr['wind_speed'] as num?)?.toDouble() ?? 0;
        final gustMph = (hr['wind_gust'] as num?)?.toDouble();
        final windDeg = (hr['wind_deg'] as num?)?.toDouble() ?? 0;
        final temp = (hr['temp'] as num?)?.toDouble();
        final humidity = (hr['humidity'] as num?)?.toDouble();
        final pressure = (hr['pressure'] as num?)?.toDouble();

        return WeatherEntry(
          id: '',
          eventId: eventId,
          timestamp: dt,
          source: WeatherSource.openWeather,
          windSpeedKts: windMph * 0.868976,
          windGustKts: gustMph != null ? gustMph * 0.868976 : null,
          windDirectionDeg: windDeg,
          windDirectionLabel: _degToCompass(windDeg),
          temperatureF: temp,
          humidity: humidity,
          pressureMb: pressure,
        );
      }).toList();
    } catch (e) {
      return [];
    }
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
