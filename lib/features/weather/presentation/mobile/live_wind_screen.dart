import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mpyc_raceday/core/theme.dart';
import 'package:mpyc_raceday/features/weather/data/models/live_weather.dart';
import 'package:mpyc_raceday/features/weather/presentation/live_weather_providers.dart';
import 'package:mpyc_raceday/features/weather/presentation/widgets/wind_compass_widget.dart';
import 'package:mpyc_raceday/shared/services/distance_utils.dart';

class LiveWindScreen extends ConsumerStatefulWidget {
  const LiveWindScreen({super.key});

  @override
  ConsumerState<LiveWindScreen> createState() => _LiveWindScreenState();
}

class _LiveWindScreenState extends ConsumerState<LiveWindScreen> {
  Position? _userPosition;
  String? _locationError;
  bool _locationLoading = true;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    if (kIsWeb) {
      // On web, attempt a single position; stream not reliable
      try {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          final requested = await Geolocator.requestPermission();
          if (requested == LocationPermission.denied ||
              requested == LocationPermission.deniedForever) {
            setState(() {
              _locationError = 'Location permission denied';
              _locationLoading = false;
            });
            return;
          }
        }
        if (perm == LocationPermission.deniedForever) {
          setState(() {
            _locationError = 'Location permanently denied. Enable in browser settings.';
            _locationLoading = false;
          });
          return;
        }
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        if (mounted) {
          setState(() {
            _userPosition = pos;
            _locationLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _locationError = 'Could not get location';
            _locationLoading = false;
          });
        }
      }
      return;
    }

    // Mobile: use position stream
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services disabled';
          _locationLoading = false;
        });
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _locationLoading = false;
          });
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permanently denied. Enable in Settings.';
          _locationLoading = false;
        });
        return;
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (pos) {
          if (mounted) {
            setState(() {
              _userPosition = pos;
              _locationLoading = false;
            });
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _locationError = 'Location error';
              _locationLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Could not access location';
          _locationLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(liveWeatherProvider);
    final speedUnit = ref.watch(windSpeedUnitProvider);
    final distUnit = ref.watch(distanceUnitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Wind'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Speed unit toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<WindSpeedUnit>(
              segments: const [
                ButtonSegment(value: WindSpeedUnit.kts, label: Text('kts')),
                ButtonSegment(value: WindSpeedUnit.mph, label: Text('mph')),
              ],
              selected: {speedUnit},
              onSelectionChanged: (v) =>
                  ref.read(windSpeedUnitProvider.notifier).state = v.first,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: WidgetStatePropertyAll(Colors.white),
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: weatherAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (weather) {
          if (weather == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No weather data available.\nWeather station data will appear here once configured.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final speed = speedUnit == WindSpeedUnit.kts
              ? weather.speedKts
              : weather.speedMph;
          final gust = speedUnit == WindSpeedUnit.kts
              ? weather.gustKts
              : weather.gustMph;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stale warning
                if (weather.isStale)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Data is ${weather.staleness.inSeconds}s old — station may be offline',
                            style: const TextStyle(color: Colors.orange, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Compass
                WindCompassWidget(
                  dirDeg: weather.dirDeg,
                  speed: speed,
                  unit: speedUnit,
                  gust: gust,
                  size: 240,
                ),

                const SizedBox(height: 16),

                // Extra weather info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (weather.tempF != null)
                          _InfoColumn(
                            label: 'Temp',
                            value: '${weather.tempF!.toStringAsFixed(0)}°F',
                          ),
                        if (weather.humidity != null)
                          _InfoColumn(
                            label: 'Humidity',
                            value: '${weather.humidity!.toStringAsFixed(0)}%',
                          ),
                        if (weather.pressureInHg != null)
                          _InfoColumn(
                            label: 'Pressure',
                            value: '${weather.pressureInHg!.toStringAsFixed(2)}"',
                          ),
                        _InfoColumn(
                          label: 'Updated',
                          value: _timeAgo(weather.fetchedAt),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Distance card
                _buildDistanceCard(weather, distUnit),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDistanceCard(LiveWeather weather, DistanceUnit distUnit) {
    if (_locationLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Getting your location...'),
            ],
          ),
        ),
      );
    }

    if (_locationError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_locationError!, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text(
                      'Enable location to see your distance from the station.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_userPosition == null) return const SizedBox.shrink();

    final meters = DistanceUtils.haversineMeters(
      _userPosition!.latitude,
      _userPosition!.longitude,
      weather.station.lat,
      weather.station.lon,
    );

    String distStr;
    String unitLabel;
    switch (distUnit) {
      case DistanceUnit.nm:
        distStr = DistanceUtils.metersToNauticalMiles(meters).toStringAsFixed(2);
        unitLabel = 'nm';
      case DistanceUnit.mi:
        distStr = DistanceUtils.metersToMiles(meters).toStringAsFixed(2);
        unitLabel = 'mi';
      case DistanceUnit.km:
        distStr = DistanceUtils.metersToKm(meters).toStringAsFixed(2);
        unitLabel = 'km';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are $distStr $unitLabel from ${weather.station.name}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'GPS accuracy: ${_userPosition!.accuracy.toStringAsFixed(0)}m',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Spacer(),
                SegmentedButton<DistanceUnit>(
                  segments: const [
                    ButtonSegment(value: DistanceUnit.nm, label: Text('nm')),
                    ButtonSegment(value: DistanceUnit.mi, label: Text('mi')),
                    ButtonSegment(value: DistanceUnit.km, label: Text('km')),
                  ],
                  selected: {distUnit},
                  onSelectionChanged: (v) =>
                      ref.read(distanceUnitProvider.notifier).state = v.first,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
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

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
