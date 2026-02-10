import 'package:flutter/material.dart';
import 'package:mpyc_raceday/core/theme.dart';
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
    label: 'Racing Rules',
    route: '/rules-reference',
    icon: Icons.gavel,
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
    section: 'Fleet Maintenance',
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
    section: 'Administration',
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
    this.onSignOut,
  });

  final String activeRoute;
  final bool isCollapsed;
  final ValueChanged<WebNavItem> onSelected;
  final List<MemberRole> userRoles;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final visibleItems = webNavItems.where((item) => item.isVisibleTo(userRoles)).toList();

    // Build widgets with section headers
    final widgets = <Widget>[];
    String? lastSection;

    for (final item in visibleItems) {
      // Insert section header when section changes
      if (item.section != null && item.section != lastSection) {
        lastSection = item.section;
        if (!isCollapsed) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 20, bottom: 6, right: 16),
              child: Text(
                item.section!.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          );
        } else {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(height: 1, color: Colors.white.withAlpha(30)),
            ),
          );
        }
      }

      final isActive = activeRoute == item.route;

      widgets.add(
        Tooltip(
          message: isCollapsed ? item.label : '',
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: isActive ? AppColors.sidebarSelected : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? const Border(
                      left: BorderSide(color: AppColors.accent, width: 3),
                    )
                  : null,
            ),
            child: ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -1),
              leading: Icon(
                item.icon,
                size: 20,
                color: isActive ? AppColors.accent : Colors.white60,
              ),
              title: isCollapsed
                  ? null
                  : Text(
                      item.label,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
              onTap: () => onSelected(item),
              hoverColor: AppColors.sidebarSelected.withAlpha(120),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: widgets,
          ),
        ),
        if (onSignOut != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Divider(height: 1, color: Colors.white.withAlpha(30)),
          ),
          Tooltip(
            message: isCollapsed ? 'Sign Out' : '',
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -1),
                leading: const Icon(Icons.logout, size: 20, color: Colors.red),
                title: isCollapsed
                    ? null
                    : const Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                onTap: onSignOut,
                hoverColor: Colors.red.withAlpha(30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
