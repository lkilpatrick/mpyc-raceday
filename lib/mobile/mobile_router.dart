import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/features/auth/presentation/mobile/login_screen.dart';
import 'package:mpyc_raceday/features/checklists/presentation/mobile/active_checklist_screen.dart';
import 'package:mpyc_raceday/features/checklists/presentation/mobile/checklist_history_screen.dart';
import 'package:mpyc_raceday/features/checklists/presentation/mobile/checklist_list_screen.dart';
import 'package:mpyc_raceday/features/crew_assignment/presentation/mobile/event_detail_screen.dart';
import 'package:mpyc_raceday/features/maintenance/presentation/mobile/maintenance_detail_screen.dart';
import 'package:mpyc_raceday/features/racing_rules/presentation/mobile/definitions_screen.dart';
import 'package:mpyc_raceday/features/racing_rules/presentation/mobile/rule_detail_screen.dart';
import 'package:mpyc_raceday/features/racing_rules/presentation/mobile/rules_home_screen.dart';
import 'package:mpyc_raceday/features/racing_rules/presentation/mobile/situation_advisor_screen.dart';
import 'package:mpyc_raceday/features/timing/presentation/mobile/finish_recording_screen.dart';
import 'package:mpyc_raceday/features/timing/presentation/mobile/start_sequence_screen.dart';
import 'package:mpyc_raceday/features/timing/presentation/mobile/timing_dashboard_screen.dart';
import 'package:mpyc_raceday/features/timing/presentation/mobile/timing_results_screen.dart';
import 'package:mpyc_raceday/features/weather/presentation/mobile/weather_history_screen.dart';
import 'package:mpyc_raceday/features/courses/presentation/mobile/course_selection_screen.dart';
import 'package:mpyc_raceday/features/courses/presentation/mobile/course_display_screen.dart';
import 'package:mpyc_raceday/features/courses/presentation/mobile/fleet_broadcast_screen.dart';
import 'package:mpyc_raceday/features/boat_checkin/presentation/mobile/boat_checkin_screen.dart';
import 'package:mpyc_raceday/features/incidents/presentation/mobile/quick_incident_screen.dart';
import 'package:mpyc_raceday/features/incidents/presentation/mobile/incident_list_screen.dart';
import 'package:mpyc_raceday/features/incidents/presentation/mobile/incident_detail_screen.dart';
import 'package:mpyc_raceday/features/maintenance/presentation/mobile/maintenance_feed_screen.dart';
import 'package:mpyc_raceday/features/maintenance/presentation/mobile/maintenance_quick_report_screen.dart';
import 'package:mpyc_raceday/features/auth/presentation/mobile/profile_screen.dart';
import 'package:mpyc_raceday/features/weather/presentation/mobile/live_wind_screen.dart';
import 'package:mpyc_raceday/features/race_mode/presentation/mobile/race_mode_screen.dart';
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/mode_switcher_screen.dart';
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/crew_dashboard_screen.dart';
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/crew_chat_screen.dart';
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/crew_safety_screen.dart';
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/spectator_screen.dart';
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/leaderboard_screen.dart';
import 'package:mpyc_raceday/features/skipper/presentation/mobile/skipper_checkin_screen.dart';
import 'package:mpyc_raceday/features/skipper/presentation/mobile/skipper_race_screen.dart';
import 'package:mpyc_raceday/features/skipper/presentation/mobile/skipper_results_screen.dart';
import 'package:mpyc_raceday/features/skipper/presentation/mobile/skipper_incident_screen.dart';
import 'package:mpyc_raceday/features/skipper/presentation/mobile/racing_rules_reference_screen.dart';
import 'package:mpyc_raceday/features/crew/presentation/mobile/crew_profile_screen.dart';
import 'package:mpyc_raceday/features/crew/presentation/mobile/crew_incident_screen.dart';
import 'package:mpyc_raceday/features/demo/presentation/demo_mode_screen.dart';
import 'package:mpyc_raceday/features/rc_race/presentation/mobile/rc_race_flow_screen.dart';
import 'package:mpyc_raceday/features/rc_race/presentation/mobile/rc_race_history_screen.dart';
import 'package:mpyc_raceday/mobile/mobile_shell.dart';

