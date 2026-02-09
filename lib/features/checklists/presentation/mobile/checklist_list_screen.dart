import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/checklist.dart';
import '../checklist_providers.dart';

class ChecklistListScreen extends ConsumerWidget {
  const ChecklistListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(checklistTemplatesProvider);
    final activeAsync = ref.watch(activeCompletionsProvider);
    final historyAsync = ref.watch(completionHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checklists')),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (templates) {
          final active = templates.where((t) => t.isActive).toList();
          final activeCompletions = activeAsync.valueOrNull ?? [];
          final history = historyAsync.valueOrNull ?? [];

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (activeCompletions.isNotEmpty) ...[
                Text(
                  'In Progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...activeCompletions.map(
                  (c) => _ActiveCompletionCard(
                    completion: c,
                    template: active
                        .where((t) => t.id == c.checklistId)
                        .firstOrNull,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Available Checklists',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...active.map(
                (template) => _TemplateCard(
                  template: template,
                  lastCompletion: history
                      .where((c) => c.checklistId == template.id)
                      .firstOrNull,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActiveCompletionCard extends StatelessWidget {
  const _ActiveCompletionCard({required this.completion, this.template});

  final ChecklistCompletion completion;
  final Checklist? template;

  @override
  Widget build(BuildContext context) {
    final checked = completion.items.where((i) => i.checked).length;
    final total = completion.items.length;
    final progress = total > 0 ? checked / total : 0.0;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: () => context.go('/checklists/active/${completion.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template?.name ?? 'Checklist',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Started ${DateFormat.jm().format(completion.startedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Text('$checked / $total items complete'),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template, this.lastCompletion});

  final Checklist template;
  final ChecklistCompletion? lastCompletion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeLabel = switch (template.type) {
      ChecklistType.preRace => 'Pre-Race',
      ChecklistType.postRace => 'Post-Race',
      ChecklistType.safety => 'Safety',
      ChecklistType.custom => 'Custom',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(typeLabel)),
              ],
            ),
            Text('${template.items.length} items'),
            if (lastCompletion != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last completed: ${DateFormat.yMMMd().format(lastCompletion!.startedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _startChecklist(context, ref),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Checklist'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startChecklist(BuildContext context, WidgetRef ref) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final repo = ref.read(checklistsRepositoryProvider);
    final completion = await repo.startChecklist(
      checklistId: template.id,
      eventId: 'today_${DateTime.now().toIso8601String().substring(0, 10)}',
      userId: userId,
    );
    if (context.mounted) {
      context.go('/checklists/active/${completion.id}');
    }
  }
}
