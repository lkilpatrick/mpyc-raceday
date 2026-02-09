import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/crew_assignment_repository.dart';
import '../crew_assignment_formatters.dart';
import '../crew_assignment_providers.dart';

class MyScheduleScreen extends ConsumerWidget {
  const MyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(myAssignmentsProvider);

    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assignments) {
        if (assignments.isEmpty) {
          return const Center(child: Text('No upcoming assignments.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            final event = assignment.event;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(DateFormat.yMMMd().format(event.date)),
                    Text('Role: ${roleLabel(assignment.role)}'),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusColor(assignment.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(statusLabel(assignment.status)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () => ref
                              .read(crewAssignmentRepositoryProvider)
                              .updateConfirmation(
                                event.id,
                                assignment.role,
                                ConfirmationStatus.confirmed,
                              ),
                          child: const Text('Confirm'),
                        ),
                        OutlinedButton(
                          onPressed: () => ref
                              .read(crewAssignmentRepositoryProvider)
                              .updateConfirmation(
                                event.id,
                                assignment.role,
                                ConfirmationStatus.declined,
                              ),
                          child: const Text('Decline'),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go('/schedule/event/${event.id}'),
                          child: const Text('View details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
