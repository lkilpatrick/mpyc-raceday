import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/data/auth_providers.dart';
import '../widgets/weather_header.dart';

/// Skipper Results screen — view race results, your boat's finish,
/// and browse past races.
class SkipperResultsScreen extends ConsumerWidget {
  const SkipperResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentUserProvider);
    final member = memberAsync.value;
    final mySail = member?.sailNumber ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Race Results')),
      body: Column(
        children: [
          const WeatherHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('race_events')
                  .where('status',
                      whereIn: ['finalized', 'review', 'scoring', 'running'])
                  .orderBy('date', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.leaderboard,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        const Text('No race results yet',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final name = d['name'] as String? ?? 'Race';
                    final date =
                        (d['date'] as Timestamp?)?.toDate();
                    final status = d['status'] as String? ?? '';
                    final raceStartId =
                        d['raceStartId'] as String?;

                    return _RaceResultCard(
                      eventId: doc.id,
                      name: name,
                      date: date,
                      status: status,
                      raceStartId: raceStartId,
                      mySailNumber: mySail,
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
}

class _RaceResultCard extends StatelessWidget {
  const _RaceResultCard({
    required this.eventId,
    required this.name,
    required this.date,
    required this.status,
    required this.raceStartId,
    required this.mySailNumber,
  });

  final String eventId;
  final String name;
  final DateTime? date;
  final String status;
  final String? raceStartId;
  final String mySailNumber;

  @override
  Widget build(BuildContext context) {
    final isComplete = ['finalized', 'review'].contains(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(
          isComplete ? Icons.check_circle : Icons.sailing,
          color: isComplete ? Colors.green : Colors.blue,
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            if (date != null)
              Text(DateFormat.MMMd().format(date!),
                  style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isComplete
                    ? Colors.green.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.green : Colors.blue),
              ),
            ),
          ],
        ),
        children: [
          if (raceStartId == null || raceStartId!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No finish records for this race.',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            _FinishList(
              raceStartId: raceStartId!,
              mySailNumber: mySailNumber,
            ),
        ],
      ),
    );
  }
}

class _FinishList extends StatelessWidget {
  const _FinishList({
    required this.raceStartId,
    required this.mySailNumber,
  });

  final String raceStartId;
  final String mySailNumber;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('finish_records')
          .where('raceStartId', isEqualTo: raceStartId)
          .orderBy('position')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No finishes recorded yet.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                        width: 28,
                        child: Text('#',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.grey))),
                    Expanded(
                        child: Text('Boat',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.grey))),
                    SizedBox(
                        width: 70,
                        child: Text('Elapsed',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.grey))),
                    SizedBox(
                        width: 50,
                        child: Text('Status',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.grey))),
                  ],
                ),
              ),
              ...docs.map((doc) {
                final f = doc.data() as Map<String, dynamic>;
                final pos = f['position'] as int? ?? 0;
                final sail = f['sailNumber'] as String? ?? '';
                final boat = f['boatName'] as String? ?? '';
                final elapsed =
                    (f['elapsedSeconds'] as num?)?.toDouble() ?? 0;
                final letterScore =
                    f['letterScore'] as String? ?? 'finished';
                final isFinished = letterScore == 'finished';
                final isMe = mySailNumber.isNotEmpty &&
                    sail == mySailNumber;

                final dur = Duration(seconds: elapsed.toInt());
                final timeStr = isFinished
                    ? '${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}'
                    : '—';

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.teal.shade50 : null,
                    border: Border(
                      bottom:
                          BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          isFinished ? '$pos' : '—',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: pos <= 3 && isFinished
                                ? Colors.amber.shade800
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Text(sail,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isMe
                                        ? Colors.teal
                                        : null)),
                            if (boat.isNotEmpty)
                              Text(' $boat',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                            if (isMe)
                              const Text(' (You)',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(timeStr,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12)),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          letterScore.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isFinished
                                  ? Colors.green
                                  : Colors.orange),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
