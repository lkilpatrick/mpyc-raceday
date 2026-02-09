import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _MoreItem(
          icon: Icons.gavel,
          label: 'Racing Rules',
          subtitle: 'RRS reference & situation advisor',
          onTap: () => context.push('/rules'),
        ),
        _MoreItem(
          icon: Icons.build,
          label: 'Maintenance',
          subtitle: 'Report issues & view requests',
          onTap: () => context.push('/maintenance/feed'),
        ),
        _MoreItem(
          icon: Icons.report,
          label: 'Incidents',
          subtitle: 'View reported incidents',
          onTap: () => context.push('/incidents/all'),
        ),
        _MoreItem(
          icon: Icons.sailing,
          label: 'Courses',
          subtitle: 'View course library',
          onTap: () => context.push('/courses/select/browse'),
        ),
        const Divider(),
        _MoreItem(
          icon: Icons.person,
          label: 'Profile',
          subtitle: 'Your account & preferences',
          onTap: () => context.push('/more'),
        ),
        _MoreItem(
          icon: Icons.settings,
          label: 'Settings',
          subtitle: 'App settings & notifications',
          onTap: () => context.push('/more'),
        ),
      ],
    );
  }
}

class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
