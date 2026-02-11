import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/live_weather.dart';
import '../live_weather_providers.dart';
import '../widgets/wind_compass_widget.dart';

class WeatherLogPage extends ConsumerStatefulWidget {
  const WeatherLogPage({super.key});

  @override
  ConsumerState<WeatherLogPage> createState() => _WeatherLogPageState();
}

class _WeatherLogPageState extends ConsumerState<WeatherLogPage> {
  String? _selectedStationId;

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(liveWeatherProvider);
    final stationsAsync = ref.watch(allStationsWeatherProvider);
    final unit = ref.watch(windSpeedUnitProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 960;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Text(
                'Live data from NOAA NWS, CO-OPS, and Weather Underground stations near Monterey Harbor',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),

            // Main content area
            Expanded(
              child: stationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading stations: $e')),
                data: (stations) {
                  if (isWide) {
                    return _buildSplitLayout(context, weatherAsync, stations, unit);
                  }
                  return _buildStackedLayout(context, weatherAsync, stations, unit);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Split layout: station list left, map right ──────────────────

  Widget _buildSplitLayout(
    BuildContext context,
    AsyncValue<LiveWeather?> weatherAsync,
    List<LiveWeather> stations,
    WindSpeedUnit unit,
  ) {
    return Row(
      children: [
        // Left panel: scrollable station list
        SizedBox(
          width: 420,
          child: _buildStationListPanel(context, weatherAsync, stations, unit),
        ),
        // Right panel: map
        Expanded(
          child: _buildMapPanel(context, stations, unit),
        ),
      ],
    );
  }

  // ── Stacked layout (narrow screens) ─────────────────────────────

  Widget _buildStackedLayout(
    BuildContext context,
    AsyncValue<LiveWeather?> weatherAsync,
    List<LiveWeather> stations,
    WindSpeedUnit unit,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map at top on mobile
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 300,
              child: _buildMap(context, stations, unit),
            ),
          ),
          const SizedBox(height: 16),

          // Primary weather
          weatherAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Unable to load weather: $e'),
              ),
            ),
            data: (weather) {
              if (weather == null) return const SizedBox.shrink();
              return _buildWeatherContent(context, ref, weather, unit);
            },
          ),
          const SizedBox(height: 24),

          // Station cards
          if (stations.isNotEmpty)
            _buildStationComparison(context, stations, unit),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Left panel: station list ────────────────────────────────────

  Widget _buildStationListPanel(
    BuildContext context,
    AsyncValue<LiveWeather?> weatherAsync,
    List<LiveWeather> stations,
    WindSpeedUnit unit,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 16, 24),
        children: [
          // Primary weather compact
          weatherAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Unable to load weather: $e'),
              ),
            ),
            data: (weather) {
              if (weather == null) return const SizedBox.shrink();
              return _buildWeatherContent(context, ref, weather, unit);
            },
          ),
          const SizedBox(height: 20),

          // Station list grouped by type
          if (stations.isNotEmpty)
            _buildStationList(context, stations, unit),
        ],
      ),
    );
  }

  // ── Map panel ───────────────────────────────────────────────────

  Widget _buildMapPanel(
    BuildContext context,
    List<LiveWeather> stations,
    WindSpeedUnit unit,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMap(context, stations, unit),
      ),
    );
  }

  Widget _buildMap(
    BuildContext context,
    List<LiveWeather> stations,
    WindSpeedUnit unit,
  ) {
    // Center on Monterey Harbor
    const center = LatLng(36.600, -121.890);
    final unitLabel = unit == WindSpeedUnit.kts ? 'kts' : 'mph';

    return FlutterMap(
      options: const MapOptions(
        initialCenter: center,
        initialZoom: 12.0,
        minZoom: 10,
        maxZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.mpyc.raceday',
        ),
        MarkerLayer(
          markers: stations.map((w) {
            final isSelected = _selectedStationId == (w.stationId ?? w.station.id);
            final color = _typeColor(w.stationType);
            final speed = unit == WindSpeedUnit.kts ? w.speedKts : w.speedMph;

            return Marker(
              point: LatLng(w.station.lat, w.station.lon),
              width: isSelected ? 180 : 140,
              height: isSelected ? 72 : 56,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStationId = (w.stationId ?? w.station.id) == _selectedStationId
                        ? null
                        : (w.stationId ?? w.station.id);
                  });
                },
                child: _MapMarker(
                  station: w,
                  color: color,
                  isSelected: isSelected,
                  label: w.stationType == 'coops'
                      ? (w.waterTempF != null ? 'Water ${w.waterTempF!.toStringAsFixed(0)}°F' : '—')
                      : '${speed.toStringAsFixed(1)} $unitLabel ${w.windDirectionLabel} ${w.dirDeg}°',
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
    // Group stations by type
    final nws = stations.where((s) => s.stationType == 'nws').toList();
    final coops = stations.where((s) => s.stationType == 'coops').toList();
    final wu = stations.where((s) => s.stationType == 'wunderground').toList();
    // Anything without a type goes into NWS (legacy data)
    final untyped = stations.where((s) =>
        s.stationType != 'nws' && s.stationType != 'coops' && s.stationType != 'wunderground').toList();
    final nwsAll = [...nws, ...untyped];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
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
            _badge(context, '${stations.length} stations',
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.onPrimaryContainer),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Live data from NOAA NWS, CO-OPS, and Weather Underground stations within ~10 miles of Monterey Harbor',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        // NWS / AWOS stations
        if (nwsAll.isNotEmpty) ...[
          _groupHeader(context, 'NWS / AWOS', Icons.air, Colors.blue.shade700,
              'Official aviation weather stations'),
          const SizedBox(height: 8),
          _stationGrid(context, nwsAll, unit),
          const SizedBox(height: 24),
        ],

        // CO-OPS tide stations
        if (coops.isNotEmpty) ...[
          _groupHeader(context, 'NOAA CO-OPS', Icons.waves, Colors.teal.shade700,
              'Tide & coastal monitoring'),
          const SizedBox(height: 8),
          _stationGrid(context, coops, unit),
          const SizedBox(height: 24),
        ],

        // Weather Underground PWS
        if (wu.isNotEmpty) ...[
          _groupHeader(context, 'Weather Underground PWS', Icons.home, Colors.orange.shade700,
              'Private weather stations'),
          const SizedBox(height: 8),
          _stationGrid(context, wu, unit),
        ],
      ],
    );
  }

  Widget _groupHeader(BuildContext context, String title, IconData icon,
      Color color, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 8),
        Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _stationGrid(
      BuildContext context, List<LiveWeather> stations, WindSpeedUnit unit) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 900
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth > 600
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: stations.map((w) => SizedBox(
            width: cardWidth,
            child: _stationCard(context, w, unit),
          )).toList(),
        );
      },
    );
  }

  Widget _stationCard(BuildContext context, LiveWeather w, WindSpeedUnit unit) {
    final unitLabel = unit == WindSpeedUnit.kts ? 'kts' : 'mph';
    final speed = unit == WindSpeedUnit.kts ? w.speedKts : w.speedMph;
    final gust = unit == WindSpeedUnit.kts ? w.gustKts : w.gustMph;
    final isCoops = w.stationType == 'coops';
    final typeColor = _typeColor(w.stationType);

    return Card(
      elevation: w.station.isPrimary ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: w.station.isPrimary
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide(color: typeColor.withValues(alpha: 0.3)),
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
                      Text(w.station.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        '${w.stationId ?? w.station.id ?? ''} · ${w.station.distanceMi.toStringAsFixed(1)} mi',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (w.station.isPrimary)
                  _badge(context, 'Primary',
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.onPrimaryContainer),
                if (!w.station.isPrimary)
                  _badge(context, _typeLabel(w.stationType),
                      typeColor.withValues(alpha: 0.12), typeColor),
              ],
            ),
            const Divider(height: 20),

            // Main content varies by station type
            if (isCoops)
              _coopsContent(w)
            else
              _windContent(context, w, speed, gust, unitLabel),

            // Conditions
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (w.tempF != null)
                  _miniStat(Icons.thermostat, '${w.tempF!.toStringAsFixed(1)}°F'),
                if (w.waterTempF != null)
                  _miniStat(Icons.pool, 'Water ${w.waterTempF!.toStringAsFixed(1)}°F'),
                if (w.humidity != null)
                  _miniStat(Icons.water_drop, '${w.humidity!.toStringAsFixed(0)}%'),
                if (w.pressureInHg != null)
                  _miniStat(Icons.speed, '${w.pressureInHg!.toStringAsFixed(2)} inHg'),
              ],
            ),

            if (w.textDescription != null && !isCoops) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(w.textDescription!,
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
              ),
            ],

            const SizedBox(height: 8),
            Text(
              'Observed ${DateFormat.jm().format(w.observedAt)}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _windContent(BuildContext context, LiveWeather w, double speed,
      double? gust, String unitLabel) {
    return Row(
      children: [
        Transform.rotate(
          angle: (w.dirDeg * 3.14159 / 180) + 3.14159,
          child: Icon(Icons.navigation,
              size: 28, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${speed.toStringAsFixed(1)} $unitLabel',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(
              '${w.windDirectionLabel} (${w.dirDeg}°)'
              '${gust != null ? ' · G ${gust.toStringAsFixed(1)}' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _coopsContent(LiveWeather w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (w.waterTempF != null)
          Row(
            children: [
              Icon(Icons.pool, size: 28, color: Colors.teal.shade600),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${w.waterTempF!.toStringAsFixed(1)}°F',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Water Temperature',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        if (w.waterTempF == null && w.pressureInHg != null)
          Row(
            children: [
              Icon(Icons.speed, size: 28, color: Colors.teal.shade600),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${w.pressureInHg!.toStringAsFixed(2)} inHg',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Barometric Pressure',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _badge(BuildContext context, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  static Color _typeColor(String? type) {
    switch (type) {
      case 'nws':
        return Colors.blue.shade700;
      case 'coops':
        return Colors.teal.shade700;
      case 'wunderground':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  static String _typeLabel(String? type) {
    switch (type) {
      case 'nws':
        return 'NWS';
      case 'coops':
        return 'CO-OPS';
      case 'wunderground':
        return 'PWS';
      default:
        return 'Station';
    }
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

  // ── Compact station list for left panel ─────────────────────────

  Widget _buildStationList(
    BuildContext context,
    List<LiveWeather> stations,
    WindSpeedUnit unit,
  ) {
    final nws = stations.where((s) => s.stationType == 'nws').toList();
    final coops = stations.where((s) => s.stationType == 'coops').toList();
    final wu = stations.where((s) => s.stationType == 'wunderground').toList();
    final untyped = stations.where((s) =>
        s.stationType != 'nws' && s.stationType != 'coops' && s.stationType != 'wunderground').toList();
    final nwsAll = [...nws, ...untyped];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.compare_arrows, size: 18),
            const SizedBox(width: 6),
            Text('Nearby Stations',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _badge(context, '${stations.length}',
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.onPrimaryContainer),
          ],
        ),
        const SizedBox(height: 12),

        if (nwsAll.isNotEmpty) ...[
          _groupHeader(context, 'NWS / AWOS', Icons.air, Colors.blue.shade700, ''),
          const SizedBox(height: 4),
          ...nwsAll.map((w) => _compactStationTile(context, w, unit)),
          const SizedBox(height: 12),
        ],
        if (coops.isNotEmpty) ...[
          _groupHeader(context, 'NOAA CO-OPS', Icons.waves, Colors.teal.shade700, ''),
          const SizedBox(height: 4),
          ...coops.map((w) => _compactStationTile(context, w, unit)),
          const SizedBox(height: 12),
        ],
        if (wu.isNotEmpty) ...[
          _groupHeader(context, 'Weather Underground', Icons.home, Colors.orange.shade700, ''),
          const SizedBox(height: 4),
          ...wu.map((w) => _compactStationTile(context, w, unit)),
        ],
      ],
    );
  }

  Widget _compactStationTile(BuildContext context, LiveWeather w, WindSpeedUnit unit) {
    final unitLabel = unit == WindSpeedUnit.kts ? 'kts' : 'mph';
    final speed = unit == WindSpeedUnit.kts ? w.speedKts : w.speedMph;
    final gust = unit == WindSpeedUnit.kts ? w.gustKts : w.gustMph;
    final isCoops = w.stationType == 'coops';
    final stationId = w.stationId ?? w.station.id;
    final isSelected = _selectedStationId == stationId;
    final typeColor = _typeColor(w.stationType);

    return Card(
      elevation: isSelected ? 3 : 0,
      margin: const EdgeInsets.symmetric(vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: typeColor, width: 2)
            : BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _selectedStationId = stationId == _selectedStationId ? null : stationId;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Type indicator dot
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              // Station info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.station.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      '${stationId ?? ''} · ${w.station.distanceMi.toStringAsFixed(1)} mi',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // Value
              if (isCoops && w.waterTempF != null)
                Text('${w.waterTempF!.toStringAsFixed(1)}°F',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14,
                        color: Colors.teal.shade700))
              else if (!isCoops) ...[
                if (w.dirDeg > 0)
                  Transform.rotate(
                    angle: (w.dirDeg * math.pi / 180) + math.pi,
                    child: Icon(Icons.navigation, size: 16, color: typeColor),
                  ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${speed.toStringAsFixed(1)} $unitLabel',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '${w.windDirectionLabel} ${w.dirDeg}°${gust != null ? ' · G ${gust.toStringAsFixed(1)}' : ''}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Map marker widget ───────────────────────────────────────────

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.station,
    required this.color,
    required this.isSelected,
    required this.label,
  });

  final LiveWeather station;
  final Color color;
  final bool isSelected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Info bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: isSelected ? 2 : 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                station.station.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? Colors.white70 : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Pin triangle
        CustomPaint(
          size: const Size(12, 8),
          painter: _TrianglePainter(color: color),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
