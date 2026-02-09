import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/weather_models.dart';
import '../weather_providers.dart';

class WeatherLogPage extends ConsumerStatefulWidget {
  const WeatherLogPage({super.key});

  @override
  ConsumerState<WeatherLogPage> createState() => _WeatherLogPageState();
}

class _WeatherLogPageState extends ConsumerState<WeatherLogPage> {
  String _eventId = '';

  @override
  Widget build(BuildContext context) {
    final entriesAsync = _eventId.isNotEmpty
        ? ref.watch(weatherEntriesProvider(_eventId))
        : const AsyncValue<List<WeatherEntry>>.data([]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event selector + export
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Weather Log',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 16),
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Event ID',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => setState(() => _eventId = v.trim()),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _exportCsv(
                    entriesAsync.valueOrNull ?? []),
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
              ),
            ],
          ),
        ),

        if (_eventId.isEmpty)
          const Expanded(
            child: Center(child: Text('Enter an event ID to view weather log')),
          )
        else
          Expanded(
            child: entriesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(
                      child: Text('No weather entries for this event.'));
                }

                return Column(
                  children: [
                    // Wind chart
                    SizedBox(
                      height: 160,
                      child: _WindChart(entries: entries),
                    ),
                    const Divider(),

                    // Data table
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Time')),
                              DataColumn(label: Text('Source')),
                              DataColumn(label: Text('Tag')),
                              DataColumn(label: Text('Wind (kts)')),
                              DataColumn(label: Text('Gust')),
                              DataColumn(label: Text('Dir')),
                              DataColumn(label: Text('Temp')),
                              DataColumn(label: Text('Pressure')),
                              DataColumn(label: Text('Visibility')),
                              DataColumn(label: Text('Notes')),
                            ],
                            rows: entries.map((e) {
                              final isTagged =
                                  e.tag != WeatherEntryTag.routine;
                              return DataRow(
                                color: isTagged
                                    ? WidgetStateProperty.all(
                                        Colors.blue.shade50)
                                    : null,
                                cells: [
                                  DataCell(Text(DateFormat.Hm()
                                      .format(e.timestamp))),
                                  DataCell(_sourceChip(e.source)),
                                  DataCell(Text(isTagged
                                      ? _tagLabel(e.tag)
                                      : '')),
                                  DataCell(Text(e.windSpeedKts
                                      .toStringAsFixed(0))),
                                  DataCell(Text(e.windGustKts
                                          ?.toStringAsFixed(0) ??
                                      '—')),
                                  DataCell(Text(
                                      '${e.windDirectionLabel} ${e.windDirectionDeg.toStringAsFixed(0)}°')),
                                  DataCell(Text(e.temperatureF
                                          ?.toStringAsFixed(0) ??
                                      '—')),
                                  DataCell(Text(e.pressureMb
                                          ?.toStringAsFixed(0) ??
                                      '—')),
                                  DataCell(
                                      Text(e.visibility ?? '—')),
                                  DataCell(Text(e.notes)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _sourceChip(WeatherSource source) {
    final (label, color) = switch (source) {
      WeatherSource.noaa => ('NOAA', Colors.blue),
      WeatherSource.openWeather => ('OWM', Colors.orange),
      WeatherSource.manual => ('Manual', Colors.green),
      WeatherSource.merged => ('Merged', Colors.purple),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.15),
      visualDensity: VisualDensity.compact,
    );
  }

  String _tagLabel(WeatherEntryTag tag) => switch (tag) {
        WeatherEntryTag.routine => '',
        WeatherEntryTag.preRace => 'Pre-Race',
        WeatherEntryTag.raceStart => 'Race Start',
        WeatherEntryTag.raceFinish => 'Race Finish',
        WeatherEntryTag.postRace => 'Post-Race',
        WeatherEntryTag.alert => 'Alert',
      };

  void _exportCsv(List<WeatherEntry> entries) {
    final buf = StringBuffer();
    buf.writeln(
        'Time,Source,Tag,Wind (kts),Gust,Direction,Temp (F),Pressure (mb),Visibility,Notes');
    for (final e in entries) {
      buf.writeln(
        '${DateFormat('HH:mm').format(e.timestamp)},${e.source.name},${e.tag.name},${e.windSpeedKts.toStringAsFixed(1)},${e.windGustKts?.toStringAsFixed(1) ?? ''},${e.windDirectionLabel} ${e.windDirectionDeg.toStringAsFixed(0)},${e.temperatureF?.toStringAsFixed(0) ?? ''},${e.pressureMb?.toStringAsFixed(0) ?? ''},${e.visibility ?? ''},"${e.notes}"',
      );
    }
    final uri =
        Uri.dataFromString(buf.toString(), mimeType: 'text/csv', encoding: utf8);
    launchUrl(uri);
  }
}

class _WindChart extends StatelessWidget {
  const _WindChart({required this.entries});
  final List<WeatherEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final maxWind = entries
        .map((e) => e.windGustKts ?? e.windSpeedKts)
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((e) {
          final windH =
              maxWind > 0 ? (e.windSpeedKts / maxWind) * 100 : 0.0;
          final gustH = e.windGustKts != null && maxWind > 0
              ? (e.windGustKts! / maxWind) * 100
              : 0.0;
          final isTagged = e.tag != WeatherEntryTag.routine;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isTagged)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                    ),
                  if (gustH > windH)
                    Container(
                      height: gustH - windH,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2)),
                      ),
                    ),
                  Container(
                    height: windH,
                    decoration: BoxDecoration(
                      color: e.windSpeedKts >= 25
                          ? Colors.red
                          : e.windSpeedKts >= 15
                              ? Colors.orange
                              : Colors.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
