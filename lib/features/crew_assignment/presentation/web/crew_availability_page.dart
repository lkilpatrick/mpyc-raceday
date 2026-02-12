import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/crew_assignment_repository.dart';
import '../crew_assignment_formatters.dart';
import '../crew_assignment_providers.dart';

class CrewAvailabilityPage extends ConsumerWidget {
  const CrewAvailabilityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group_off, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'No upcoming events with crew assignments',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Create race events and assign crew to see the rotation matrix here.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final members = _memberList(events);
        final dutyCount = _dutyCount(events);

        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_off, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'No crew members assigned yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Assign crew to events from the Race Events page.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text('Crew Management',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _exportReport(context, dutyCount),
                    icon: const Icon(Icons.download),
                    label: const Text('Export rotation report'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: [
                      const DataColumn(label: Text('Member')),
                      ...events.map(
                        (e) => DataColumn(
                          label: Text(DateFormat.Md().format(e.date)),
                        ),
                      ),
                      const DataColumn(label: Text('RC Duties')),
                    ],
                    rows: members.map((member) {
                      return DataRow(
                        cells: [
                          DataCell(Text(member)),
                          ...events.map(
                            (event) => DataCell(_cellFor(event, member)),
                          ),
                          DataCell(Text('${dutyCount[member] ?? 0}')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> _memberList(List<RaceEvent> events) {
    final set = <String>{};
    for (final event in events) {
      for (final slot in event.crewSlots) {
        if (slot.memberName != null && slot.memberName!.isNotEmpty) {
          set.add(slot.memberName!);
        }
      }
    }
    return set.toList()..sort();
  }

  Map<String, int> _dutyCount(List<RaceEvent> events) {
    final counts = <String, int>{};
    for (final event in events) {
      for (final slot in event.crewSlots) {
        final name = slot.memberName;
        if (name == null) continue;
        counts.update(name, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return counts;
  }

  Widget _cellFor(RaceEvent event, String member) {
    final slot = event.crewSlots
        .where((s) => s.memberName == member)
        .firstOrNull;
    if (slot == null) return const Text('—');

    return Tooltip(
      message: '${roleLabel(slot.role)} • ${statusLabel(slot.status)}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor(slot.status).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(roleLabel(slot.role), style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  void _exportReport(BuildContext context, Map<String, int> dutyCount) {
    final text = dutyCount.entries.map((e) => '${e.key},${e.value}').join('\n');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rotation Report (CSV preview)'),
        content: SelectableText('member,duties\n$text'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
