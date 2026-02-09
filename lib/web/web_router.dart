import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/web/web_shell.dart';

final GoRouter webRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const WebShell(activeRoute: '/dashboard'),
    ),
    GoRoute(
      path: '/season-calendar',
      builder: (context, state) =>
          const WebShell(activeRoute: '/season-calendar'),
    ),
    GoRoute(
      path: '/crew-management',
      builder: (context, state) =>
          const WebShell(activeRoute: '/crew-management'),
    ),
    GoRoute(
      path: '/members',
      builder: (context, state) => const WebShell(activeRoute: '/members'),
    ),
    GoRoute(
      path: '/sync-dashboard',
      builder: (context, state) =>
          const WebShell(activeRoute: '/sync-dashboard'),
    ),
    GoRoute(
      path: '/race-events',
      builder: (context, state) => const WebShell(activeRoute: '/race-events'),
    ),
    GoRoute(
      path: '/courses',
      builder: (context, state) => const WebShell(activeRoute: '/courses'),
    ),
    GoRoute(
      path: '/checklists-admin',
      builder: (context, state) =>
          const WebShell(activeRoute: '/checklists-admin'),
    ),
    GoRoute(
      path: '/maintenance',
      builder: (context, state) => const WebShell(activeRoute: '/maintenance'),
    ),
    GoRoute(
      path: '/incidents',
      builder: (context, state) => const WebShell(activeRoute: '/incidents'),
    ),
    GoRoute(
      path: '/weather-logs',
      builder: (context, state) => const WebShell(activeRoute: '/weather-logs'),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const WebShell(activeRoute: '/reports'),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const WebShell(activeRoute: '/settings'),
    ),
  ],
);
