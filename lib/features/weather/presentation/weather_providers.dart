import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/weather_models.dart';
import '../data/services/noaa_weather_service.dart';
import '../data/services/openweather_service.dart';
import '../data/services/weather_alert_service.dart';
import '../data/services/weather_polling_service.dart';

final noaaServiceProvider = Provider<NoaaWeatherService>((ref) {
  return NoaaWeatherService();
});

final openWeatherServiceProvider = Provider<OpenWeatherService>((ref) {
  final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  return OpenWeatherService(apiKey: apiKey);
});

final weatherPollingServiceProvider = Provider<WeatherPollingService>((ref) {
  return WeatherPollingService(
    noaaService: ref.watch(noaaServiceProvider),
    openWeatherService: ref.watch(openWeatherServiceProvider),
  );
});

final weatherAlertServiceProvider = Provider<WeatherAlertService>((ref) {
  return WeatherAlertService();
});

final weatherEntriesProvider =
    StreamProvider.family<List<WeatherEntry>, String>((ref, eventId) {
  return ref.watch(weatherPollingServiceProvider).watchEntries(eventId);
});

final currentConditionsProvider = FutureProvider<WeatherEntry?>((ref) async {
  final noaa = await ref.watch(noaaServiceProvider).fetchCurrentConditions();
  final ow = await ref.watch(openWeatherServiceProvider).fetchCurrentWeather();
  if (noaa == null && ow == null) return null;
  return WeatherEntry(
    id: '',
    eventId: '',
    timestamp: DateTime.now(),
    source: WeatherSource.merged,
    windSpeedKts: noaa?.windSpeedKts ?? ow?.windSpeedKts ?? 0,
    windGustKts: noaa?.windGustKts ?? ow?.windGustKts,
    windDirectionDeg: noaa?.windDirectionDeg ?? ow?.windDirectionDeg ?? 0,
    windDirectionLabel: noaa?.windDirectionLabel ?? ow?.windDirectionLabel ?? '',
    temperatureF: noaa?.temperatureF ?? ow?.temperatureF,
    humidity: noaa?.humidity ?? ow?.humidity,
    pressureMb: noaa?.pressureMb ?? ow?.pressureMb,
    visibility: noaa?.visibility ?? ow?.visibility,
    forecastSummary: ow?.forecastSummary,
  );
});

final marineForecastProvider = FutureProvider<MarineForecast?>((ref) {
  return ref.watch(noaaServiceProvider).fetchMarineForecast();
});
