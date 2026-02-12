import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/race_session.dart';
import '../rc_race_providers.dart';

/// Shows finalized and abandoned race sessions for review.
class RcRaceHistoryScreen extends ConsumerWidget {
  const RcRaceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(finalizedSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Race History')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('No finalized races yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Completed races will appear here.',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sessions.length,
            itemBuilder: (_, i) {
              final s = sessions[i];
              final isAbandoned =
                  s.status == RaceSessionStatus.abandoned;
              final color = isAbandoned ? Colors.red : Colors.green;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(
                      isAbandoned ? Icons.cancel : Icons.check_circle,
                      color: color,
                    ),
                  ),
                  title: Text(s.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat.yMMMd().format(s.date)),
                      if (s.courseName != null)
                        Text('Course ${s.courseNumber ?? ''} — ${s.courseName}',
                            style: const TextStyle(fontSize: 12)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s.status.label,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color),
                            ),
                          ),
                          if (s.clubspotReady) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CLUBSPOT READY',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => context.push('/rc-race/${s.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
