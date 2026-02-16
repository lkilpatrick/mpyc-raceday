import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/features/auth/presentation/web/no_access_page.dart';
import 'package:mpyc_raceday/features/auth/presentation/web/web_login_page.dart';
import 'package:mpyc_raceday/features/race_mode/presentation/race_replay_viewer.dart';
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
        GoRoute(path: '/dashboard', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/season-calendar', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/crew-management', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/members', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/sync-dashboard', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/race-events', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/courses', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/checklists-admin', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/checklists-history', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/checklists-compliance', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/maintenance', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/maintenance-manage', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/maintenance-schedule', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/maintenance-reports', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/rules-reference', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/course-config', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/fleet-broadcasts', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/incidents', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/fleet-management', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/event-checkins', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/weather-logs', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/weather-analytics', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/reports', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/system-settings', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/situation-advisor', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/settings', builder: (context, state) => const SizedBox()),
        GoRoute(
          path: '/race-replay/:eventId',
          builder: (context, state) {
            final eventId = state.pathParameters['eventId']!;
            final name = state.uri.queryParameters['name'] ?? 'Race Replay';
            return RaceReplayViewer(
              eventId: eventId,
              eventName: name,
              embedded: true,
            );
          },
        ),
        GoRoute(
          path: '/race-live-delayed/:eventId',
          builder: (context, state) {
            final eventId = state.pathParameters['eventId']!;
            final name = state.uri.queryParameters['name'] ?? 'Delayed Live';
            return RaceReplayViewer(
              eventId: eventId,
              eventName: name,
              embedded: true,
              delayDuration: const Duration(minutes: 5),
            );
          },
        ),
      ],
    ),
  ],
);
