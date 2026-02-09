import 'package:flutter/material.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';

/// Which roles can see this nav item.
/// If null, all authenticated users with web dashboard access can see it.
class WebNavItem {
  const WebNavItem({
    required this.label,
    required this.route,
    required this.icon,
    this.requiredRoles,
    this.section,
  });

  final String label;
  final String route;
  final IconData icon;
  final List<MemberRole>? requiredRoles;
  final String? section;

  bool isVisibleTo(List<MemberRole> userRoles) {
    if (requiredRoles == null) return true;
    return userRoles.any((r) => requiredRoles!.contains(r) || r == MemberRole.webAdmin);
  }
}

const List<WebNavItem> webNavItems = [
  // All web users
  WebNavItem(label: 'Dashboard', route: '/dashboard', icon: Icons.dashboard),

  // Race operations — web_admin + rc_chair
  WebNavItem(
    label: 'Season Calendar',
    route: '/season-calendar',
    icon: Icons.event_note,
    section: 'Race Operations',
  ),
  WebNavItem(
    label: 'Race Events',
    route: '/race-events',
    icon: Icons.flag,
    requiredRoles: [MemberRole.webAdmin, MemberRole.rcChair],
  ),
  WebNavItem(
    label: 'Crew Management',
    route: '/crew-management',
    icon: Icons.group,
    requiredRoles: [MemberRole.webAdmin, MemberRole.rcChair],
  ),
  WebNavItem(
    label: 'Courses',
    route: '/courses',
    icon: Icons.map,
    requiredRoles: [MemberRole.webAdmin, MemberRole.rcChair],
  ),
  WebNavItem(
    label: 'Checklists',
    route: '/checklists-admin',
    icon: Icons.checklist_rtl,
    requiredRoles: [MemberRole.webAdmin, MemberRole.rcChair],
  ),
  WebNavItem(
    label: 'Incidents & Protests',
    route: '/incidents',
    icon: Icons.report,
    requiredRoles: [MemberRole.webAdmin, MemberRole.rcChair],
  ),
  WebNavItem(
    label: 'Weather Logs',
    route: '/weather-logs',
    icon: Icons.cloud,
    requiredRoles: [MemberRole.webAdmin, MemberRole.rcChair],
  ),

  // Maintenance — web_admin + rc_chair
  WebNavItem(
    label: 'Maintenance',
    route: '/maintenance',
    icon: Icons.build,
    requiredRoles: [MemberRole.webAdmin, MemberRole.rcChair],
  ),

  // Reports — web_admin + club_board
  WebNavItem(
    label: 'Reports',
    route: '/reports',
    icon: Icons.assessment,
    requiredRoles: [MemberRole.webAdmin, MemberRole.clubBoard],
    section: 'Reports',
  ),

  // Admin only — web_admin
  WebNavItem(
    label: 'Members',
    route: '/members',
    icon: Icons.badge,
    requiredRoles: [MemberRole.webAdmin],
    section: 'Admin',
  ),
  WebNavItem(
    label: 'Sync Dashboard',
    route: '/sync-dashboard',
    icon: Icons.sync,
    requiredRoles: [MemberRole.webAdmin],
  ),
  WebNavItem(
    label: 'System Settings',
    route: '/system-settings',
    icon: Icons.settings,
    requiredRoles: [MemberRole.webAdmin],
  ),

  // All web users
  WebNavItem(label: 'Profile', route: '/settings', icon: Icons.person),
];

class WebSidebar extends StatelessWidget {
  const WebSidebar({
    super.key,
    required this.activeRoute,
    required this.isCollapsed,
    required this.onSelected,
    required this.userRoles,
  });

  final String activeRoute;
  final bool isCollapsed;
  final ValueChanged<WebNavItem> onSelected;
  final List<MemberRole> userRoles;

  @override
  Widget build(BuildContext context) {
    final visibleItems = webNavItems.where((item) => item.isVisibleTo(userRoles)).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        for (final item in visibleItems)
          Tooltip(
            message: isCollapsed ? item.label : '',
            child: ListTile(
              selected: activeRoute == item.route,
              leading: Icon(item.icon),
              title: isCollapsed ? null : Text(item.label),
              onTap: () => onSelected(item),
            ),
          ),
      ],
    );
  }
}
