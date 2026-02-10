import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  static const _sections = <_NavSection>[
    _NavSection(
      title: 'Race Operations',
      items: [
        _NavItem(Icons.calendar_month, 'Season Calendar', '/season-calendar',
            'View and manage the race season schedule'),
        _NavItem(Icons.sailing, 'Race Events', '/race-events',
            'Upcoming races, results, and event details'),
        _NavItem(Icons.groups, 'Crew Management', '/crew-management',
            'Assign and track race committee crew'),
        _NavItem(Icons.map, 'Courses', '/courses',
            'Course configurations, marks, and diagrams'),
        _NavItem(Icons.checklist, 'Checklists', '/checklists',
            'Pre-race and safety checklists'),
        _NavItem(Icons.report_problem, 'Incidents & Protests',
            '/incidents', 'File and review incidents'),
        _NavItem(Icons.gavel, 'Racing Rules', '/rules-reference',
            'Browse and search the Racing Rules of Sailing'),
      ],
    ),
    _NavSection(
      title: 'Fleet Maintenance',
      items: [
        _NavItem(Icons.build, 'Maintenance', '/maintenance',
            'Track maintenance requests and repairs'),
      ],
    ),
    _NavSection(
      title: 'Administration',
      items: [
        _NavItem(Icons.people, 'Members', '/members',
            'Club membership directory'),
        _NavItem(Icons.sync, 'Sync Dashboard', '/sync-dashboard',
            'ClubSpot sync status and logs'),
        _NavItem(Icons.settings, 'System Settings', '/system-settings',
            'App configuration and preferences'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Welcome to MPYC Race Day',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          for (final section in _sections) ...[
            Text(section.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                )),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 500
                        ? 2
                        : 1;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: section.items.map((item) {
                    final cardWidth =
                        (constraints.maxWidth - (crossCount - 1) * 12) /
                            crossCount;
                    return SizedBox(
                      width: cardWidth,
                      child: _NavCard(item: item),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _NavSection {
  const _NavSection({required this.title, required this.items});
  final String title;
  final List<_NavItem> items;
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.route, this.description);
  final IconData icon;
  final String label;
  final String route;
  final String description;
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.item});
  final _NavItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(item.icon, size: 28, color: Theme.of(context).primaryColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(item.description,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
