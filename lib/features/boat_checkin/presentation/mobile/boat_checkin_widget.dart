import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../boat_checkin_providers.dart';

class BoatCheckinWidget extends ConsumerWidget {
  const BoatCheckinWidget({super.key, required this.eventId, this.eventName});

  final String eventId;
  final String? eventName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(checkinCountProvider(eventId));
    final closedAsync = ref.watch(checkinsClosedProvider(eventId));
    final isClosed = closedAsync.valueOrNull ?? false;

    return Card(
      child: InkWell(
        onTap: () => context.push('/checkin/$eventId'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isClosed
                      ? Colors.grey.shade200
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isClosed ? Colors.grey : Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count boat${count == 1 ? '' : 's'} checked in',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      eventName ?? 'Today\'s event',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isClosed)
                const Chip(
                  label: Text('CLOSED',
                      style: TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: Colors.red,
                  visualDensity: VisualDensity.compact,
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
