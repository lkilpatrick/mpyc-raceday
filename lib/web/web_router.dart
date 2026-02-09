import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    ShellRoute(
      builder: (context, state, child) {
        return WebShell(
          activeRoute: state.matchedLocation,
          child: child,
        );
      },
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/season-calendar', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/crew-management', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/members', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/sync-dashboard', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/race-events', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/courses', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/checklists-admin', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/checklists-history', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/checklists-compliance', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/maintenance', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/maintenance-manage', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/maintenance-schedule', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/maintenance-reports', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/rules-reference', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/course-config', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/fleet-broadcasts', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/incidents', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/fleet-management', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/event-checkins', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/weather-logs', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/weather-analytics', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/reports', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/system-settings', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
      ],
    ),
  ],
);
