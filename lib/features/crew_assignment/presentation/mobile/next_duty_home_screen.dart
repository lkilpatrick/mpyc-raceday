import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../maintenance/presentation/maintenance_providers.dart';
import '../crew_assignment_formatters.dart';
import '../crew_assignment_providers.dart';

class NextDutyHomeScreen extends ConsumerWidget {
  const NextDutyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextDutyAsync = ref.watch(nextDutyProvider);

    final criticalCount = ref.watch(criticalMaintenanceCountProvider);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Maintenance alerts
        if (criticalCount.valueOrNull != null && criticalCount.valueOrNull! > 0)
          Card(
            color: Colors.red.shade50,
            child: InkWell(
              onTap: () => context.go('/maintenance/feed'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${criticalCount.valueOrNull} critical maintenance issue${criticalCount.valueOrNull! > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        if (criticalCount.valueOrNull != null && criticalCount.valueOrNull! > 0)
          const SizedBox(height: 4),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: nextDutyAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Unable to load next duty: $e'),
              data: (assignment) {
                if (assignment == null) {
                  return const Text(
                    'Your Next RC Duty\nNo upcoming assignment',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Next RC Duty',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(assignment.event.name),
                    Text(DateFormat.yMMMd().format(assignment.event.date)),
                    Text('Role: ${roleLabel(assignment.role)}'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () =>
                          context.go('/schedule/event/${assignment.event.id}'),
                      child: const Text('Open assignment'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
