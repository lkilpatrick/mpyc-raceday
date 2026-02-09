import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/timing_models.dart';
import '../timing_providers.dart';

class TimingDashboardScreen extends ConsumerStatefulWidget {
  const TimingDashboardScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<TimingDashboardScreen> createState() =>
      _TimingDashboardScreenState();
}

class _TimingDashboardScreenState
    extends ConsumerState<TimingDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final startsAsync = ref.watch(raceStartsProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Race Timing')),
      body: startsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (starts) {
          // Find current/latest race
          final activeStart = starts.isNotEmpty ? starts.last : null;
          final raceNumber = activeStart?.raceNumber ?? 0;
          final totalRaces = starts.length;

          // Determine mode
          String mode;
          Color modeColor;
          if (activeStart == null || activeStart.startTime == null) {
            mode = 'PRE-START';
            modeColor = Colors.amber;
          } else {
            mode = 'RACING';
            modeColor = Colors.green;
          }
          if (activeStart?.isPostponed == true) {
            mode = 'POSTPONED';
            modeColor = Colors.red;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Mode indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: modeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    mode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Race info
                Text(
                  'Race $raceNumber of $totalRaces',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (activeStart != null)
                  Text(
                    activeStart.className,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: 24),

                // Timer display
                if (activeStart?.startTime != null)
                  _ElapsedTimer(startTime: activeStart!.startTime!),

                const SizedBox(height: 24),

                // Quick stats
                if (activeStart != null) ...[
                  Consumer(builder: (context, ref, _) {
                    final finishesAsync =
                        ref.watch(finishRecordsProvider(activeStart.id));
                    return finishesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (finishes) {
                        final finished = finishes
                            .where(
                                (f) => f.letterScore == LetterScore.finished)
                            .length;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatChip(
                                label: 'Finished', value: '$finished'),
                            _StatChip(
                                label: 'Total Recorded',
                                value: '${finishes.length}'),
                          ],
                        );
                      },
                    );
                  }),
                ],

                const Spacer(),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.go(
                            '/timing/start/${widget.eventId}'),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Sequence'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: activeStart?.startTime != null
                            ? () => context.go(
                                '/timing/finish/${activeStart!.id}')
                            : null,
                        icon: const Icon(Icons.flag),
                        label: const Text('Record Finishes'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: activeStart != null
                            ? () => context.go(
                                '/timing/results/${activeStart.id}')
                            : null,
                        icon: const Icon(Icons.leaderboard),
                        label: const Text('View Results'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ElapsedTimer extends StatefulWidget {
  const _ElapsedTimer({required this.startTime});
  final DateTime startTime;

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  late final Stream<int> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now().difference(widget.startTime).inSeconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticker,
      builder: (context, snap) {
        final elapsed = snap.data ?? 0;
        final mins = elapsed ~/ 60;
        final secs = elapsed % 60;
        return Text(
          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
