import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpyc_raceday/core/theme.dart';

import '../../data/models/fleet_broadcast.dart';
import '../courses_providers.dart';

class FleetBroadcastHistoryPage extends ConsumerWidget {
  const FleetBroadcastHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final broadcastsAsync = ref.watch(broadcastsProvider(null));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Fleet Broadcast History',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: broadcastsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (broadcasts) {
              if (broadcasts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broadcast_on_personal,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No broadcasts yet.',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: broadcasts.length,
                itemBuilder: (_, i) {
                  final b = broadcasts[i];
                  return _BroadcastCard(broadcast: b);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({required this.broadcast});

  final FleetBroadcast broadcast;

  @override
  Widget build(BuildContext context) {
    final typeLabel = broadcast.type.name
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m[0]}')
        .trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _typeColor(broadcast.type).withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _typeIcon(broadcast.type),
                color: _typeColor(broadcast.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          typeLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _typeColor(broadcast.type),
                          ),
                        ),
                        backgroundColor:
                            _typeColor(broadcast.type).withAlpha(20),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Spacer(),
                      Text(
                        DateFormat.yMMMd()
                            .add_jm()
                            .format(broadcast.sentAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    broadcast.message,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        broadcast.sentBy,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.send, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${broadcast.deliveryCount} delivered',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _typeColor(BroadcastType type) {
    return switch (type) {
      BroadcastType.courseSelection => AppColors.primary,
      BroadcastType.postponement => Colors.orange,
      BroadcastType.abandonment => Colors.red,
      BroadcastType.courseChange => Colors.blue,
      BroadcastType.generalRecall => Colors.purple,
      BroadcastType.shortenedCourse => Colors.teal,
      BroadcastType.cancellation => Colors.red.shade800,
      BroadcastType.general => Colors.grey,
    };
  }

  static IconData _typeIcon(BroadcastType type) {
    return switch (type) {
      BroadcastType.courseSelection => Icons.map,
      BroadcastType.postponement => Icons.schedule,
      BroadcastType.abandonment => Icons.cancel,
      BroadcastType.courseChange => Icons.swap_horiz,
      BroadcastType.generalRecall => Icons.replay,
      BroadcastType.shortenedCourse => Icons.content_cut,
      BroadcastType.cancellation => Icons.block,
      BroadcastType.general => Icons.campaign,
    };
  }
}
