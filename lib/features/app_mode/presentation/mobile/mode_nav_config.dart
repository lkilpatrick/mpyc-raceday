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
          ModeNavItem(label: 'Home', route: '/rc-home', icon: Icons.flag),
          ModeNavItem(label: 'Race', route: '/rc-timing', icon: Icons.sailing),
          ModeNavItem(label: 'Scoring', route: '/rc-scoring', icon: Icons.leaderboard),
          ModeNavItem(label: 'Weather', route: '/rc-weather', icon: Icons.cloud),
          ModeNavItem(label: 'More', route: '/rc-more', icon: Icons.menu),
        ],
      AppMode.skipper => const [
          ModeNavItem(label: 'Home', route: '/skipper-home', icon: Icons.sailing),
          ModeNavItem(label: 'Race', route: '/skipper-race-tab', icon: Icons.gps_fixed),
          ModeNavItem(label: 'Results', route: '/skipper-results-tab', icon: Icons.leaderboard),
          ModeNavItem(label: 'Rules', route: '/skipper-rules-tab', icon: Icons.gavel),
          ModeNavItem(label: 'More', route: '/skipper-more', icon: Icons.menu),
        ],
      AppMode.crew => const [
          ModeNavItem(label: 'Home', route: '/crew-home', icon: Icons.group),
          ModeNavItem(label: 'Rules', route: '/crew-rules-tab', icon: Icons.menu_book),
          ModeNavItem(label: 'More', route: '/crew-more', icon: Icons.menu),
        ],
      AppMode.onshore => const [
          ModeNavItem(label: 'Home', route: '/onshore-home', icon: Icons.home),
          ModeNavItem(label: 'Live', route: '/onshore-live', icon: Icons.visibility),
          ModeNavItem(label: 'Results', route: '/onshore-results', icon: Icons.leaderboard),
          ModeNavItem(label: 'Weather', route: '/onshore-weather', icon: Icons.cloud),
          ModeNavItem(label: 'More', route: '/onshore-more', icon: Icons.menu),
        ],
    };
