import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';

/// Mirrors the _routeRoles map and _hasRouteAccess logic from WebShell.
/// Kept in sync to test route-level RBAC without widget dependencies.
const _routeRoles = <String, List<MemberRole>?>{
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

bool hasRouteAccess(String route, List<MemberRole> userRoles) {
  final allowed = _routeRoles[route];
  if (allowed == null) return true; // null = any web user
  return userRoles.any((r) => allowed.contains(r) || r == MemberRole.webAdmin);
}

void main() {
  group('Route access — web_admin', () {
    const roles = [MemberRole.webAdmin];

    test('can access all routes', () {
      for (final route in _routeRoles.keys) {
        expect(hasRouteAccess(route, roles), true,
            reason: 'web_admin should access $route');
      }
    });

    test('can access unknown route (defaults to true)', () {
      expect(hasRouteAccess('/unknown', roles), true);
    });
  });

  group('Route access — rc_chair', () {
    const roles = [MemberRole.rcChair];

    test('can access public routes', () {
      expect(hasRouteAccess('/dashboard', roles), true);
      expect(hasRouteAccess('/season-calendar', roles), true);
      expect(hasRouteAccess('/settings', roles), true);
    });

    test('can access race operations', () {
      expect(hasRouteAccess('/race-events', roles), true);
      expect(hasRouteAccess('/crew-management', roles), true);
      expect(hasRouteAccess('/courses', roles), true);
      expect(hasRouteAccess('/incidents', roles), true);
      expect(hasRouteAccess('/fleet-management', roles), true);
      expect(hasRouteAccess('/event-checkins', roles), true);
    });

    test('can access maintenance', () {
      expect(hasRouteAccess('/maintenance', roles), true);
      expect(hasRouteAccess('/maintenance-manage', roles), true);
      expect(hasRouteAccess('/maintenance-schedule', roles), true);
    });

    test('cannot access admin-only routes', () {
      expect(hasRouteAccess('/members', roles), false);
      expect(hasRouteAccess('/sync-dashboard', roles), false);
      expect(hasRouteAccess('/system-settings', roles), false);
    });

    test('cannot access reports (club_board only)', () {
      expect(hasRouteAccess('/reports', roles), false);
    });
  });

  group('Route access — club_board', () {
    const roles = [MemberRole.clubBoard];

    test('can access public routes', () {
      expect(hasRouteAccess('/dashboard', roles), true);
      expect(hasRouteAccess('/season-calendar', roles), true);
      expect(hasRouteAccess('/settings', roles), true);
    });

    test('can access reports', () {
      expect(hasRouteAccess('/reports', roles), true);
    });

    test('cannot access race operations', () {
      expect(hasRouteAccess('/race-events', roles), false);
      expect(hasRouteAccess('/incidents', roles), false);
      expect(hasRouteAccess('/fleet-management', roles), false);
    });

    test('cannot access admin-only routes', () {
      expect(hasRouteAccess('/members', roles), false);
      expect(hasRouteAccess('/sync-dashboard', roles), false);
      expect(hasRouteAccess('/system-settings', roles), false);
    });

    test('cannot access maintenance', () {
      expect(hasRouteAccess('/maintenance', roles), false);
      expect(hasRouteAccess('/maintenance-manage', roles), false);
    });
  });

  group('Route access — multi-role', () {
    test('rc_chair + club_board can access both race ops and reports', () {
      const roles = [MemberRole.rcChair, MemberRole.clubBoard];
      expect(hasRouteAccess('/race-events', roles), true);
      expect(hasRouteAccess('/reports', roles), true);
      expect(hasRouteAccess('/incidents', roles), true);
    });

    test('rc_chair + club_board still cannot access admin-only', () {
      const roles = [MemberRole.rcChair, MemberRole.clubBoard];
      expect(hasRouteAccess('/members', roles), false);
      expect(hasRouteAccess('/system-settings', roles), false);
    });
  });

  group('Route access — no roles (empty list)', () {
    const roles = <MemberRole>[];

    test('can access public routes', () {
      expect(hasRouteAccess('/dashboard', roles), true);
      expect(hasRouteAccess('/season-calendar', roles), true);
    });

    test('cannot access restricted routes', () {
      expect(hasRouteAccess('/race-events', roles), false);
      expect(hasRouteAccess('/reports', roles), false);
      expect(hasRouteAccess('/members', roles), false);
    });
  });

  group('Route access — unknown routes', () {
    test('unknown route returns true (not in map, allowed == null)', () {
      expect(hasRouteAccess('/nonexistent', [MemberRole.crew]), true);
      expect(hasRouteAccess('/foo', [MemberRole.skipper]), true);
    });
  });

  group('Route map completeness', () {
    test('all expected routes are in the map', () {
      final expectedRoutes = [
        '/dashboard',
        '/season-calendar',
        '/settings',
        '/race-events',
        '/crew-management',
        '/courses',
        '/course-config',
        '/checklists-admin',
        '/checklists-history',
        '/checklists-compliance',
        '/incidents',
        '/rules-reference',
        '/situation-advisor',
        '/weather-logs',
        '/weather-analytics',
        '/fleet-broadcasts',
        '/fleet-management',
        '/event-checkins',
        '/maintenance',
        '/maintenance-manage',
        '/maintenance-schedule',
        '/maintenance-reports',
        '/reports',
        '/members',
        '/sync-dashboard',
        '/system-settings',
      ];

      for (final route in expectedRoutes) {
        expect(_routeRoles.containsKey(route), true,
            reason: 'Missing route: $route');
      }
    });

    test('admin-only routes require exactly webAdmin', () {
      final adminOnlyRoutes = ['/members', '/sync-dashboard', '/system-settings'];
      for (final route in adminOnlyRoutes) {
        final allowed = _routeRoles[route]!;
        expect(allowed, [MemberRole.webAdmin],
            reason: '$route should be admin-only');
      }
    });
  });
}
