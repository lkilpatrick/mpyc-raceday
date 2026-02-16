import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/features/admin/presentation/web/member_management_page.dart';
import 'package:mpyc_raceday/features/admin/presentation/web/sync_dashboard_panel.dart';
import 'package:mpyc_raceday/features/auth/data/auth_providers.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';
import 'package:mpyc_raceday/features/auth/presentation/web/admin_profile_page.dart';
import 'package:mpyc_raceday/features/checklists/presentation/web/checklist_compliance_dashboard.dart';
import 'package:mpyc_raceday/features/checklists/presentation/web/checklist_completion_history_page.dart';
import 'package:mpyc_raceday/features/checklists/presentation/web/checklist_templates_page.dart';
import 'package:mpyc_raceday/features/maintenance/presentation/web/maintenance_dashboard_page.dart';
import 'package:mpyc_raceday/features/maintenance/presentation/web/maintenance_management_page.dart';
import 'package:mpyc_raceday/features/maintenance/presentation/web/maintenance_reports_panel.dart';
import 'package:mpyc_raceday/features/maintenance/presentation/web/maintenance_schedule_page.dart';
import 'package:mpyc_raceday/features/racing_rules/presentation/web/rules_reference_page.dart';
import 'package:mpyc_raceday/features/racing_rules/presentation/web/situation_advisor_page.dart';
import 'package:mpyc_raceday/features/weather/presentation/web/weather_analytics_panel.dart';
import 'package:mpyc_raceday/features/weather/presentation/web/weather_log_page.dart';
import 'package:mpyc_raceday/features/boat_checkin/presentation/web/fleet_management_page.dart';
import 'package:mpyc_raceday/features/boat_checkin/presentation/web/event_checkin_page.dart';
import 'package:mpyc_raceday/features/incidents/presentation/web/incident_management_page.dart';
import 'package:mpyc_raceday/features/admin/presentation/web/admin_dashboard_page.dart';
import 'package:mpyc_raceday/features/admin/presentation/web/system_settings_page.dart';
import 'package:mpyc_raceday/features/reports/presentation/web/reports_page.dart';
import 'package:mpyc_raceday/features/crew_assignment/presentation/web/crew_availability_page.dart';
import 'package:mpyc_raceday/features/crew_assignment/presentation/web/event_management_page.dart';
import 'package:mpyc_raceday/features/crew_assignment/presentation/web/season_calendar_page.dart';
import 'package:mpyc_raceday/features/courses/presentation/web/course_configuration_page.dart';
import 'package:mpyc_raceday/features/courses/presentation/web/course_sheet_page.dart';
import 'package:mpyc_raceday/features/courses/presentation/web/fleet_broadcast_history_page.dart';
import 'package:mpyc_raceday/shared/widgets/placeholder_page.dart';
import 'package:mpyc_raceday/web/layouts/web_scaffold.dart';
import 'package:mpyc_raceday/web/navigation/web_sidebar.dart';

class WebShell extends ConsumerStatefulWidget {
  const WebShell({super.key, required this.activeRoute, required this.child});

  final String activeRoute;
  final Widget child;

  @override
  ConsumerState<WebShell> createState() => _WebShellState();
}

