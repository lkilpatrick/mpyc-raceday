import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/features/crew_assignment/presentation/mobile/my_schedule_screen.dart';
import 'package:mpyc_raceday/features/checklists/presentation/mobile/checklist_list_screen.dart';
import 'package:mpyc_raceday/features/home/presentation/mobile/home_screen.dart';
import 'package:mpyc_raceday/features/home/presentation/mobile/more_screen.dart';
import 'package:mpyc_raceday/mobile/layouts/mobile_scaffold.dart';
import 'package:mpyc_raceday/mobile/navigation/mobile_bottom_nav.dart';
import 'package:mpyc_raceday/features/weather/presentation/mobile/weather_dashboard_screen.dart';
import 'package:mpyc_raceday/shared/widgets/placeholder_page.dart';

class MobileShell extends StatefulWidget {
  const MobileShell({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
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

  void _onTap(int index) {
    if (index == _index) {
      return;
    }
    setState(() {
      _index = index;
    });
    context.go(mobileNavItems[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final item = mobileNavItems[_index];
    final body = switch (_index) {
      0 => const HomeScreen(),
      1 => const MyScheduleScreen(),
      2 => const ChecklistListScreen(),
      3 => const WeatherDashboardScreen(),
      4 => const MoreScreen(),
      _ => PlaceholderPage(title: item.label, subtitle: 'Mobile experience'),
    };

    return MobileScaffold(
      title: item.label,
      body: Column(
        children: [
          // RACE ACTIVE banner
          const _RaceActiveBanner(),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: MobileBottomNav(currentIndex: _index, onTap: _onTap),
    );
  }
}

class _RaceActiveBanner extends StatelessWidget {
  const _RaceActiveBanner();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .where('status', isEqualTo: 'racing')
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final eventId = docs.first.id;

        return Material(
          color: Colors.red,
          child: InkWell(
            onTap: () => context.push('/timing/$eventId'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.white, size: 10),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'RACE ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
