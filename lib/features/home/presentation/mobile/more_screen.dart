import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_mode/data/app_mode.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeAsync = ref.watch(appModeProvider);
    final mode = modeAsync.value ?? currentAppMode();
    final isRC = mode == AppMode.raceCommittee;
    final isSkipper = mode == AppMode.skipper;
    final isCrew = mode == AppMode.crew;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _MoreItem(
          icon: Icons.swap_horiz,
          label: 'Switch Mode',
          subtitle: 'Change between RC, Skipper, Crew, Onshore',
          onTap: () => context.push('/mode-switcher'),
          color: Colors.indigo,
        ),
        const Divider(),
        _MoreItem(
          icon: Icons.gavel,
          label: 'Racing Rules',
          subtitle: 'RRS reference & situation advisor',
          onTap: () => context.push('/rules'),
        ),
        _MoreItem(
          icon: Icons.air,
          label: 'Live Wind',
          subtitle: 'Real-time wind from NOAA',
          onTap: () => context.push('/live-wind'),
        ),
        if (isRC || isSkipper) ...[
          _MoreItem(
            icon: Icons.report,
            label: 'Incidents',
            subtitle: 'View reported incidents',
            onTap: () => context.push('/incidents/browse'),
          ),
        ],
        if (isRC) ...[
          const Divider(),
          _MoreItem(
            icon: Icons.checklist,
            label: 'Checklists',
            subtitle: 'Pre-race checklists',
            onTap: () => context.push('/checklists'),
          ),
          _MoreItem(
            icon: Icons.history,
            label: 'Checklist History',
            subtitle: 'Past checklist completions',
            onTap: () => context.push('/checklists/history'),
          ),
          _MoreItem(
            icon: Icons.build,
            label: 'Maintenance Feed',
            subtitle: 'View all maintenance requests',
            onTap: () => context.push('/maintenance/feed'),
          ),
          _MoreItem(
            icon: Icons.science,
            label: 'Demo Mode',
            subtitle: 'Simulate a race day for testing',
            onTap: () => context.push('/demo'),
            color: Colors.amber.shade800,
          ),
        ],
        if (isCrew) ...[
          const Divider(),
          _MoreItem(
            icon: Icons.person_add,
            label: 'Crew Profile',
            subtitle: 'Set your boat & position',
            onTap: () => context.push('/crew-profile'),
          ),
        ],
        const Divider(),
        _MoreItem(
          icon: Icons.person,
          label: 'Profile',
          subtitle: 'Your account & preferences',
          onTap: () => context.push('/profile'),
        ),
        _MoreItem(
          icon: Icons.logout,
          label: 'Sign Out',
          subtitle: 'Sign out of your account',
          onTap: () => _handleSignOut(context),
          color: Colors.red,
        ),
      ],
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) context.go('/login');
    }
  }
}

class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: color != null ? TextStyle(color: color) : null),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
