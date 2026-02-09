import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/fleet_broadcast.dart';
import '../courses_providers.dart';

class FleetBroadcastScreen extends ConsumerStatefulWidget {
  const FleetBroadcastScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<FleetBroadcastScreen> createState() =>
      _FleetBroadcastScreenState();
}

class _FleetBroadcastScreenState extends ConsumerState<FleetBroadcastScreen> {
  final _messageController = TextEditingController();
  BroadcastType _selectedType = BroadcastType.general;

  static const _templates = [
    (BroadcastType.courseSelection, 'Course Selected', Icons.route),
    (BroadcastType.postponement, 'Postponement', Icons.pause_circle),
    (BroadcastType.abandonment, 'Abandonment', Icons.cancel),
    (BroadcastType.courseChange, 'Course Change', Icons.swap_horiz),
    (BroadcastType.generalRecall, 'General Recall', Icons.replay),
    (BroadcastType.shortenedCourse, 'Shortened Course', Icons.content_cut),
    (BroadcastType.cancellation, 'Racing Cancelled', Icons.block),
    (BroadcastType.general, 'Custom Message', Icons.message),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Broadcast')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Template buttons
          Text('Quick Templates',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _templates.map((t) {
              final (type, label, icon) = t;
              final isSelected = _selectedType == type;
              return ChoiceChip(
                avatar: Icon(icon, size: 18),
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedType = type;
                    _messageController.text = _templateMessage(type);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Message field
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
              hintText: 'Enter broadcast message...',
            ),
          ),
          const SizedBox(height: 12),

          // Recipient count
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.people, size: 20),
                  const SizedBox(width: 8),
                  const Text('Will notify all checked-in boats'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Send button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _send,
              icon: const Icon(Icons.send),
              label: const Text('SEND BROADCAST',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),

          // Recent broadcasts
          Text('Recent Broadcasts',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Consumer(builder: (context, ref, _) {
            final broadcastsAsync =
                ref.watch(broadcastsProvider(widget.eventId));
            return broadcastsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (broadcasts) {
                if (broadcasts.isEmpty) {
                  return const Text('No broadcasts sent yet.');
                }
                return Column(
                  children: broadcasts.take(10).map((b) {
                    return Card(
                      child: ListTile(
                        dense: true,
                        leading: Icon(_iconForType(b.type), size: 20),
                        title: Text(b.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${b.type.name} • ${b.sentBy} • ${b.deliveryCount} delivered',
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  String _templateMessage(BroadcastType type) => switch (type) {
        BroadcastType.courseSelection =>
          'MPYC RC: Course selected for today\'s racing.',
        BroadcastType.postponement =>
          'MPYC RC: Racing is postponed. Stand by for further signals.',
        BroadcastType.abandonment =>
          'MPYC RC: Race abandoned. Return to the harbor.',
        BroadcastType.courseChange =>
          'MPYC RC: Course has been changed.',
        BroadcastType.generalRecall =>
          'MPYC RC: General recall. New start sequence will begin shortly.',
        BroadcastType.shortenedCourse =>
          'MPYC RC: Shortened course. Finish at the next mark.',
        BroadcastType.cancellation =>
          'MPYC RC: Racing cancelled for today.',
        BroadcastType.general => '',
      };

  IconData _iconForType(BroadcastType type) => switch (type) {
        BroadcastType.courseSelection => Icons.route,
        BroadcastType.postponement => Icons.pause_circle,
        BroadcastType.abandonment => Icons.cancel,
        BroadcastType.courseChange => Icons.swap_horiz,
        BroadcastType.generalRecall => Icons.replay,
        BroadcastType.shortenedCourse => Icons.content_cut,
        BroadcastType.cancellation => Icons.block,
        BroadcastType.general => Icons.message,
      };

  Future<void> _send() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Broadcast?'),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send')),
        ],
      ),
    );
    if (confirm != true) return;

    final broadcast = FleetBroadcast(
      id: '',
      eventId: widget.eventId,
      sentBy: 'PRO',
      message: msg,
      type: _selectedType,
      sentAt: DateTime.now(),
      deliveryCount: 0,
    );

    await ref.read(coursesRepositoryProvider).sendBroadcast(broadcast);

    if (mounted) {
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast sent!')),
      );
    }
  }
}
