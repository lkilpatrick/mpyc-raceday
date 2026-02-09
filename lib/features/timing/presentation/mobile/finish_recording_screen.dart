import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/models/timing_models.dart';
import '../timing_providers.dart';

class FinishRecordingScreen extends ConsumerStatefulWidget {
  const FinishRecordingScreen({super.key, required this.raceStartId});

  final String raceStartId;

  @override
  ConsumerState<FinishRecordingScreen> createState() =>
      _FinishRecordingScreenState();
}

class _FinishRecordingScreenState
    extends ConsumerState<FinishRecordingScreen> {
  DateTime? _startTime;
  final _sailController = TextEditingController();
  DateTime? _pendingFinishTime;
  int _nextPosition = 1;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _sailController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finishesAsync =
        ref.watch(finishRecordsProvider(widget.raceStartId));
    final startsAsync = ref.watch(raceStartsProvider(''));

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // Top: race clock
            _RaceClock(
              raceStartId: widget.raceStartId,
              onStartTimeResolved: (t) => _startTime = t,
            ),

            // BIG FINISH button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 80,
                child: FilledButton(
                  onPressed: _onFinishTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'FINISH',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
            ),

            // Sail number entry (shown after FINISH tap)
            if (_pendingFinishTime != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Card(
                  color: Colors.green.shade900,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          'Position $_nextPosition — Enter Sail #',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _sailController,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Sail #',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white54),
                                  ),
                                ),
                                onSubmitted: (_) => _confirmFinish(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 56,
                              child: FilledButton(
                                onPressed: _confirmFinish,
                                child: const Icon(Icons.check, size: 28),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Special score buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  _SpecialButton('DNF', Colors.orange, LetterScore.dnf),
                  const SizedBox(width: 6),
                  _SpecialButton('DNS', Colors.grey, LetterScore.dns),
                  const SizedBox(width: 6),
                  _SpecialButton('DSQ', Colors.red, LetterScore.dsq),
                  const SizedBox(width: 6),
                  _SpecialButton('OCS', Colors.red.shade300, LetterScore.ocs),
                  const SizedBox(width: 6),
                  _SpecialButton('RAF', Colors.purple, LetterScore.raf),
                  const SizedBox(width: 6),
                  _SpecialButton('RET', Colors.brown, LetterScore.ret),
                ],
              ),
            ),

            // Finish list
            Expanded(
              child: finishesAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
                error: (e, _) =>
                    Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                data: (finishes) {
                  if (finishes.isEmpty) {
                    return const Center(
                      child: Text(
                        'No finishes recorded yet',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: finishes.length,
                    itemBuilder: (_, i) {
                      final f = finishes[i];
                      final elapsed = Duration(
                          seconds: f.elapsedSeconds.toInt());
                      final label = f.letterScore == LetterScore.finished
                          ? '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}'
                          : f.letterScore.name.toUpperCase();
                      return Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Text(
                              '${f.position}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            f.sailNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            label,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: i == finishes.length - 1
                              ? IconButton(
                                  icon: const Icon(Icons.undo,
                                      color: Colors.orange),
                                  onPressed: () => _undoLast(f),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _SpecialButton(String label, Color color, LetterScore score) {
    return Expanded(
      child: SizedBox(
        height: 40,
        child: FilledButton(
          onPressed: () => _recordSpecial(score),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _onFinishTap() {
    HapticFeedback.heavyImpact();
    setState(() {
      _pendingFinishTime = DateTime.now();
      _sailController.clear();
    });
  }

  Future<void> _confirmFinish() async {
    final sail = _sailController.text.trim();
    if (sail.isEmpty || _pendingFinishTime == null) return;

    final elapsed = _startTime != null
        ? _pendingFinishTime!.difference(_startTime!).inSeconds.toDouble()
        : 0.0;

    final record = FinishRecord(
      id: '',
      raceStartId: widget.raceStartId,
      sailNumber: sail,
      finishTimestamp: _pendingFinishTime!,
      elapsedSeconds: elapsed,
      letterScore: LetterScore.finished,
      position: _nextPosition,
    );

    await ref.read(timingRepositoryProvider).recordFinish(record);

    setState(() {
      _pendingFinishTime = null;
      _nextPosition++;
      _sailController.clear();
    });
  }

  Future<void> _recordSpecial(LetterScore score) async {
    final sailController = TextEditingController();
    final sail = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(score.name.toUpperCase()),
        content: TextField(
          controller: sailController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Sail Number'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, sailController.text.trim()),
            child: const Text('Record'),
          ),
        ],
      ),
    );
    if (sail == null || sail.isEmpty) return;

    final record = FinishRecord(
      id: '',
      raceStartId: widget.raceStartId,
      sailNumber: sail,
      finishTimestamp: DateTime.now(),
      elapsedSeconds: 0,
      letterScore: score,
      position: 0,
    );

    await ref.read(timingRepositoryProvider).recordFinish(record);
  }

  Future<void> _undoLast(FinishRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Undo Last Finish?'),
        content: Text('Remove ${record.sailNumber} at position ${record.position}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Undo')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(timingRepositoryProvider).deleteFinishRecord(record.id);
      setState(() => _nextPosition--);
    }
  }
}

class _RaceClock extends ConsumerStatefulWidget {
  const _RaceClock({
    required this.raceStartId,
    required this.onStartTimeResolved,
  });

  final String raceStartId;
  final ValueChanged<DateTime> onStartTimeResolved;

  @override
  ConsumerState<_RaceClock> createState() => _RaceClockState();
}

class _RaceClockState extends ConsumerState<_RaceClock> {
  late final Stream<int> _ticker;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(const Duration(seconds: 1), (i) => i);
  }

  @override
  Widget build(BuildContext context) {
    // Try to resolve start time from race starts
    final startsAsync = ref.watch(raceStartsProvider(''));

    return StreamBuilder<int>(
      stream: _ticker,
      builder: (context, _) {
        // Find start time from any available source
        if (_startTime == null) {
          startsAsync.whenData((starts) {
            for (final s in starts) {
              if (s.id == widget.raceStartId && s.startTime != null) {
                _startTime = s.startTime;
                widget.onStartTimeResolved(s.startTime!);
              }
            }
          });
        }

        final elapsed = _startTime != null
            ? DateTime.now().difference(_startTime!).inSeconds
            : 0;
        final mins = elapsed ~/ 60;
        final secs = elapsed % 60;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.black,
          child: Text(
            '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }
}
