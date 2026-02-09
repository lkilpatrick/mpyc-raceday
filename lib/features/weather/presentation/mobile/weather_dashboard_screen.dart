import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/wind_compass_widget.dart';
import '../../data/models/weather_models.dart';
import '../weather_providers.dart';

class WeatherDashboardScreen extends ConsumerWidget {
  const WeatherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditionsAsync = ref.watch(currentConditionsProvider);
    final forecastAsync = ref.watch(marineForecastProvider);
    final pollingService = ref.watch(weatherPollingServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weather')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showManualEntry(context, ref, conditionsAsync.valueOrNull),
        child: const Icon(Icons.edit),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Logging indicator
          if (pollingService.isLogging)
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 12),
                    const SizedBox(width: 8),
                    const Text('Weather logging active',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // Current conditions hero card
          conditionsAsync.when(
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
            data: (entry) {
              if (entry == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No weather data available'),
                  ),
                );
              }
              return _CurrentConditionsCard(entry: entry);
            },
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
      ),
    );
  }

  void _showManualEntry(
    BuildContext context,
    WidgetRef ref,
    WeatherEntry? prefill,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ManualWeatherEntrySheet(prefill: prefill, ref: ref),
    );
  }
}

class _CurrentConditionsCard extends StatelessWidget {
  const _CurrentConditionsCard({required this.entry});
  final WeatherEntry entry;

  @override
  Widget build(BuildContext context) {
    final ago = DateTime.now().difference(entry.timestamp).inMinutes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Wind compass
            WindCompassWidget(
              windSpeedKts: entry.windSpeedKts,
              windGustKts: entry.windGustKts,
              windDirectionDeg: entry.windDirectionDeg,
              windDirectionLabel: entry.windDirectionLabel,
              size: 180,
            ),
            const SizedBox(height: 12),
            Text(
              'Wind from ${entry.windDirectionLabel} (${entry.windDirectionDeg.toStringAsFixed(0)}°)',
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
                  value: entry.temperatureF != null
                      ? '${entry.temperatureF!.toStringAsFixed(0)}°F'
                      : '—',
                ),
                _StatItem(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: entry.humidity != null
                      ? '${entry.humidity!.toStringAsFixed(0)}%'
                      : '—',
                ),
                _StatItem(
                  icon: Icons.speed,
                  label: 'Pressure',
                  value: entry.pressureMb != null
                      ? '${entry.pressureMb!.toStringAsFixed(0)} mb'
                      : '—',
                ),
                _StatItem(
                  icon: Icons.visibility,
                  label: 'Visibility',
                  value: entry.visibility ?? '—',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Sea state
            if (entry.seaState != null)
              Chip(
                label: Text(
                    'Sea: ${entry.seaState!.name[0].toUpperCase()}${entry.seaState!.name.substring(1)}'),
              ),

            Text(
              'Updated $ago min ago',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
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

class ManualWeatherEntrySheet extends StatefulWidget {
  const ManualWeatherEntrySheet({super.key, this.prefill, required this.ref});
  final WeatherEntry? prefill;
  final WidgetRef ref;

  @override
  State<ManualWeatherEntrySheet> createState() =>
      _ManualWeatherEntrySheetState();
}

class _ManualWeatherEntrySheetState extends State<ManualWeatherEntrySheet> {
  late final TextEditingController _windSpeed;
  late final TextEditingController _windGust;
  late final TextEditingController _windDir;
  late final TextEditingController _notes;
  SeaState _seaState = SeaState.moderate;
  String _visibility = 'Good';

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    _windSpeed =
        TextEditingController(text: p?.windSpeedKts.toStringAsFixed(0) ?? '');
    _windGust =
        TextEditingController(text: p?.windGustKts?.toStringAsFixed(0) ?? '');
    _windDir =
        TextEditingController(text: p?.windDirectionDeg.toStringAsFixed(0) ?? '');
    _notes = TextEditingController();
    if (p?.seaState != null) _seaState = p!.seaState!;
  }

  @override
  void dispose() {
    _windSpeed.dispose();
    _windGust.dispose();
    _windDir.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manual Weather Entry',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _windSpeed,
                  decoration: const InputDecoration(labelText: 'Wind (kts)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _windGust,
                  decoration: const InputDecoration(labelText: 'Gust (kts)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _windDir,
                  decoration: const InputDecoration(labelText: 'Direction (°)'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<SeaState>(
                  value: _seaState,
                  decoration: const InputDecoration(labelText: 'Sea State'),
                  items: SeaState.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.name[0].toUpperCase() +
                                s.name.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _seaState = v ?? _seaState),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _visibility,
                  decoration: const InputDecoration(labelText: 'Visibility'),
                  items: ['Excellent', 'Good', 'Moderate', 'Poor', 'Very Poor']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _visibility = v ?? _visibility),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Log Entry'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final entry = WeatherEntry(
      id: '',
      eventId: widget.ref.read(weatherPollingServiceProvider).activeEventId ?? '',
      timestamp: DateTime.now(),
      source: WeatherSource.manual,
      windSpeedKts: double.tryParse(_windSpeed.text) ?? 0,
      windGustKts: double.tryParse(_windGust.text),
      windDirectionDeg: double.tryParse(_windDir.text) ?? 0,
      windDirectionLabel: _degToCompass(double.tryParse(_windDir.text) ?? 0),
      seaState: _seaState,
      visibility: _visibility,
      notes: _notes.text.trim(),
      loggedBy: 'manual',
    );

    await widget.ref
        .read(weatherPollingServiceProvider)
        .saveManualEntry(entry);

    if (mounted) Navigator.pop(context);
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
