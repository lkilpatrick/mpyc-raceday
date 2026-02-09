import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpyc_raceday/core/theme.dart';

import '../../data/models/fleet_broadcast.dart';
import '../../domain/courses_repository.dart';
import '../courses_providers.dart';

class FleetBroadcastScreen extends ConsumerStatefulWidget {
  const FleetBroadcastScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<FleetBroadcastScreen> createState() =>
      _FleetBroadcastScreenState();
}

class _FleetBroadcastScreenState extends ConsumerState<FleetBroadcastScreen> {
  final _messageCtrl = TextEditingController();
  BroadcastType _type = BroadcastType.general;
  bool _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final broadcastsAsync = ref.watch(broadcastsProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Broadcast')),
      body: Column(
        children: [
          // Compose area
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<BroadcastType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Broadcast Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: BroadcastType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(_typeLabel(t)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                    hintText: 'Enter broadcast message...',
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _sending ? null : _sendBroadcast,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(_sending ? 'Sending...' : 'Send Broadcast'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // History
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  'Broadcast History',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
              ],
            ),
          ),
          Expanded(
            child: broadcastsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (broadcasts) {
                if (broadcasts.isEmpty) {
                  return const Center(
                    child: Text('No broadcasts for this event.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: broadcasts.length,
                  itemBuilder: (_, i) {
                    final b = broadcasts[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          _typeIcon(b.type),
                          color: _typeColor(b.type),
                        ),
                        title: Text(b.message,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          '${_typeLabel(b.type)} · ${DateFormat.jm().format(b.sentAt)} · ${b.deliveryCount} delivered',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendBroadcast() async {
    final message = _messageCtrl.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(coursesRepositoryProvider).sendBroadcast(
            FleetBroadcast(
              id: '',
              eventId: widget.eventId,
              sentBy: 'RC', // TODO: use actual user
              message: message,
              type: _type,
              sentAt: DateTime.now(),
              deliveryCount: 0,
            ),
          );
      _messageCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast sent.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static String _typeLabel(BroadcastType type) {
    return switch (type) {
      BroadcastType.courseSelection => 'Course Selection',
      BroadcastType.postponement => 'Postponement',
      BroadcastType.abandonment => 'Abandonment',
      BroadcastType.courseChange => 'Course Change',
      BroadcastType.generalRecall => 'General Recall',
      BroadcastType.shortenedCourse => 'Shortened Course',
      BroadcastType.cancellation => 'Cancellation',
      BroadcastType.general => 'General',
    };
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
