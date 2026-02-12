import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SpectatorScreen extends ConsumerWidget {
  const SpectatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Race View')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Race status
          const _RaceStatusCard(),
          const SizedBox(height: 12),

          // Live leaderboard mini
          const _LiveLeaderboardMini(),
          const SizedBox(height: 12),

          // Weather
          const _WeatherMini(),
          const SizedBox(height: 12),

          // Race replay access
          Card(
            child: InkWell(
              onTap: () => context.push('/race-replay'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.replay, color: Colors.purple.shade700),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Race Replay',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('View recorded GPS tracks from today',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Notice board
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.campaign, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('Notice Board',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notices')
                        .orderBy('createdAt', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snap) {
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Text('No notices posted',
                            style: TextStyle(color: Colors.grey));
                      }
                      return Column(
                        children: docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          final title = d['title'] as String? ?? '';
                          final body = d['body'] as String? ?? '';
                          final ts = d['createdAt'] as Timestamp?;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            subtitle: Text(body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                            trailing: ts != null
                                ? Text(
                                    DateFormat.jm().format(ts.toDate()),
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  )
                                : null,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaceStatusCard extends StatelessWidget {
  const _RaceStatusCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_events')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.sailing, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  const Text('No race today',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final d = docs.first.data() as Map<String, dynamic>;
        final name = d['name'] as String? ?? 'Race Day';
        final status = d['status'] as String? ?? 'setup';
        final courseId = d['courseId'] as String? ?? '';

        final (statusLabel, statusColor) = switch (status) {
          'setup' => ('Setting Up', Colors.orange),
          'racing' => ('RACING', Colors.green),
          'complete' => ('Complete', Colors.blue),
          _ => ('—', Colors.grey),
        };

        return Card(
          color: statusColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sailing, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                if (courseId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Course: $courseId',
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiveLeaderboardMini extends StatelessWidget {
  const _LiveLeaderboardMini();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/leaderboard'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.leaderboard, color: Colors.amber.shade800),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Leaderboard',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Real-time scoring & corrected times',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
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

class _WeatherMini extends StatelessWidget {
  const _WeatherMini();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('weather')
          .doc('mpyc_station')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }
        final d = snap.data!.data() as Map<String, dynamic>? ?? {};
        final wind = (d['speedKts'] as num?)?.toDouble() ?? 0;
        final dir = (d['dirDeg'] as num?)?.toInt() ?? 0;
        final temp = (d['tempF'] as num?)?.toDouble();

        return Card(
          color: Colors.blue.shade50,
          child: InkWell(
            onTap: () => context.push('/live-wind'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.air, color: Colors.blue, size: 24),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${wind.toStringAsFixed(0)} kts from $dir°',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (temp != null)
                        Text('${temp.toStringAsFixed(0)}°F',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
