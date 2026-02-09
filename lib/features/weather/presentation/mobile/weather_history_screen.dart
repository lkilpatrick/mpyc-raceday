import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/weather_models.dart';
import '../weather_providers.dart';

class WeatherHistoryScreen extends ConsumerStatefulWidget {
  const WeatherHistoryScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<WeatherHistoryScreen> createState() =>
      _WeatherHistoryScreenState();
}

class _WeatherHistoryScreenState extends ConsumerState<WeatherHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(weatherEntriesProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Weather History')),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No weather entries recorded.'));
          }

          // Wind speed sparkline (simple bar representation)
          final maxWind = entries
              .map((e) => e.windSpeedKts)
              .reduce((a, b) => a > b ? a : b);

          return Column(
            children: [
              // Wind chart
              SizedBox(
                height: 120,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: entries.map((e) {
                      final h = maxWind > 0
                          ? (e.windSpeedKts / maxWind) * 80
                          : 0.0;
                      final color = e.windSpeedKts >= 25
                          ? Colors.red
                          : e.windSpeedKts >= 15
                              ? Colors.orange
                              : Colors.green;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                e.windSpeedKts.toStringAsFixed(0),
                                style: const TextStyle(fontSize: 8),
                              ),
                              Container(
                                height: h,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(),

              // Entries table
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    final tagLabel = e.tag != WeatherEntryTag.routine
                        ? ' [${_tagLabel(e.tag)}]'
                        : '';
                    return ListTile(
                      dense: true,
                      leading: _sourceIcon(e.source),
                      title: Text(
                        '${e.windSpeedKts.toStringAsFixed(0)} kts ${e.windDirectionLabel}$tagLabel',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat.Hm().format(e.timestamp),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (e.temperatureF != null)
                            Text('${e.temperatureF!.toStringAsFixed(0)}°F',
                                style: const TextStyle(fontSize: 12)),
                          if (e.windGustKts != null)
                            Text(
                                'G${e.windGustKts!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.orange)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sourceIcon(WeatherSource source) {
    switch (source) {
      case WeatherSource.noaa:
        return const Icon(Icons.public, size: 18, color: Colors.blue);
      case WeatherSource.openWeather:
        return const Icon(Icons.cloud, size: 18, color: Colors.orange);
      case WeatherSource.manual:
        return const Icon(Icons.person, size: 18, color: Colors.green);
      case WeatherSource.merged:
        return const Icon(Icons.merge, size: 18, color: Colors.purple);
    }
  }

  String _tagLabel(WeatherEntryTag tag) => switch (tag) {
        WeatherEntryTag.routine => '',
        WeatherEntryTag.preRace => 'Pre-Race',
        WeatherEntryTag.raceStart => 'Race Start',
        WeatherEntryTag.raceFinish => 'Race Finish',
        WeatherEntryTag.postRace => 'Post-Race',
        WeatherEntryTag.alert => 'Alert',
      };
}