final GoRouter mobileRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/login';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && state.matchedLocation == '/login') return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MobileShell(initialIndex: 0),
    ),
    GoRoute(
      path: '/course',
      builder: (context, state) => const MobileShell(initialIndex: 1),
    ),
    GoRoute(
      path: '/weather',
      builder: (context, state) => const MobileShell(initialIndex: 2),
    ),
    GoRoute(
      path: '/report',
      builder: (context, state) => const MobileShell(initialIndex: 3),
    ),
    GoRoute(
      path: '/more',
      builder: (context, state) => const MobileShell(initialIndex: 4),
    ),
    GoRoute(
      path: '/schedule/event/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return EventDetailScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/checklists',
      builder: (context, state) => const ChecklistListScreen(),
    ),
    GoRoute(
      path: '/checklists/active/:completionId',
      builder: (context, state) {
        final completionId = state.pathParameters['completionId']!;
        return ActiveChecklistScreen(completionId: completionId);
      },
    ),
    GoRoute(
      path: '/checklists/history',
      builder: (context, state) => const ChecklistHistoryScreen(),
    ),
    GoRoute(
      path: '/maintenance/report',
      builder: (context, state) => const MaintenanceQuickReportScreen(),
    ),
    GoRoute(
      path: '/maintenance/feed',
      builder: (context, state) => const MaintenanceFeedScreen(),
    ),
    GoRoute(
      path: '/maintenance/detail/:requestId',
      builder: (context, state) {
        final requestId = state.pathParameters['requestId']!;
        return MaintenanceDetailScreen(requestId: requestId);
      },
    ),
    GoRoute(
      path: '/rules',
      builder: (context, state) => const RulesHomeScreen(),
    ),
    GoRoute(
      path: '/rules/detail/:ruleNumber',
      builder: (context, state) {
        final ruleNumber = state.pathParameters['ruleNumber']!;
        return RuleDetailScreen(ruleNumber: ruleNumber);
      },
    ),
    GoRoute(
      path: '/rules/advisor',
      builder: (context, state) => const SituationAdvisorScreen(),
    ),
    GoRoute(
      path: '/rules/definitions',
      builder: (context, state) => const DefinitionsScreen(),
    ),
    GoRoute(
      path: '/timing/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return TimingDashboardScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/timing/start/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return StartSequenceScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/timing/finish/:raceStartId',
      builder: (context, state) {
        final raceStartId = state.pathParameters['raceStartId']!;
        return FinishRecordingScreen(raceStartId: raceStartId);
      },
    ),
    GoRoute(
      path: '/timing/results/:raceStartId',
      builder: (context, state) {
        final raceStartId = state.pathParameters['raceStartId']!;
        return TimingResultsScreen(raceStartId: raceStartId);
      },
    ),
    GoRoute(
      path: '/weather/history/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return WeatherHistoryScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/courses/select/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return CourseSelectionScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/courses/display/:courseId',
      builder: (context, state) {
        final courseId = state.pathParameters['courseId']!;
        return CourseDisplayScreen(courseId: courseId);
      },
    ),
    GoRoute(
      path: '/courses/broadcast/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return FleetBroadcastScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/checkin/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return BoatCheckinScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/live-wind',
      builder: (context, state) => const LiveWindScreen(),
    ),
    GoRoute(
      path: '/incidents/browse',
      builder: (context, state) => const IncidentListScreen(eventId: ''),
    ),
    GoRoute(
      path: '/incidents/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return IncidentListScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/incidents/report/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return QuickIncidentScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/incidents/detail/:incidentId',
      builder: (context, state) {
        final incidentId = state.pathParameters['incidentId']!;
        return IncidentDetailScreen(incidentId: incidentId);
      },
    ),
    GoRoute(
      path: '/race-mode',
      builder: (context, state) => const RaceModeScreen(),
    ),
    GoRoute(
      path: '/mode-switcher',
      builder: (context, state) => const ModeSwitcherScreen(),
    ),
    GoRoute(
      path: '/crew-dashboard',
      builder: (context, state) => const CrewDashboardScreen(),
    ),
    GoRoute(
      path: '/crew-chat',
      builder: (context, state) => const CrewChatScreen(),
    ),
    GoRoute(
      path: '/crew-safety',
      builder: (context, state) => const CrewSafetyScreen(),
    ),
    GoRoute(
      path: '/spectator',
      builder: (context, state) => const SpectatorScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/skipper-checkin/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return SkipperCheckinScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/skipper-race/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return SkipperRaceScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/skipper-results',
      builder: (context, state) => const SkipperResultsScreen(),
    ),
    GoRoute(
      path: '/skipper-incident',
      builder: (context, state) => const SkipperIncidentScreen(),
    ),
    GoRoute(
      path: '/rules/reference',
      builder: (context, state) => const RacingRulesReferenceScreen(),
    ),
    GoRoute(
      path: '/demo',
      builder: (context, state) => const DemoModeScreen(),
    ),
    GoRoute(
      path: '/rc-race/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return RcRaceFlowScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/rc-race-history',
      builder: (context, state) => const RcRaceHistoryScreen(),
    ),
    // Shell routes for mode-specific bottom nav tabs
    GoRoute(
      path: '/rc-timing',
      builder: (context, state) => const MobileShell(initialIndex: 2),
    ),
    // Skipper mode shell tabs
    GoRoute(
      path: '/skipper-home',
      builder: (context, state) => const MobileShell(initialIndex: 0),
    ),
    GoRoute(
      path: '/skipper-results-tab',
      builder: (context, state) => const MobileShell(initialIndex: 2),
    ),
    GoRoute(
      path: '/rules-tab',
      builder: (context, state) => const MobileShell(initialIndex: 3),
    ),
    // Crew mode shell tabs
    GoRoute(
      path: '/crew-home',
      builder: (context, state) => const MobileShell(initialIndex: 0),
    ),
    GoRoute(
      path: '/crew-rules-tab',
      builder: (context, state) => const MobileShell(initialIndex: 1),
    ),
    // Crew push routes
    GoRoute(
      path: '/crew-profile',
      builder: (context, state) => const CrewProfileScreen(),
    ),
    GoRoute(
      path: '/crew-incident',
      builder: (context, state) => const CrewIncidentScreen(),
    ),
  ],
);
