import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/live_weather.dart';
import '../live_weather_providers.dart';
import '../widgets/wind_compass_widget.dart';

class WeatherLogPage extends ConsumerWidget {
  const WeatherLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(liveWeatherProvider);
    final unit = ref.watch(windSpeedUnitProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Current Weather',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Live data from NOAA via Cloud Function',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 20),

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
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No weather data available.\n\n'
                      'The NOAA Cloud Function writes to weather/mpyc_station every minute. '
                      'Check that the function is deployed and running.',
                    ),
                  ),
                );
              }
              return _buildWeatherContent(context, ref, weather, unit);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(
    BuildContext context,
    WidgetRef ref,
    LiveWeather weather,
    WindSpeedUnit unit,
  ) {
    final speed =
        unit == WindSpeedUnit.kts ? weather.speedKts : weather.speedMph;
    final gust =
        unit == WindSpeedUnit.kts ? weather.gustKts : weather.gustMph;
    final unitLabel = unit == WindSpeedUnit.kts ? 'kts' : 'mph';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stale / error banners
        if (weather.isStale)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Data is ${_stalenessText(weather.staleness)} old',
                  style:
                      const TextStyle(color: Colors.orange, fontSize: 13),
                ),
              ],
            ),
          ),
        if (weather.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              'Fetch error: ${weather.error}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        // Main layout: compass + details side by side
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wind compass card
                  SizedBox(
                    width: 320,
                    child: _compassCard(context, weather, speed, gust, unit),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: _detailsCard(
                        context, weather, speed, gust, unitLabel),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _compassCard(context, weather, speed, gust, unit),
                const SizedBox(height: 16),
                _detailsCard(context, weather, speed, gust, unitLabel),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _compassCard(
    BuildContext context,
    LiveWeather weather,
    double speed,
    double? gust,
    WindSpeedUnit unit,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            WindCompassWidget(
              dirDeg: weather.dirDeg,
              speed: speed,
              unit: unit,
              gust: gust,
              size: 220,
            ),
            const SizedBox(height: 12),
            Text(
              'Wind from ${weather.windDirectionLabel} (${weather.dirDeg}°)',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsCard(
    BuildContext context,
    LiveWeather weather,
    double speed,
    double? gust,
    String unitLabel,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conditions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            _row('Wind Speed', '${speed.toStringAsFixed(1)} $unitLabel'),
            if (gust != null)
              _row('Gusts', '${gust.toStringAsFixed(1)} $unitLabel'),
            _row('Direction',
                '${weather.windDirectionLabel} (${weather.dirDeg}°)'),
            if (weather.tempF != null)
              _row('Temperature', '${weather.tempF!.toStringAsFixed(1)}°F'),
            if (weather.humidity != null)
              _row('Humidity', '${weather.humidity!.toStringAsFixed(0)}%'),
            if (weather.pressureInHg != null)
              _row('Pressure',
                  '${weather.pressureInHg!.toStringAsFixed(2)} inHg'),
            const Divider(height: 20),
            _row('Station', weather.station.name),
            _row('Source', weather.source.toUpperCase()),
            _row('Observed',
                DateFormat.yMMMd().add_jm().format(weather.observedAt)),
            _row('Updated',
                DateFormat.yMMMd().add_jm().format(weather.fetchedAt)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  static String _stalenessText(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }
}
