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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('race_events')
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
            .where('date', isLessThan: Timestamp.fromDate(todayEnd))
            .limit(1)
            .snapshots(),
        builder: (context, eventSnap) {
          if (eventSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final eventDocs = eventSnap.data?.docs ?? [];
          if (eventDocs.isEmpty) {
            return _emptyState(
              icon: Icons.event_busy,
              title: 'No race event today',
              subtitle: 'Scoring will be available on race day',
            );
          }

          final eventId = eventDocs.first.id;
          final eventData =
              eventDocs.first.data() as Map<String, dynamic>;
          final eventName = eventData['name'] as String? ?? 'Race Day';
          final raceStartId = eventData['raceStartId'] as String? ?? '';
          final status = eventData['status'] as String? ?? 'setup';

          return Column(
            children: [
              // Event header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.indigo.shade100),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.leaderboard,
                        color: Colors.indigo, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(eventName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text(_statusLabel(status),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Results
              Expanded(
                child: raceStartId.isNotEmpty
                    ? _buildFinishResults(context, raceStartId)
                    : _buildRaceStartFinder(context, eventId),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Find race starts for the event and show their finish records.
  Widget _buildRaceStartFinder(BuildContext context, String eventId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_starts')
          .where('eventId', isEqualTo: eventId)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState(
            icon: Icons.hourglass_empty,
            title: 'No races started yet',
            subtitle: 'Results will appear once a race starts',
          );
        }

        // Use the most recent race start
        final latestDoc = docs.last;
        return _buildFinishResults(context, latestDoc.id);
      },
    );
  }

  /// Show finish records for a given raceStartId from the top-level
  /// `finish_records` collection.
  Widget _buildFinishResults(BuildContext context, String raceStartId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('finish_records')
          .where('raceStartId', isEqualTo: raceStartId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState(
            icon: Icons.hourglass_empty,
            title: 'No finishes recorded yet',
            subtitle: 'Results will appear as boats cross the line',
          );
        }

        // Sort by position client-side
        final sorted = [...docs];
        sorted.sort((a, b) {
          final aPos = (a.data() as Map<String, dynamic>)['position'] as int? ?? 999;
          final bPos = (b.data() as Map<String, dynamic>)['position'] as int? ?? 999;
          return aPos.compareTo(bPos);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: sorted.length,
          itemBuilder: (_, i) {
            final d = sorted[i].data() as Map<String, dynamic>;
            final sail = d['sailNumber'] as String? ?? '?';
            final boat = d['boatName'] as String? ?? '';
            final elapsed =
                (d['elapsedSeconds'] as num?)?.toDouble() ?? 0;
            final corrected =
                (d['correctedSeconds'] as num?)?.toDouble();
            final letterScore =
                d['letterScore'] as String? ?? 'finished';
            final pos = d['position'] as int? ?? (i + 1);
            final isFinished = letterScore == 'finished';

            return Card(
              color: pos <= 3 && isFinished
                  ? [
                      Colors.amber.shade50,
                      Colors.grey.shade100,
                      Colors.orange.shade50,
                    ][pos - 1]
                  : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: pos <= 3 && isFinished
                      ? [
                          Colors.amber,
                          Colors.grey.shade400,
                          Colors.orange,
                        ][pos - 1]
                      : isFinished
                          ? Colors.indigo.shade100
                          : Colors.red.shade100,
                  child: isFinished
                      ? Text('$pos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: pos <= 3
                                ? Colors.white
                                : Colors.indigo,
                          ))
                      : Text(letterScore.toUpperCase().substring(0, 3),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                ),
                title: Text(
                  boat.isNotEmpty ? '$sail — $boat' : 'Sail $sail',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: isFinished
                    ? Text(
                        'Elapsed: ${_formatSeconds(elapsed.toInt())}'
                        '${corrected != null ? ' • Corrected: ${_formatSeconds(corrected.toInt())}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      )
                    : Text(letterScore.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.red)),
                trailing: isFinished
                    ? Text(
                        _formatFinishTime(d),
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  String _formatFinishTime(Map<String, dynamic> d) {
    final ts = d['finishTimestamp'] as Timestamp?;
    if (ts != null) return DateFormat.Hms().format(ts.toDate());
    final ft = d['finishTime'] as Timestamp?;
    if (ft != null) return DateFormat.Hms().format(ft.toDate());
    return '';
  }

  String _formatSeconds(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  String _statusLabel(String status) => switch (status) {
        'setup' => 'Setting up',
        'checkin_open' => 'Check-in open',
        'start_pending' => 'Start pending',
        'running' => 'Race in progress',
        'scoring' => 'Scoring',
        'review' => 'Under review',
        'finalized' => 'Results final',
        'abandoned' => 'Abandoned',
        _ => status,
      };
}
