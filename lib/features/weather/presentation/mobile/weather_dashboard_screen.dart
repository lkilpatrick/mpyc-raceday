import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/live_weather.dart';
import '../live_weather_providers.dart';
import '../weather_providers.dart';
import '../widgets/wind_compass_widget.dart';

class WeatherDashboardScreen extends ConsumerWidget {
  const WeatherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(liveWeatherProvider);
    final forecastAsync = ref.watch(marineForecastProvider);
    final unit = ref.watch(windSpeedUnitProvider);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Current conditions hero card
        weatherAsync.when(
          loading: () => const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Unable to load weather: $e'),
            ),
          ),
          data: (weather) {
            if (weather == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No weather data available from NOAA.'),
                ),
              );
            }
            return _CurrentConditionsCard(weather: weather, unit: unit);
          },
        ),
        const SizedBox(height: 8),

        // Unit toggle + Live Wind link
        Row(
          children: [
            SegmentedButton<WindSpeedUnit>(
              segments: const [
                ButtonSegment(value: WindSpeedUnit.kts, label: Text('kts')),
                ButtonSegment(value: WindSpeedUnit.mph, label: Text('mph')),
              ],
              selected: {unit},
              onSelectionChanged: (v) =>
                  ref.read(windSpeedUnitProvider.notifier).state = v.first,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.push('/live-wind'),
              icon: const Icon(Icons.gps_fixed, size: 16),
              label: const Text('Live Wind + GPS'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Marine forecast
        Text('Marine Forecast',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        forecastAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Card(child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Forecast unavailable'),
              )),
          data: (forecast) {
            if (forecast == null || forecast.periods.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No forecast data'),
                ),
              );
            }
            return Column(
              children: forecast.periods.take(4).map((p) {
                return Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.shortForecast),
                    trailing: Text(
                      '${p.windSpeed}\n${p.windDirection}',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CurrentConditionsCard extends StatelessWidget {
  const _CurrentConditionsCard({required this.weather, required this.unit});
  final LiveWeather weather;
  final WindSpeedUnit unit;

  @override
  Widget build(BuildContext context) {
    final speed = unit == WindSpeedUnit.kts ? weather.speedKts : weather.speedMph;
    final gust = unit == WindSpeedUnit.kts ? weather.gustKts : weather.gustMph;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stale warning
            if (weather.isStale)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Data is ${weather.staleness.inSeconds}s old',
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Error banner
            if (weather.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Fetch error: ${weather.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              ),

            // Wind compass
            WindCompassWidget(
              dirDeg: weather.dirDeg,
              speed: speed,
              unit: unit,
              gust: gust,
              size: 200,
            ),
            const SizedBox(height: 12),
            Text(
              'Wind from ${weather.windDirectionLabel} (${weather.dirDeg}°)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  icon: Icons.thermostat,
                  label: 'Temp',
                  value: weather.tempF != null
                      ? '${weather.tempF!.toStringAsFixed(0)}°F'
                      : '—',
                ),
                _StatItem(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: weather.humidity != null
                      ? '${weather.humidity!.toStringAsFixed(0)}%'
                      : '—',
                ),
                _StatItem(
                  icon: Icons.speed,
                  label: 'Pressure',
                  value: weather.pressureInHg != null
                      ? '${weather.pressureInHg!.toStringAsFixed(2)}"'
                      : '—',
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Source: ${weather.station.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Updated ${_timeAgo(weather.fetchedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
