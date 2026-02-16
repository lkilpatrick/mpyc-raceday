import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpyc_raceday/core/theme.dart';

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
  final _messageCtrl = TextEditingController();
  BroadcastType _type = BroadcastType.general;
  BroadcastTarget _target = BroadcastTarget.everyone;
  bool _requiresAck = true;
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<BroadcastType>(
                        // ignore: deprecated_member_use
                        value: _type,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: BroadcastType.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(_typeShort(t),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _type = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<BroadcastTarget>(
                        initialValue: _target,
                        decoration: const InputDecoration(
                          labelText: 'Send To',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: BroadcastTarget.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(_targetLabel(t)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _target = v);
                        },
                      ),
                    ),
                  ],
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
                Row(
                  children: [
                    Checkbox(
                      value: _requiresAck,
                      onChanged: (v) =>
                          setState(() => _requiresAck = v ?? true),
                    ),
                    const Expanded(
                      child: Text('Require acknowledgement from recipients',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
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
                          '${_typeLabel(b.type)} · ${_targetLabel(b.target)} · ${DateFormat.jm().format(b.sentAt)}'
                          '${b.requiresAck ? ' · ${b.ackCount} ack' : ''}',
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
              sentBy: 'RC',
              message: message,
              type: _type,
              sentAt: DateTime.now(),
              deliveryCount: 0,
              target: _target,
              requiresAck: _requiresAck,
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

  static String _typeShort(BroadcastType type) {
    return switch (type) {
      BroadcastType.courseSelection => 'Course',
      BroadcastType.postponement => 'Postpone',
      BroadcastType.abandonment => 'Abandon',
      BroadcastType.courseChange => 'Course Chg',
      BroadcastType.generalRecall => 'Gen. Recall',
      BroadcastType.shortenedCourse => 'Shorten',
      BroadcastType.cancellation => 'Cancel',
      BroadcastType.general => 'General',
      BroadcastType.vhfChannelChange => 'VHF Ch.',
      BroadcastType.shortenCourse => 'Shorten',
      BroadcastType.abandonTooMuchWind => 'Abn Wind+',
      BroadcastType.abandonTooLittleWind => 'Abn Wind-',
    };
  }

  static String _typeLabel(BroadcastType type) {
    return switch (type) {
      BroadcastType.courseSelection => 'Course Selection',
      BroadcastType.postponement => 'Postponement (AP Flag)',
      BroadcastType.abandonment => 'Abandonment (N Flag)',
      BroadcastType.courseChange => 'Course Change',
      BroadcastType.generalRecall => 'General Recall (1st Sub)',
      BroadcastType.shortenedCourse => 'Shortened Course (S Flag)',
      BroadcastType.cancellation => 'Cancellation',
      BroadcastType.general => 'General',
      BroadcastType.vhfChannelChange => 'VHF Channel Change',
      BroadcastType.shortenCourse => 'Shorten Course (S Flag)',
      BroadcastType.abandonTooMuchWind => 'Abandon — Too Much Wind',
      BroadcastType.abandonTooLittleWind => 'Abandon — Too Little Wind',
    };
  }

  static String _targetLabel(BroadcastTarget target) {
    return switch (target) {
      BroadcastTarget.everyone => 'Everyone',
      BroadcastTarget.skippersOnly => 'Skippers Only',
      BroadcastTarget.onshore => 'Onshore',
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
      BroadcastType.vhfChannelChange => Colors.indigo,
      BroadcastType.shortenCourse => Colors.teal,
      BroadcastType.abandonTooMuchWind => Colors.red,
      BroadcastType.abandonTooLittleWind => Colors.amber,
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
      BroadcastType.vhfChannelChange => Icons.radio,
      BroadcastType.shortenCourse => Icons.content_cut,
      BroadcastType.abandonTooMuchWind => Icons.air,
      BroadcastType.abandonTooLittleWind => Icons.cloud_off,
    };
  }
}
