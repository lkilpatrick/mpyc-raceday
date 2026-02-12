import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/features/app_mode/data/app_mode.dart';
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/mode_nav_config.dart';
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/rc_home_screen.dart';
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/rc_timing_screen.dart';
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/crew_dashboard_screen.dart';
// crew_chat_screen removed — chat not needed in any mode
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/crew_safety_screen.dart';
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/spectator_screen.dart';
import 'package:mpyc_raceday/features/app_mode/presentation/mobile/leaderboard_screen.dart';
import 'package:mpyc_raceday/features/home/presentation/mobile/home_screen.dart';
import 'package:mpyc_raceday/features/home/presentation/mobile/more_screen.dart';
import 'package:mpyc_raceday/features/courses/presentation/mobile/course_tab_screen.dart';
import 'package:mpyc_raceday/features/race_mode/presentation/mobile/race_mode_screen.dart';
import 'package:mpyc_raceday/features/racing_rules/presentation/mobile/situation_advisor_screen.dart';
import 'package:mpyc_raceday/features/reporting/presentation/mobile/report_tab_screen.dart';
import 'package:mpyc_raceday/features/skipper/presentation/mobile/skipper_home_screen.dart';
import 'package:mpyc_raceday/features/skipper/presentation/mobile/skipper_race_tab.dart';
import 'package:mpyc_raceday/features/skipper/presentation/mobile/skipper_results_screen.dart';
import 'package:mpyc_raceday/features/skipper/presentation/mobile/racing_rules_reference_screen.dart';
import 'package:mpyc_raceday/features/crew/presentation/mobile/crew_home_screen.dart';
import 'package:mpyc_raceday/mobile/layouts/mobile_scaffold.dart';
import 'package:mpyc_raceday/features/weather/presentation/mobile/weather_dashboard_screen.dart';
import 'package:mpyc_raceday/shared/widgets/placeholder_page.dart';

class MobileShell extends ConsumerStatefulWidget {
  const MobileShell({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  ConsumerState<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<MobileShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant MobileShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _index = widget.initialIndex;
      });
    }
  }

  void _onTap(int index, List<ModeNavItem> navItems) {
    if (index == _index) return;
    setState(() => _index = index);
    // Navigate to the route for this mode's tab
    final route = navItems[index].route;
    context.go(route);
  }

  Widget _screenForRoute(String route) => switch (route) {
        '/home' => const HomeScreen(),
        '/rc-home' => const RcHomeScreen(),
        '/course' => const CourseTabScreen(),
        '/weather' => const WeatherDashboardScreen(),
        '/report' => const ReportTabScreen(),
        '/more' => const MoreScreen(),
        '/rc-timing' => const RcTimingScreen(),
        '/race-mode' => const RaceModeScreen(embedded: true),
        '/rules/advisor' => const SituationAdvisorScreen(),
        '/crew-dashboard' => const CrewDashboardScreen(),
        // crew-chat removed
        '/crew-safety' => const CrewSafetyScreen(),
        '/spectator' => const SpectatorScreen(),
        '/leaderboard' => const LeaderboardScreen(),
        '/skipper-home' => const SkipperHomeScreen(),
        '/skipper-race-tab' => const SkipperRaceTab(),
        '/skipper-results-tab' => const SkipperResultsScreen(embedded: true),
        '/rules-tab' => const RacingRulesReferenceScreen(embedded: true),
        '/crew-home' => const CrewHomeScreen(),
        '/crew-rules-tab' => const RacingRulesReferenceScreen(embedded: true),
        _ => PlaceholderPage(title: route, subtitle: 'Coming soon'),
      };

  @override
  Widget build(BuildContext context) {
    final modeAsync = ref.watch(appModeProvider);
    final mode = modeAsync.value ?? currentAppMode();
    final navItems = navItemsForMode(mode);

    // Clamp index to valid range
    final safeIndex = _index.clamp(0, navItems.length - 1);
    final item = navItems[safeIndex];
    final body = _screenForRoute(item.route);

    return MobileScaffold(
      title: item.label,
      appBarColor: mode.color,
      body: Column(
        children: [
          // Mode indicator bar
          _ModeIndicatorBar(mode: mode),
          // RACE ACTIVE banner
          const _RaceActiveBanner(),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: safeIndex,
        onTap: (i) => _onTap(i, navItems),
        selectedItemColor: mode.color,
        items: [
          for (final nav in navItems)
            BottomNavigationBarItem(icon: Icon(nav.icon), label: nav.label),
        ],
      ),
    );
  }
}

class _ModeIndicatorBar extends StatelessWidget {
  const _ModeIndicatorBar({required this.mode});
  final AppMode mode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: mode.color.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => context.push('/mode-switcher'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(mode.icon, size: 14, color: mode.color),
              const SizedBox(width: 6),
              Text(
                '${mode.label} Mode',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: mode.color,
                ),
              ),
              const Spacer(),
              Text('Switch',
                  style: TextStyle(fontSize: 10, color: mode.color)),
              Icon(Icons.chevron_right, size: 14, color: mode.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _RaceActiveBanner extends ConsumerWidget {
  const _RaceActiveBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final modeAsync = ref.watch(appModeProvider);
    final mode = modeAsync.value ?? currentAppMode();
    final isSkipper = mode == AppMode.skipper;
    final isSpectator = mode == AppMode.onshore || mode == AppMode.crew;

    // Query date range only, filter status client-side to avoid composite index
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .snapshots(),
      builder: (context, snap) {
        final allDocs = snap.data?.docs ?? [];
        final docs = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['status'] == 'running';
        }).toList();
        if (docs.isEmpty) return const SizedBox.shrink();

        final eventId = docs.first.id;

        // Don't show banner on skipper home — it has its own race card
        if (isSkipper) return const SizedBox.shrink();

        return Material(
          color: isSpectator ? Colors.green : Colors.red,
          child: InkWell(
            onTap: isSpectator
                ? () => context.go('/spectator')
                : () => context.push('/timing/$eventId'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.white, size: 10),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSpectator ? 'RACE IN PROGRESS' : 'RACE ACTIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isSpectator) ...[
                    TextButton(
                      onPressed: () => context.go('/spectator'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Watch Live'),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () => context.push('/timing/$eventId'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Timing'),
                    ),
                    TextButton(
                      onPressed: () => context.push('/checkin/$eventId'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Check-In'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
