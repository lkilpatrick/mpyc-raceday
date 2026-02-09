import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/features/auth/presentation/mobile/login_screen.dart';
import 'package:mpyc_raceday/features/auth/presentation/mobile/verification_screen.dart';
import 'package:mpyc_raceday/features/checklists/presentation/mobile/active_checklist_screen.dart';
import 'package:mpyc_raceday/features/checklists/presentation/mobile/checklist_history_screen.dart';
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
import 'package:mpyc_raceday/features/weather/presentation/mobile/weather_dashboard_screen.dart';
import 'package:mpyc_raceday/features/weather/presentation/mobile/weather_history_screen.dart';
import 'package:mpyc_raceday/features/maintenance/presentation/mobile/maintenance_feed_screen.dart';
import 'package:mpyc_raceday/features/maintenance/presentation/mobile/maintenance_quick_report_screen.dart';
import 'package:mpyc_raceday/mobile/mobile_shell.dart';

final GoRouter mobileRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/verify';

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
      path: '/verify',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return VerificationScreen(
          maskedEmail: extra['maskedEmail'] as String? ?? '',
          memberId: extra['memberId'] as String? ?? '',
          memberNumber: extra['memberNumber'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MobileShell(initialIndex: 0),
    ),
    GoRoute(
      path: '/schedule',
      builder: (context, state) => const MobileShell(initialIndex: 1),
    ),
    GoRoute(
      path: '/checklists',
      builder: (context, state) => const MobileShell(initialIndex: 2),
    ),
    GoRoute(
      path: '/weather',
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
      path: '/weather',
      builder: (context, state) => const WeatherDashboardScreen(),
    ),
    GoRoute(
      path: '/weather/history/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return WeatherHistoryScreen(eventId: eventId);
      },
    ),
  ],
);
