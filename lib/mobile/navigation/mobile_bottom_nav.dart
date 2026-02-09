import 'package:flutter/material.dart';

class MobileNavItem {
  const MobileNavItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

const List<MobileNavItem> mobileNavItems = [
  MobileNavItem(label: 'Home', route: '/home', icon: Icons.home),
  MobileNavItem(label: 'Schedule', route: '/schedule', icon: Icons.event),
  MobileNavItem(
    label: 'Checklists',
    route: '/checklists',
    icon: Icons.checklist,
  ),
  MobileNavItem(label: 'Weather', route: '/weather', icon: Icons.cloud),
  MobileNavItem(label: 'More', route: '/more', icon: Icons.more_horiz),
];

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        for (final item in mobileNavItems)
          BottomNavigationBarItem(icon: Icon(item.icon), label: item.label),
      ],
    );
  }
}
