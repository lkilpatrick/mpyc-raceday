import 'package:flutter/material.dart';

class WebNavItem {
  const WebNavItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

const List<WebNavItem> webNavItems = [
  WebNavItem(label: 'Dashboard', route: '/dashboard', icon: Icons.dashboard),
  WebNavItem(
    label: 'Season Calendar',
    route: '/season-calendar',
    icon: Icons.event_note,
  ),
  WebNavItem(
    label: 'Crew Management',
    route: '/crew-management',
    icon: Icons.group,
  ),
  WebNavItem(label: 'Members', route: '/members', icon: Icons.badge),
  WebNavItem(label: 'Race Events', route: '/race-events', icon: Icons.flag),
  WebNavItem(label: 'Courses', route: '/courses', icon: Icons.map),
  WebNavItem(
    label: 'Checklists',
    route: '/checklists-admin',
    icon: Icons.checklist_rtl,
  ),
  WebNavItem(label: 'Maintenance', route: '/maintenance', icon: Icons.build),
  WebNavItem(
    label: 'Incidents & Protests',
    route: '/incidents',
    icon: Icons.report,
  ),
  WebNavItem(label: 'Weather Logs', route: '/weather-logs', icon: Icons.cloud),
  WebNavItem(label: 'Reports', route: '/reports', icon: Icons.assessment),
  WebNavItem(label: 'Settings', route: '/settings', icon: Icons.settings),
];

class WebSidebar extends StatelessWidget {
  const WebSidebar({
    super.key,
    required this.activeRoute,
    required this.isCollapsed,
    required this.onSelected,
  });

  final String activeRoute;
  final bool isCollapsed;
  final ValueChanged<WebNavItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        for (final item in webNavItems)
          ListTile(
            selected: activeRoute == item.route,
            leading: Icon(item.icon),
            title: isCollapsed ? null : Text(item.label),
            tooltip: isCollapsed ? item.label : null,
            onTap: () => onSelected(item),
          ),
      ],
    );
  }
}
