import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/features/admin/presentation/web/member_management_page.dart';
import 'package:mpyc_raceday/features/admin/presentation/web/sync_dashboard_panel.dart';
import 'package:mpyc_raceday/features/auth/presentation/web/admin_profile_page.dart';
import 'package:mpyc_raceday/features/crew_assignment/presentation/web/crew_availability_page.dart';
import 'package:mpyc_raceday/features/crew_assignment/presentation/web/event_management_page.dart';
import 'package:mpyc_raceday/features/crew_assignment/presentation/web/season_calendar_page.dart';
import 'package:mpyc_raceday/shared/widgets/placeholder_page.dart';
import 'package:mpyc_raceday/web/layouts/web_scaffold.dart';
import 'package:mpyc_raceday/web/navigation/web_sidebar.dart';

class WebShell extends StatefulWidget {
  const WebShell({super.key, required this.activeRoute});

  final String activeRoute;

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  bool _isCollapsed = false;

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  Widget _buildBody() {
    switch (widget.activeRoute) {
      case '/season-calendar':
        return const SeasonCalendarPage();
      case '/crew-management':
        return const CrewAvailabilityPage();
      case '/sync-dashboard':
        return const SyncDashboardPanel();
      case '/members':
        return const MemberManagementPage();
      case '/race-events':
        return const EventManagementPage();
      case '/settings':
        return const AdminProfilePage();
      default:
        final activeItem = webNavItems.firstWhere(
          (item) => item.route == widget.activeRoute,
          orElse: () => webNavItems.first,
        );
        return PlaceholderPage(
          title: activeItem.label,
          subtitle: 'Web admin dashboard',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeItem = webNavItems.firstWhere(
      (item) => item.route == widget.activeRoute,
      orElse: () => webNavItems.first,
    );

    return WebScaffold(
      title: 'MPYC Admin',
      isSidebarCollapsed: _isCollapsed,
      onToggleSidebar: _toggleSidebar,
      sidebar: WebSidebar(
        activeRoute: activeItem.route,
        isCollapsed: _isCollapsed,
        onSelected: (item) => context.go(item.route),
      ),
      body: _buildBody(),
    );
  }
}
