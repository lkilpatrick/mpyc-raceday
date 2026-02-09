import 'package:flutter/material.dart';

/// Nautical-themed empty state widget for list screens.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  // ── Pre-built empty states ──

  static const noEvents = EmptyState(
    icon: Icons.sailing,
    title: 'Smooth seas ahead',
    subtitle: 'No races scheduled',
  );

  static const noMaintenance = EmptyState(
    icon: Icons.check_circle_outline,
    title: 'Ship shape!',
    subtitle: 'No issues reported',
  );

  static const noIncidents = EmptyState(
    icon: Icons.thumb_up_outlined,
    title: 'Clean racing!',
    subtitle: 'No incidents to report',
  );

  static const noCheckins = EmptyState(
    icon: Icons.directions_boat_outlined,
    title: 'No boats yet',
    subtitle: 'Check-ins will appear here',
  );

  static const noResults = EmptyState(
    icon: Icons.emoji_events_outlined,
    title: 'No results yet',
    subtitle: 'Race results will appear after finishes are recorded',
  );

  static const noChecklists = EmptyState(
    icon: Icons.checklist_outlined,
    title: 'All clear',
    subtitle: 'No checklists assigned',
  );

  static const noWeather = EmptyState(
    icon: Icons.cloud_off_outlined,
    title: 'No weather data',
    subtitle: 'Weather readings will appear here',
  );

  static const noCrew = EmptyState(
    icon: Icons.group_outlined,
    title: 'No crew assigned',
    subtitle: 'Crew assignments will appear here',
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade400,
                  ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
