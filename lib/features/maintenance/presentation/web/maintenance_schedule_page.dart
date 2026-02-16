import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/maintenance_repository.dart';
import '../maintenance_providers.dart';

class MaintenanceSchedulePage extends ConsumerStatefulWidget {
  const MaintenanceSchedulePage({super.key});

  @override
  ConsumerState<MaintenanceSchedulePage> createState() =>
      _MaintenanceSchedulePageState();
}

class _MaintenanceSchedulePageState
    extends ConsumerState<MaintenanceSchedulePage> {
  String _boatFilter = 'All';

  static const _boats = [
    'All',
    "Duncan's Watch",
    'Signal Boat',
    'Mark Boat',
    'Safety Boat',
  ];

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduledMaintenanceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            DropdownButton<String>(
              value: _boatFilter,
              items: _boats
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) => setState(() => _boatFilter = v ?? 'All'),
            ),
            FilledButton.icon(
              onPressed: _addScheduledItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Scheduled Item'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: scheduleAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              final filtered = _boatFilter == 'All'
                  ? items
                  : items.where((s) => s.boatName == _boatFilter).toList();

              if (filtered.isEmpty) {
                return const Center(
                    child: Text('No scheduled maintenance items.'));
              }

              // Group by boat
              final byBoat = <String, List<ScheduledMaintenance>>{};
              for (final item in filtered) {
                byBoat.putIfAbsent(item.boatName, () => []).add(item);
              }

              return ListView(
                children: byBoat.entries.expand((entry) {
                  return [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ...entry.value.map((item) {
                      final overdue = item.nextDueAt != null &&
                          item.nextDueAt!.isBefore(DateTime.now());
                      return Card(
                        color: overdue ? Colors.red.shade50 : null,
                        child: ListTile(
                          title: Text(item.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.description),
                              Text(
                                'Every ${item.intervalDays} days',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                              if (item.lastCompletedAt != null)
                                Text(
                                  'Last: ${DateFormat.yMMMd().format(item.lastCompletedAt!)}',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              if (item.nextDueAt != null)
                                Text(
                                  'Next due: ${DateFormat.yMMMd().format(item.nextDueAt!)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: overdue ? Colors.red : null,
                                        fontWeight: overdue
                                            ? FontWeight.bold
                                            : null,
                                      ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green),
                                tooltip: 'Mark completed',
                                onPressed: () => _markCompleted(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit',
                                onPressed: () => _editItem(item),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _deleteItem(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ];
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addScheduledItem() async {
    final result = await _showItemDialog(null);
    if (result != null) {
      await ref
          .read(maintenanceRepositoryProvider)
          .saveScheduledMaintenance(result);
    }
  }

  Future<void> _editItem(ScheduledMaintenance item) async {
    final result = await _showItemDialog(item);
    if (result != null) {
      await ref
          .read(maintenanceRepositoryProvider)
          .saveScheduledMaintenance(result);
    }
  }

  Future<void> _markCompleted(ScheduledMaintenance item) async {
    final now = DateTime.now();
    final nextDue = now.add(Duration(days: item.intervalDays));
    await ref.read(maintenanceRepositoryProvider).saveScheduledMaintenance(
          item.copyWith(lastCompletedAt: now, nextDueAt: nextDue),
        );
  }

  Future<void> _deleteItem(ScheduledMaintenance item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Delete "${item.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(maintenanceRepositoryProvider)
          .deleteScheduledMaintenance(item.id);
    }
  }

  Future<ScheduledMaintenance?> _showItemDialog(
      ScheduledMaintenance? existing) async {
    final titleC = TextEditingController(text: existing?.title ?? '');
    final descC = TextEditingController(text: existing?.description ?? '');
    final intervalC = TextEditingController(
        text: existing?.intervalDays.toString() ?? '30');
    String boat = existing?.boatName ?? "Duncan's Watch";

    return showDialog<ScheduledMaintenance>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Scheduled Item' : 'Edit Item'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: boat,
                  decoration: const InputDecoration(labelText: 'Boat'),
                  items: _boats
                      .where((b) => b != 'All')
                      .map((b) =>
                          DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => boat = v ?? boat),
                ),
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descC,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: intervalC,
                  decoration: const InputDecoration(
                      labelText: 'Interval (days)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final interval =
                    int.tryParse(intervalC.text.trim()) ?? 30;
                final now = DateTime.now();
                final item = ScheduledMaintenance(
                  id: existing?.id ??
                      'sched_${now.millisecondsSinceEpoch}',
                  boatName: boat,
                  title: titleC.text.trim(),
                  description: descC.text.trim(),
                  intervalDays: interval,
                  lastCompletedAt: existing?.lastCompletedAt,
                  nextDueAt: existing?.nextDueAt ??
                      now.add(Duration(days: interval)),
                );
                Navigator.pop(ctx, item);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
