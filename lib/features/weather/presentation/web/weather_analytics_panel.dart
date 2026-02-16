import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/weather_models.dart';
import '../weather_providers.dart';

class WeatherAnalyticsPanel extends ConsumerStatefulWidget {
  const WeatherAnalyticsPanel({super.key});

  @override
  ConsumerState<WeatherAnalyticsPanel> createState() =>
      _WeatherAnalyticsPanelState();
}

class _WeatherAnalyticsPanelState
    extends ConsumerState<WeatherAnalyticsPanel> {
  List<WeatherEntry>? _allEntries;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = ref.read(weatherPollingServiceProvider);
    final entries = await service.getAllEntries();
    if (mounted) {
      setState(() {
        _allEntries = entries;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final entries = _allEntries ?? [];
    if (entries.isEmpty) {
      return const Center(child: Text('No weather data available for analysis.'));
    }

    // By day of week
    final byDow = <int, List<WeatherEntry>>{};
    for (final e in entries) {
      byDow.putIfAbsent(e.timestamp.weekday, () => []).add(e);
    }

    // By month
    final byMonth = <int, List<WeatherEntry>>{};
    for (final e in entries) {
      byMonth.putIfAbsent(e.timestamp.month, () => []).add(e);
    }

    // Overall stats
    final avgWind = entries.isEmpty
        ? 0.0
        : entries.map((e) => e.windSpeedKts).reduce((a, b) => a + b) /
            entries.length;
    final maxWind = entries.isEmpty
        ? 0.0
        : entries
            .map((e) => e.windSpeedKts)
            .reduce((a, b) => a > b ? a : b);
    final maxGust = entries
        .where((e) => e.windGustKts != null)
        .map((e) => e.windGustKts!)
        .fold<double>(0, (a, b) => a > b ? a : b);

    const dowNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weather Analytics',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          // Summary cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                title: 'Total Readings',
                value: '${entries.length}',
                icon: Icons.data_usage,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Avg Wind',
                value: '${avgWind.toStringAsFixed(1)} kts',
                icon: Icons.air,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Max Wind',
                value: '${maxWind.toStringAsFixed(0)} kts',
                icon: Icons.speed,
                color: Colors.orange,
              ),
              _StatCard(
                title: 'Max Gust',
                value: '${maxGust.toStringAsFixed(0)} kts',
                icon: Icons.bolt,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Average wind by day of week
          Text('Average Wind by Day of Week',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: List.generate(7, (i) {
                  final dow = i + 1;
                  final dayEntries = byDow[dow] ?? [];
                  final avg = dayEntries.isEmpty
                      ? 0.0
                      : dayEntries
                              .map((e) => e.windSpeedKts)
                              .reduce((a, b) => a + b) /
                          dayEntries.length;
                  final pct = maxWind > 0 ? avg / maxWind : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 40,
                            child: Text(dowNames[dow],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: pct,
                            color: avg >= 20
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${avg.toStringAsFixed(1)} kts',
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '(${dayEntries.length})',
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Average wind by month
          Text('Average Wind by Month',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: List.generate(12, (i) {
                  final month = i + 1;
                  final monthEntries = byMonth[month] ?? [];
                  final avg = monthEntries.isEmpty
                      ? 0.0
                      : monthEntries
                              .map((e) => e.windSpeedKts)
                              .reduce((a, b) => a + b) /
                          monthEntries.length;
                  final pct = maxWind > 0 ? avg / maxWind : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 40,
                            child: Text(monthNames[month],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: pct,
                            color: avg >= 20
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${avg.toStringAsFixed(1)} kts',
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '(${monthEntries.length})',
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // High wind events
          Text('High Wind Events (25+ kts)',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: entries
                  .where((e) => e.windSpeedKts >= 25)
                  .take(20)
                  .map((e) => ListTile(
                        dense: true,
                        title: Text(
                          '${e.windSpeedKts.toStringAsFixed(0)} kts ${e.windDirectionLabel}'
                          '${e.windGustKts != null ? " (G${e.windGustKts!.toStringAsFixed(0)})" : ""}',
                        ),
                        subtitle: Text(DateFormat.yMMMd()
                            .add_Hm()
                            .format(e.timestamp)),
                        trailing: Text(e.eventId.isNotEmpty
                            ? e.eventId.substring(0, 8)
                            : '—'),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
