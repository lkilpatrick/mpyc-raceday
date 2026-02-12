import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../weather/data/models/live_weather.dart';
import '../../../weather/presentation/live_weather_providers.dart';

/// Persistent weather header bar shown on every skipper screen.
/// Compact single-row: wind arrow · speed · gust · direction · freshness.
class WeatherHeader extends ConsumerWidget {
  const WeatherHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(liveWeatherProvider);

    return weatherAsync.when(
      loading: () => _shell(
        child: const Row(
          children: [
            Icon(Icons.air, size: 16, color: Colors.white70),
            SizedBox(width: 6),
            Text('Loading weather...',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      error: (_, __) => _shell(
        color: Colors.orange.shade800,
        child: const Row(
          children: [
            Icon(Icons.cloud_off, size: 16, color: Colors.white70),
            SizedBox(width: 6),
            Text('Weather feed unavailable',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      data: (weather) {
        if (weather == null) {
          return _shell(
            color: Colors.orange.shade800,
            child: const Row(
              children: [
                Icon(Icons.cloud_off, size: 16, color: Colors.white70),
                SizedBox(width: 6),
                Text('Weather feed unavailable',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          );
        }
        return _weatherBar(context, weather);
      },
    );
  }

  Widget _weatherBar(BuildContext context, LiveWeather w) {
    final age = w.staleness;
    final ageLabel = age.inMinutes < 1
        ? 'now'
        : age.inMinutes < 60
            ? '${age.inMinutes}m'
            : '${age.inHours}h';
    final isStale = w.isStale;

    return _shell(
      color: isStale ? Colors.orange.shade800 : const Color(0xFF1565C0),
      onTap: () => context.push('/live-wind'),
      child: Row(
        children: [
          // Wind direction arrow
          Transform.rotate(
            angle: (w.dirDeg + 180) * 3.14159 / 180,
            child: const Icon(Icons.navigation, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 6),
          // Speed
          Text(
            '${w.speedKts.toStringAsFixed(0)} kts',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          // Gust
          if (w.gustKts != null && w.gustKts! > 0) ...[
            const SizedBox(width: 4),
            Text(
              'G${w.gustKts!.toStringAsFixed(0)}',
              style: TextStyle(
                  color: Colors.red.shade200,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ],
          const SizedBox(width: 6),
          // Direction label
          Text(
            '${w.dirDeg}° ${w.windDirectionLabel}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          // Temp
          if (w.tempF != null) ...[
            Text('${w.tempF!.toStringAsFixed(0)}°F',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(width: 8),
          ],
          // Freshness
          if (isStale)
            const Icon(Icons.warning_amber, size: 12, color: Colors.yellow),
          Text(
            ageLabel,
            style: TextStyle(
                color: isStale ? Colors.yellow : Colors.white54, fontSize: 11),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 14, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _shell({
    required Widget child,
    Color color = const Color(0xFF1565C0),
    VoidCallback? onTap,
  }) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: child,
        ),
      ),
    );
  }
}
