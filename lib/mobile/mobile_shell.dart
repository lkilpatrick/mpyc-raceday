import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/features/auth/presentation/mobile/profile_screen.dart';
import 'package:mpyc_raceday/features/crew_assignment/presentation/mobile/full_calendar_screen.dart';
import 'package:mpyc_raceday/features/crew_assignment/presentation/mobile/my_schedule_screen.dart';
import 'package:mpyc_raceday/features/checklists/presentation/mobile/checklist_list_screen.dart';
import 'package:mpyc_raceday/features/crew_assignment/presentation/mobile/next_duty_home_screen.dart';
import 'package:mpyc_raceday/mobile/layouts/mobile_scaffold.dart';
import 'package:mpyc_raceday/mobile/navigation/mobile_bottom_nav.dart';
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
      0 => const NextDutyHomeScreen(),
      1 => const MyScheduleScreen(),
      2 => const ChecklistListScreen(),
      4 => const ProfileScreen(),
      _ => PlaceholderPage(title: item.label, subtitle: 'Mobile experience'),
    };

    return MobileScaffold(
      title: item.label,
      body: body,
      bottomNavigationBar: MobileBottomNav(currentIndex: _index, onTap: _onTap),
    );
  }
}
