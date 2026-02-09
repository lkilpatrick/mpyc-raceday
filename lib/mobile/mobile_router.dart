import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/features/crew_assignment/presentation/mobile/event_detail_screen.dart';
import 'package:mpyc_raceday/mobile/mobile_shell.dart';

final GoRouter mobileRouter = GoRouter(
  initialLocation: '/home',
  routes: [
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
  ],
);
