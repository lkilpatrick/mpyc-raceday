import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Report tab: quick access to file a protest or report a maintenance issue.
class ReportTabScreen extends StatefulWidget {
  const ReportTabScreen({super.key});

  @override
  State<ReportTabScreen> createState() => _ReportTabScreenState();
}

class _ReportTabScreenState extends State<ReportTabScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ── File a Protest ──
        _ReportCard(
          icon: Icons.gavel,
          color: Colors.red,
          title: 'File a Protest',
          subtitle: 'Report a racing incident or rule violation',
          onTap: () => _openProtest(),
        ),
        const SizedBox(height: 8),

        // ── Report Maintenance Issue ──
        _ReportCard(
          icon: Icons.build,
          color: Colors.orange,
          title: 'Report Maintenance Issue',
          subtitle: 'Report a boat or equipment problem',
          onTap: () => context.push('/maintenance/report'),
        ),
        const SizedBox(height: 20),

        // ── Recent Reports ──
        Text('Recent Reports',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Recent incidents
        _RecentIncidents(),
        const SizedBox(height: 8),

        // Recent maintenance
        _RecentMaintenance(),
      ],
    );
  }

  Future<void> _openProtest() async {
    // Find today's event to attach the protest to
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final snap = await FirebaseFirestore.instance
        .collection('race_events')
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('date', isLessThan: Timestamp.fromDate(todayEnd))
        .limit(1)
        .get();

    if (!mounted) return;

    if (snap.docs.isNotEmpty) {
      context.push('/incidents/report/${snap.docs.first.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No race event today to file a protest against')),
      );
    }
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentIncidents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .orderBy('reportedAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.gavel, size: 18, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  const Text('No recent incidents',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final desc = d['description'] as String? ?? '';
            final status = d['status'] as String? ?? '';
            final ts = d['reportedAt'] as Timestamp?;
            final timeStr = ts != null
                ? '${ts.toDate().month}/${ts.toDate().day}'
                : '';

            return Card(
              child: ListTile(
                dense: true,
                leading: Icon(Icons.gavel,
                    size: 18,
                    color: status == 'resolved' ? Colors.green : Colors.red),
                title: Text(
                  desc.length > 60 ? '${desc.substring(0, 60)}...' : desc,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text('$status · $timeStr',
                    style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => context.push('/incidents/detail/${doc.id}'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RecentMaintenance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maintenance_requests')
          .orderBy('reportedAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.build, size: 18, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  const Text('No recent maintenance reports',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final title = d['title'] as String? ?? '';
            final status = d['status'] as String? ?? '';
            final priority = d['priority'] as String? ?? '';

            final priorityColor = switch (priority) {
              'critical' => Colors.red,
              'high' => Colors.deepOrange,
              'medium' => Colors.orange,
              _ => Colors.green,
            };

            return Card(
              child: ListTile(
                dense: true,
                leading: Icon(Icons.circle, size: 12, color: priorityColor),
                title: Text(title, style: const TextStyle(fontSize: 13)),
                subtitle: Text('$priority · $status',
                    style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => context.push('/maintenance/detail/${doc.id}'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
