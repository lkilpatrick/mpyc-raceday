import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// RC Timing hub — shows today's event, start sequence, finish recording,
/// check-in management, and scoring all in one place.
class RcTimingScreen extends ConsumerStatefulWidget {
  const RcTimingScreen({super.key});

  @override
  ConsumerState<RcTimingScreen> createState() => _RcTimingScreenState();
}

class _RcTimingScreenState extends ConsumerState<RcTimingScreen> {
  String? _eventId;
  String _eventName = '';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _loadTodaysEvent();
  }

  Future<void> _loadTodaysEvent() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    try {
      final snap = await FirebaseFirestore.instance
          .collection('race_events')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        final d = snap.docs.first.data();
        setState(() {
          _eventId = snap.docs.first.id;
          _eventName = d['name'] as String? ?? 'Race Day';
          _status = d['status'] as String? ?? 'setup';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_eventId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No race event today',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    final (statusLabel, statusColor) = switch (_status) {
      'setup' => ('Setup', Colors.orange),
      'racing' => ('Racing', Colors.green),
      'complete' => ('Complete', Colors.blue),
      _ => ('—', Colors.grey),
    };

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Event header
        Card(
          color: statusColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.sailing, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_eventName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(DateFormat.yMMMd().format(DateTime.now()),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Quick actions grid
        _RcActionCard(
          icon: Icons.map,
          label: 'Select Course',
          subtitle: 'Choose and broadcast course to fleet',
          color: Colors.blue,
          onTap: () => context.push('/courses/select/$_eventId'),
        ),
        const SizedBox(height: 8),
        _RcActionCard(
          icon: Icons.timer,
          label: 'Start Sequence',
          subtitle: 'Horn detection & countdown timer',
          color: Colors.green,
          onTap: () => context.push('/timing/start/$_eventId'),
        ),
        const SizedBox(height: 8),
        _RcActionCard(
          icon: Icons.sports_score,
          label: 'Record Finishes',
          subtitle: 'Tap to record each boat crossing the line',
          color: Colors.orange,
          onTap: () => context.push('/timing/$_eventId'),
        ),
        const SizedBox(height: 8),
        _RcActionCard(
          icon: Icons.how_to_reg,
          label: 'Race Check-In',
          subtitle: 'Manage boat check-ins & souls on board',
          color: Colors.teal,
          onTap: () => context.push('/checkin/$_eventId'),
        ),
        const SizedBox(height: 8),
        _RcActionCard(
          icon: Icons.leaderboard,
          label: 'Scoring & Results',
          subtitle: 'View corrected times and publish results',
          color: Colors.purple,
          onTap: () => context.push('/leaderboard'),
        ),
        const SizedBox(height: 8),
        _RcActionCard(
          icon: Icons.campaign,
          label: 'Fleet Broadcast',
          subtitle: 'Send course/status notifications to fleet',
          color: Colors.red,
          onTap: () => context.push('/courses/broadcast/$_eventId'),
        ),
        const SizedBox(height: 8),
        _RcActionCard(
          icon: Icons.report,
          label: 'Incidents',
          subtitle: 'View and manage race incidents',
          color: Colors.amber,
          onTap: () => context.push('/incidents/$_eventId'),
        ),
      ],
    );
  }
}

class _RcActionCard extends StatelessWidget {
  const _RcActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
