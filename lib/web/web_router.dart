import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/features/auth/presentation/web/no_access_page.dart';
import 'package:mpyc_raceday/features/auth/presentation/web/web_login_page.dart';
import 'package:mpyc_raceday/web/web_shell.dart';

final GoRouter webRouter = GoRouter(
  initialLocation: '/dashboard',
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/web-login' ||
        state.matchedLocation == '/no-access';

    if (!isLoggedIn && !isAuthRoute) return '/web-login';
    if (isLoggedIn && state.matchedLocation == '/web-login') return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(
      path: '/web-login',
      builder: (context, state) => const WebLoginPage(),
    ),
    GoRoute(
      path: '/no-access',
      builder: (context, state) => const NoAccessPage(),
    ),
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
      path: '/checklists-history',
      builder: (context, state) =>
          const WebShell(activeRoute: '/checklists-history'),
    ),
    GoRoute(
      path: '/checklists-compliance',
      builder: (context, state) =>
          const WebShell(activeRoute: '/checklists-compliance'),
    ),
    GoRoute(
      path: '/maintenance',
      builder: (context, state) => const WebShell(activeRoute: '/maintenance'),
    ),
    GoRoute(
      path: '/maintenance-manage',
      builder: (context, state) =>
          const WebShell(activeRoute: '/maintenance-manage'),
    ),
    GoRoute(
      path: '/maintenance-schedule',
      builder: (context, state) =>
          const WebShell(activeRoute: '/maintenance-schedule'),
    ),
    GoRoute(
      path: '/maintenance-reports',
      builder: (context, state) =>
          const WebShell(activeRoute: '/maintenance-reports'),
    ),
    GoRoute(
      path: '/rules-reference',
      builder: (context, state) =>
          const WebShell(activeRoute: '/rules-reference'),
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
