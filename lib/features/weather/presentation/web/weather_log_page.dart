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
    final stationsAsync = ref.watch(allStationsWeatherProvider);
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

          // Multi-station comparison section
          const SizedBox(height: 32),
          stationsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stations) {
              if (stations.length < 2) return const SizedBox.shrink();
              return _buildStationComparison(context, stations, unit);
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
        child: WindCompassWidget(
          dirDeg: weather.dirDeg,
          speed: speed,
          unit: unit,
          gust: gust,
          size: 240,
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

  Widget _buildStationComparison(
    BuildContext context,
    List<LiveWeather> stations,
    WindSpeedUnit unit,
  ) {
    final unitLabel = unit == WindSpeedUnit.kts ? 'kts' : 'mph';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.compare_arrows, size: 20),
            const SizedBox(width: 8),
            Text('Nearby Stations',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${stations.length} stations',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Comparing NOAA weather stations within ~16 miles of Old Fisherman\'s Wharf',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        // Station comparison cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth > 900
                ? (constraints.maxWidth - 32) / 3
                : constraints.maxWidth > 600
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: stations.map((w) {
                final speed = unit == WindSpeedUnit.kts ? w.speedKts : w.speedMph;
                final gust = unit == WindSpeedUnit.kts ? w.gustKts : w.gustMph;

                return SizedBox(
                  width: cardWidth,
                  child: Card(
                    elevation: w.station.isPrimary ? 3 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: w.station.isPrimary
                          ? BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2)
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Station header
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      w.station.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${w.stationId ?? w.station.id ?? ''} · ${w.station.distanceMi.toStringAsFixed(1)} mi away',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (w.station.isPrimary)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('Primary',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      )),
                                ),
                            ],
                          ),
                          const Divider(height: 20),

                          // Wind info — prominent
                          Row(
                            children: [
                              Transform.rotate(
                                angle: (w.dirDeg * 3.14159 / 180) + 3.14159,
                                child: Icon(Icons.navigation,
                                    size: 28,
                                    color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${speed.toStringAsFixed(1)} $unitLabel',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${w.windDirectionLabel} (${w.dirDeg}°)'
                                    '${gust != null ? ' · G ${gust.toStringAsFixed(1)}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Other conditions
                          Wrap(
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              if (w.tempF != null)
                                _miniStat(Icons.thermostat,
                                    '${w.tempF!.toStringAsFixed(1)}°F'),
                              if (w.humidity != null)
                                _miniStat(Icons.water_drop,
                                    '${w.humidity!.toStringAsFixed(0)}%'),
                              if (w.pressureInHg != null)
                                _miniStat(Icons.speed,
                                    '${w.pressureInHg!.toStringAsFixed(2)} inHg'),
                            ],
                          ),

                          if (w.textDescription != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                w.textDescription!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),
                          Text(
                            'Observed ${DateFormat.jm().format(w.observedAt)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
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

  Widget _miniStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
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
