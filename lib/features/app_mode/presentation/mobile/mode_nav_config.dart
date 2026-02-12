import 'package:flutter/material.dart';
import '../../data/app_mode.dart';

class ModeNavItem {
  const ModeNavItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

List<ModeNavItem> navItemsForMode(AppMode mode) => switch (mode) {
      AppMode.raceCommittee => const [
          ModeNavItem(label: 'RC Home', route: '/home', icon: Icons.flag),
          ModeNavItem(label: 'Course', route: '/course', icon: Icons.map),
          ModeNavItem(label: 'Timing', route: '/rc-timing', icon: Icons.timer),
          ModeNavItem(label: 'Weather', route: '/weather', icon: Icons.cloud),
          ModeNavItem(label: 'More', route: '/more', icon: Icons.menu),
        ],
      AppMode.skipper => const [
          ModeNavItem(label: 'Home', route: '/home', icon: Icons.sailing),
          ModeNavItem(label: 'Race', route: '/race-mode', icon: Icons.gps_fixed),
          ModeNavItem(label: 'Weather', route: '/weather', icon: Icons.cloud),
          ModeNavItem(label: 'Protest', route: '/rules/advisor', icon: Icons.gavel),
          ModeNavItem(label: 'More', route: '/more', icon: Icons.menu),
        ],
      AppMode.crew => const [
          ModeNavItem(label: 'Home', route: '/home', icon: Icons.group),
          ModeNavItem(label: 'Role', route: '/crew-dashboard', icon: Icons.assignment),
          ModeNavItem(label: 'Chat', route: '/crew-chat', icon: Icons.chat),
          ModeNavItem(label: 'Safety', route: '/crew-safety', icon: Icons.health_and_safety),
          ModeNavItem(label: 'More', route: '/more', icon: Icons.menu),
        ],
      AppMode.onshore => const [
          ModeNavItem(label: 'Home', route: '/home', icon: Icons.home),
          ModeNavItem(label: 'Live', route: '/spectator', icon: Icons.visibility),
          ModeNavItem(label: 'Results', route: '/leaderboard', icon: Icons.leaderboard),
          ModeNavItem(label: 'Weather', route: '/weather', icon: Icons.cloud),
          ModeNavItem(label: 'More', route: '/more', icon: Icons.menu),
        ],
    };
