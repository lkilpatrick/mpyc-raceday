import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/fleet_broadcast.dart';
import '../courses_providers.dart';

class FleetBroadcastHistoryPage extends ConsumerWidget {
  const FleetBroadcastHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final broadcastsAsync = ref.watch(broadcastsProvider(null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Fleet Broadcast History',
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        Expanded(
          child: broadcastsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (broadcasts) {
              if (broadcasts.isEmpty) {
                return const Center(child: Text('No broadcasts sent yet.'));
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Event')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Message')),
                      DataColumn(label: Text('Sent By')),
                      DataColumn(label: Text('Delivered')),
                    ],
                    rows: broadcasts.map((b) {
                      return DataRow(cells: [
                        DataCell(Text(
                            DateFormat.yMMMd().add_Hm().format(b.sentAt))),
                        DataCell(Text(b.eventId.length > 8
                            ? b.eventId.substring(0, 8)
                            : b.eventId)),
                        DataCell(_typeChip(b.type)),
                        DataCell(SizedBox(
                          width: 300,
                          child: Text(b.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        )),
                        DataCell(Text(b.sentBy)),
                        DataCell(Text('${b.deliveryCount}')),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _typeChip(BroadcastType type) {
    final (label, color) = switch (type) {
      BroadcastType.courseSelection => ('Course', Colors.green),
      BroadcastType.postponement => ('Postpone', Colors.orange),
      BroadcastType.abandonment => ('Abandon', Colors.red),
      BroadcastType.courseChange => ('Change', Colors.blue),
      BroadcastType.generalRecall => ('Recall', Colors.purple),
      BroadcastType.shortenedCourse => ('Shorten', Colors.teal),
      BroadcastType.cancellation => ('Cancel', Colors.red),
      BroadcastType.general => ('General', Colors.grey),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.15),
      visualDensity: VisualDensity.compact,
    );
  }
}