class _WebShellState extends ConsumerState<WebShell> {
  bool _isCollapsed = false;
  bool _autoCollapsed = false;

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      _autoCollapsed = false; // manual override
    });
  }

  // Route-level RBAC: maps every route to the roles that can access it.
  // null = any authenticated web user; empty list would deny all (not used).
  static const _routeRoles = <String, List<MemberRole>?>{
    '/dashboard': null,
    '/season-calendar': null,
    '/settings': null,
    // Race operations — web_admin + rc_chair
    '/race-events': [MemberRole.webAdmin, MemberRole.rcChair],
    '/crew-management': [MemberRole.webAdmin, MemberRole.rcChair],
    '/courses': [MemberRole.webAdmin, MemberRole.rcChair],
    '/course-config': [MemberRole.webAdmin, MemberRole.rcChair],
    '/checklists-admin': [MemberRole.webAdmin, MemberRole.rcChair],
    '/checklists-history': [MemberRole.webAdmin, MemberRole.rcChair],
    '/checklists-compliance': [MemberRole.webAdmin, MemberRole.rcChair],
    '/incidents': [MemberRole.webAdmin, MemberRole.rcChair],
    '/rules-reference': [MemberRole.webAdmin, MemberRole.rcChair],
    '/situation-advisor': [MemberRole.webAdmin, MemberRole.rcChair],
    '/weather-logs': [MemberRole.webAdmin, MemberRole.rcChair],
    '/weather-analytics': [MemberRole.webAdmin, MemberRole.rcChair],
    '/fleet-broadcasts': [MemberRole.webAdmin, MemberRole.rcChair],
    '/fleet-management': [MemberRole.webAdmin, MemberRole.rcChair],
    '/event-checkins': [MemberRole.webAdmin, MemberRole.rcChair],
    // Maintenance — web_admin + rc_chair
    '/maintenance': [MemberRole.webAdmin, MemberRole.rcChair],
    '/maintenance-manage': [MemberRole.webAdmin, MemberRole.rcChair],
    '/maintenance-schedule': [MemberRole.webAdmin, MemberRole.rcChair],
    '/maintenance-reports': [MemberRole.webAdmin, MemberRole.rcChair],
    // Reports — web_admin + club_board
    '/reports': [MemberRole.webAdmin, MemberRole.clubBoard],
    // Admin only
    '/members': [MemberRole.webAdmin],
    '/sync-dashboard': [MemberRole.webAdmin],
    '/system-settings': [MemberRole.webAdmin],
  };

  bool _hasRouteAccess(String route, List<MemberRole> userRoles) {
    final allowed = _routeRoles[route];
    if (allowed == null) return true; // null = any web user
    return userRoles.any((r) =>
        allowed.contains(r) || r == MemberRole.webAdmin);
  }

  Widget _buildBody() {
    // Route-level role enforcement
    final userRoles = ref.read(currentRolesProvider);
    if (!_hasRouteAccess(widget.activeRoute, userRoles)) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('You do not have permission to access this page.',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

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
      case '/checklists-admin':
        return const ChecklistTemplatesPage();
      case '/checklists-history':
        return const ChecklistCompletionHistoryPage();
      case '/checklists-compliance':
        return const ChecklistComplianceDashboard();
      case '/maintenance':
        return const MaintenanceDashboardPage();
      case '/maintenance-manage':
        return const MaintenanceManagementPage();
      case '/maintenance-schedule':
        return const MaintenanceSchedulePage();
      case '/maintenance-reports':
        return const MaintenanceReportsPanel();
      case '/rules-reference':
        return const RulesReferencePage();
      case '/situation-advisor':
        return const SituationAdvisorPage();
      case '/courses':
        return const CourseSheetPage();
      case '/course-config':
        return const CourseConfigurationPage();
      case '/fleet-broadcasts':
        return const FleetBroadcastHistoryPage();
      case '/fleet-management':
        return const FleetManagementPage();
      case '/event-checkins':
        return const EventCheckinPage();
      case '/incidents':
        return const IncidentManagementPage();
      case '/dashboard':
        return const AdminDashboardPage();
      case '/reports':
        return const ReportsPage();
      case '/system-settings':
        return const SystemSettingsPage();
      case '/weather-logs':
        return const WeatherLogPage();
      case '/weather-analytics':
        return const WeatherAnalyticsPanel();
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

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    if (!mounted) return;

    await ref.read(authRepositoryProvider).signOut();
    
    if (!mounted) return;
    context.go('/web-login');
  }

  @override
  Widget build(BuildContext context) {
    final userRoles = ref.watch(currentRolesProvider);
    final memberAsync = ref.watch(currentUserProvider);

    // Role guard: once member data loads, verify web dashboard access
    final member = memberAsync.value;
    if (member != null && !member.canAccessWebDashboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/no-access');
      });
      return const SizedBox.shrink();
    }

    // Auto-collapse sidebar on tablet-width screens (<1024px)
    final width = MediaQuery.sizeOf(context).width;
    if (width < 1024 && !_isCollapsed && !_autoCollapsed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() { _isCollapsed = true; _autoCollapsed = true; });
      });
    } else if (width >= 1024 && _autoCollapsed && _isCollapsed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() { _isCollapsed = false; _autoCollapsed = false; });
      });
    }

    final activeItem = webNavItems.firstWhere(
      (item) => item.route == widget.activeRoute,
      orElse: () => webNavItems.first,
    );

    final userName = member != null
        ? '${member.firstName} ${member.lastName}'.trim()
        : null;
    final userInitials = member != null
        ? '${member.firstName.isNotEmpty ? member.firstName[0] : ''}${member.lastName.isNotEmpty ? member.lastName[0] : ''}'
        : null;

    return WebScaffold(
      title: 'MPYC Admin',
      isSidebarCollapsed: _isCollapsed,
      onToggleSidebar: _toggleSidebar,
      userName: userName,
      userInitials: userInitials,
      onSignOut: _handleSignOut,
      sidebar: WebSidebar(
        activeRoute: activeItem.route,
        isCollapsed: _isCollapsed,
        onSelected: (item) => context.go(item.route),
        userRoles: userRoles,
        onSignOut: _handleSignOut,
      ),
      body: _buildBody(),
    );
  }
}
