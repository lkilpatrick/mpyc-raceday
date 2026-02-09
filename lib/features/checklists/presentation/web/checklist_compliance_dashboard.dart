import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/checklist.dart';
import '../checklist_providers.dart';

class ChecklistComplianceDashboard extends ConsumerWidget {
  const ChecklistComplianceDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(allCompletionHistoryProvider);
    final templatesAsync = ref.watch(checklistTemplatesProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (completions) {
        final templates = templatesAsync.value ?? [];

        // Stats
        final total = completions.length;
        final signedOff = completions
            .where((c) => c.status == ChecklistCompletionStatus.signedOff)
            .length;
        final pending = completions
            .where((c) =>
                c.status == ChecklistCompletionStatus.completedPendingSignoff)
            .length;
        final inProgress = completions
            .where(
                (c) => c.status == ChecklistCompletionStatus.inProgress)
            .length;
        final signOffRate =
            total > 0 ? (signedOff / total * 100).toStringAsFixed(1) : '0';

        // Average completion time (for signed-off checklists)
        final completedWithTime = completions.where(
          (c) => c.completedAt != null,
        );
        final avgMinutes = completedWithTime.isNotEmpty
            ? completedWithTime
                    .map((c) =>
                        c.completedAt!.difference(c.startedAt).inMinutes)
                    .reduce((a, b) => a + b) /
                completedWithTime.length
            : 0;

        // Most common notes (issues)
        final noteCounts = <String, int>{};
        for (final c in completions) {
          for (final item in c.items) {
            if (item.note != null && item.note!.isNotEmpty) {
              // Find the template item title
              final template = templates
                  .where((t) => t.id == c.checklistId)
                  .firstOrNull;
              final templateItem = template?.items
                  .where((ti) => ti.id == item.itemId)
                  .firstOrNull;
              final label = templateItem?.title ?? item.itemId;
              noteCounts.update(label, (v) => v + 1, ifAbsent: () => 1);
            }
          }
        }
        final topNotes = noteCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Pre-race vs post-race completion rates
        final preRaceTemplateIds = templates
            .where((t) => t.type == ChecklistType.preRace)
            .map((t) => t.id)
            .toSet();
        final postRaceTemplateIds = templates
            .where((t) => t.type == ChecklistType.postRace)
            .map((t) => t.id)
            .toSet();
        final preRaceCompleted = completions
            .where((c) =>
                preRaceTemplateIds.contains(c.checklistId) &&
                c.status == ChecklistCompletionStatus.signedOff)
            .length;
        final postRaceCompleted = completions
            .where((c) =>
                postRaceTemplateIds.contains(c.checklistId) &&
                c.status == ChecklistCompletionStatus.signedOff)
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    title: 'Sign-Off Rate',
                    value: '$signOffRate%',
                    subtitle: '$signedOff of $total checklists',
                    icon: Icons.verified,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: 'Avg Completion Time',
                    value: '${avgMinutes.toStringAsFixed(0)} min',
                    subtitle: 'Across ${completedWithTime.length} completions',
                    icon: Icons.timer,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Pre-Race Completed',
                    value: '$preRaceCompleted',
                    subtitle: 'Signed off',
                    icon: Icons.sailing,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Post-Race Completed',
                    value: '$postRaceCompleted',
                    subtitle: 'Signed off',
                    icon: Icons.anchor,
                    color: Colors.purple,
                  ),
                  _StatCard(
                    title: 'Pending Sign-Off',
                    value: '$pending',
                    subtitle: 'Awaiting co-sign',
                    icon: Icons.pending_actions,
                    color: Colors.amber,
                  ),
                  _StatCard(
                    title: 'In Progress',
                    value: '$inProgress',
                    subtitle: 'Not yet completed',
                    icon: Icons.hourglass_bottom,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Most commonly noted issues
              Text(
                'Most Commonly Noted Issues',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (topNotes.isEmpty)
                const Text('No notes recorded yet.')
              else
                Card(
                  child: Column(
                    children: topNotes.take(10).map((entry) {
                      return ListTile(
                        title: Text(entry.key),
                        trailing: Chip(
                          label: Text('${entry.value} notes'),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 24),
              // Overdue / incomplete checklists
              Text(
                'Incomplete Checklists (In Progress)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...completions
                  .where((c) =>
                      c.status == ChecklistCompletionStatus.inProgress)
                  .take(10)
                  .map((c) {
                final template = templates
                    .where((t) => t.id == c.checklistId)
                    .firstOrNull;
                final checked = c.items.where((i) => i.checked).length;
                return Card(
                  child: ListTile(
                    title: Text(template?.name ?? c.checklistId),
                    subtitle: Text(
                      'Event: ${c.eventId} • $checked/${c.items.length} items • Started by ${c.completedBy}',
                    ),
                    trailing: const Icon(Icons.warning, color: Colors.orange),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
