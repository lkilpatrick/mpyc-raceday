import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/crew_assignment_repository.dart';
import '../crew_assignment_formatters.dart';
import '../crew_assignment_providers.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final _declineReasonController = TextEditingController();

  @override
  void dispose() {
    _declineReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(eventDetailProvider(widget.eventId));
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Detail')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) {
          final event = detail.event;
          final mySlot = event.crewSlots
              .where((s) => s.memberId == userId)
              .firstOrNull;
          final isAssigned = mySlot != null;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                event.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${event.date.month}/${event.date.day}/${event.date.year} • ${event.seriesName}',
              ),
              const SizedBox(height: 12),
              Text('Crew', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...event.crewSlots.map(
                (slot) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(roleLabel(slot.role)),
                  subtitle: Text(slot.memberName ?? 'Unassigned'),
                  trailing: Text(statusLabel(slot.status)),
                ),
              ),
              if (isAssigned) ...[
                const Divider(height: 24),
                Text(
                  'Your response',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () =>
                      _setStatus(mySlot.role, ConfirmationStatus.confirmed),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _declineWithReason(mySlot.role),
                  icon: const Icon(Icons.close),
                  label: const Text('Decline'),
                ),
              ],
              const Divider(height: 24),
              Text('Course: ${detail.courseName ?? 'Not selected'}'),
              Text('Weather: ${detail.weatherSummary ?? 'No weather log'}'),
              const SizedBox(height: 12),
              if (isAssigned && _isToday(event.date))
                FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.playlist_add_check),
                  label: const Text('Start Checklist'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _setStatus(CrewRole role, ConfirmationStatus status) async {
    await ref
        .read(crewAssignmentRepositoryProvider)
        .updateConfirmation(widget.eventId, role, status);
  }

  Future<void> _declineWithReason(CrewRole role) async {
    final suggestions = await ref
        .read(crewAssignmentRepositoryProvider)
        .suggestFairAssignments(widget.eventId);
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Decline assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _declineReasonController,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 8),
            const Text('Suggested RC-qualified replacements:'),
            ...suggestions.take(4).map((name) => Text('• $name')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(crewAssignmentRepositoryProvider)
                  .updateConfirmation(
                    widget.eventId,
                    role,
                    ConfirmationStatus.declined,
                    reason: _declineReasonController.text.trim(),
                  );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Submit Decline'),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }
}
