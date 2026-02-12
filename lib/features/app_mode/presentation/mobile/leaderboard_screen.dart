import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

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
        builder: (context, eventSnap) {
          final eventDocs = eventSnap.data?.docs ?? [];
          if (eventDocs.isEmpty) {
            return const Center(
              child: Text('No race event today',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          final eventId = eventDocs.first.id;
          final eventData =
              eventDocs.first.data() as Map<String, dynamic>;
          final eventName = eventData['name'] as String? ?? 'Race Day';

          return Column(
            children: [
              // Event header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: Colors.indigo.shade50,
                child: Text(eventName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              // Results list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('race_events')
                      .doc(eventId)
                      .collection('results')
                      .orderBy('correctedTime')
                      .snapshots(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return _buildFinishFeed(eventId);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final d = docs[i].data() as Map<String, dynamic>;
                        final sail = d['sailNumber'] as String? ?? '';
                        final boat = d['boatName'] as String? ?? '';
                        final elapsed = d['elapsedSeconds'] as int? ?? 0;
                        final corrected =
                            d['correctedSeconds'] as int? ?? 0;
                        final phrf = d['phrfRating'] as int? ?? 0;
                        final position = i + 1;

                        return Card(
                          color: position <= 3
                              ? [
                                  Colors.amber.shade50,
                                  Colors.grey.shade100,
                                  Colors.orange.shade50,
                                ][position - 1]
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: position <= 3
                                  ? [
                                      Colors.amber,
                                      Colors.grey,
                                      Colors.orange,
                                    ][position - 1]
                                  : Colors.indigo.shade100,
                              child: Text('$position',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: position <= 3
                                        ? Colors.white
                                        : Colors.indigo,
                                  )),
                            ),
                            title: Text('$sail — $boat',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Elapsed: ${_formatSeconds(elapsed)} • '
                              'Corrected: ${_formatSeconds(corrected)} • '
                              'PHRF $phrf',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
    );
  }

  /// Fallback: show raw finish records if no corrected results yet
  Widget _buildFinishFeed(String eventId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('finish_records')
          .orderBy('finishTime', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('No finishes recorded yet',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 4),
                Text('Results will appear as boats cross the line',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final sail = d['sailNumber'] as String? ?? '?';
            final ts = d['finishTime'] as Timestamp?;
            final pos = d['position'] as int? ?? 0;

            return ListTile(
              leading: CircleAvatar(child: Text('$pos')),
              title: Text('Sail $sail',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: ts != null
                  ? Text(DateFormat.Hms().format(ts.toDate()),
                      style: const TextStyle(fontFamily: 'monospace'))
                  : null,
            );
          },
        );
      },
    );
  }

  String _formatSeconds(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h}h ${m}m ${s}s';
    }
    return '${m}m ${s}s';
  }
}
