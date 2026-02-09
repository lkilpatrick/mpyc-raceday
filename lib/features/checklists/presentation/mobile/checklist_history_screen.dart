import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/checklist.dart';
import '../checklist_providers.dart';

class ChecklistHistoryScreen extends ConsumerWidget {
  const ChecklistHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(completionHistoryProvider);
    final templatesAsync = ref.watch(checklistTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checklist History')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (completions) {
          if (completions.isEmpty) {
            return const Center(child: Text('No completed checklists yet.'));
          }
          final templates = templatesAsync.value ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: completions.length,
            itemBuilder: (context, index) {
              final c = completions[index];
              final template =
                  templates.where((t) => t.id == c.checklistId).firstOrNull;
              final statusLabel = switch (c.status) {
                ChecklistCompletionStatus.inProgress => 'In Progress',
                ChecklistCompletionStatus.completedPendingSignoff =>
                  'Pending Sign-Off',
                ChecklistCompletionStatus.signedOff => 'Signed Off',
              };
              final checked = c.items.where((i) => i.checked).length;

              return Card(
                child: ListTile(
                  title: Text(template?.name ?? c.checklistId),
                  subtitle: Text(
                    '${DateFormat.yMMMd().format(c.startedAt)} • $checked/${c.items.length} items • $statusLabel',
                  ),
                  trailing: Icon(
                    c.status == ChecklistCompletionStatus.signedOff
                        ? Icons.check_circle
                        : Icons.pending,
                    color: c.status == ChecklistCompletionStatus.signedOff
                        ? Colors.green
                        : Colors.orange,
                  ),
                  onTap: () => _showDetail(context, c, template),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    ChecklistCompletion completion,
    Checklist? template,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _CompletionDetail(
          completion: completion,
          template: template,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _CompletionDetail extends StatelessWidget {
  const _CompletionDetail({
    required this.completion,
    this.template,
    required this.scrollController,
  });

  final ChecklistCompletion completion;
  final Checklist? template;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final categories = <String, List<ChecklistItem>>{};
    for (final item in template?.items ?? <ChecklistItem>[]) {
      categories.putIfAbsent(item.category, () => []).add(item);
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          template?.name ?? 'Checklist',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Completed ${DateFormat.yMMMd().add_jm().format(completion.startedAt)}',
        ),
        if (completion.signOffBy != null)
          Text('Signed off by: ${completion.signOffBy}'),
        const Divider(height: 24),
        ...categories.entries.expand((entry) {
          return [
            Text(
              entry.key,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            ...entry.value.map((templateItem) {
              final completed = completion.items
                  .where((i) => i.itemId == templateItem.id)
                  .firstOrNull;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  (completed?.checked ?? false)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: (completed?.checked ?? false)
                      ? Colors.green
                      : Colors.grey,
                ),
                title: Text(templateItem.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (completed?.note?.isNotEmpty ?? false)
                      Text('Note: ${completed!.note}'),
                    if (completed?.photoUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            completed!.photoUrl!,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ];
        }),
      ],
    );
  }
}
