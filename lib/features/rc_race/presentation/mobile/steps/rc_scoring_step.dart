import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../boat_checkin/presentation/boat_checkin_providers.dart';
import '../../../../timing/data/models/timing_models.dart';
import '../../../../timing/presentation/timing_providers.dart';
import '../../../data/models/race_session.dart';
import '../../rc_race_providers.dart';

/// Step 5: Scoring — tap boats to record finish, DNF, abandon.
class RcScoringStep extends ConsumerStatefulWidget {
  const RcScoringStep({super.key, required this.session});

  final RaceSession session;

  @override
  ConsumerState<RcScoringStep> createState() => _RcScoringStepState();
}

class _RcScoringStepState extends ConsumerState<RcScoringStep> {
  DateTime? _pendingFinishTime;
  int _nextPosition = 1;
  DateTime? _lastUndoDeadline;
  String? _lastFinishId;
  bool _autoReviewTriggered = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final raceStartId = widget.session.raceStartId ?? '';
    final finishesAsync = ref.watch(finishRecordsProvider(raceStartId));
    final checkinsAsync = ref.watch(eventCheckinsProvider(widget.session.id));

    return Column(
      children: [
        // Race clock
        if (widget.session.startTime != null)
          _ScoringClock(startTime: widget.session.startTime!),

        // BIG FINISH button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: 72,
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
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ),

        // Pending finish — select boat
        if (_pendingFinishTime != null)
          _PendingFinishCard(
            position: _nextPosition,
            pendingTime: _pendingFinishTime!,
            startTime: widget.session.startTime,
            checkins: checkinsAsync.value ?? [],
            finishes: finishesAsync.value ?? [],
            onBoatSelected: _confirmFinishForBoat,
            onCancel: () => setState(() => _pendingFinishTime = null),
          ),

        // Special score buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _SpecialBtn('DNF', Colors.orange, () => _recordSpecial(LetterScore.dnf)),
              const SizedBox(width: 6),
              _SpecialBtn('DNS', Colors.grey, () => _recordSpecial(LetterScore.dns)),
              const SizedBox(width: 6),
              _SpecialBtn('DSQ', Colors.red, () => _recordSpecial(LetterScore.dsq)),
              const SizedBox(width: 6),
              _SpecialBtn('OCS', Colors.red.shade300, () => _recordSpecial(LetterScore.ocs)),
            ],
          ),
        ),

        // Finish list
        Expanded(
          child: finishesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (finishes) {
              // Update next position
              final finishedCount = finishes
                  .where((f) => f.letterScore == LetterScore.finished)
                  .length;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _nextPosition != finishedCount + 1) {
                  setState(() => _nextPosition = finishedCount + 1);
                }
              });

              // Auto-move to review when all boats have a finish record
              final checkins = checkinsAsync.value ?? [];
              if (checkins.isNotEmpty &&
                  finishes.length >= checkins.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _autoMoveToReview();
                });
              }

              if (finishes.isEmpty) {
                return const Center(
                  child: Text('No finishes recorded yet',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: finishes.length,
                itemBuilder: (_, i) {
                  final f = finishes[i];
                  final elapsed =
                      Duration(seconds: f.elapsedSeconds.toInt());
                  final isFinished =
                      f.letterScore == LetterScore.finished;
                  final label = isFinished
                      ? '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}'
                      : f.letterScore.name.toUpperCase();

                  // Can undo if it's the last finish and within 30 seconds
                  final canUndo = i == finishes.length - 1 &&
                      _lastFinishId == f.id &&
                      _lastUndoDeadline != null &&
                      DateTime.now().isBefore(_lastUndoDeadline!);

                  return Card(
                    color: isFinished ? null : Colors.orange.shade50,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isFinished ? Colors.green : Colors.orange,
                        child: Text(
                          isFinished ? '${f.position}' : label[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        '${f.sailNumber}${f.boatName.isNotEmpty ? ' — ${f.boatName}' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(label),
                      trailing: canUndo
                          ? IconButton(
                              icon: const Icon(Icons.undo,
                                  color: Colors.orange),
                              onPressed: () => _undoFinish(f),
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Bottom actions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmAbandon(),
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                        label: const Text('Abandon',
                            style: TextStyle(color: Colors.red, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => _moveToReview(),
                        icon: const Icon(Icons.rate_review, size: 18),
                        label: const Text('Review Results',
                            style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton.icon(
                  onPressed: _backToRunning,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Racing',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onFinishTap() {
    HapticFeedback.heavyImpact();
    setState(() {
      _pendingFinishTime = DateTime.now();
    });
  }

  Future<void> _confirmFinishForBoat(String sailNumber, String boatName) async {
    if (_pendingFinishTime == null) return;

    final elapsed = widget.session.startTime != null
        ? _pendingFinishTime!
            .difference(widget.session.startTime!)
            .inSeconds
            .toDouble()
        : 0.0;

    final record = FinishRecord(
      id: '',
      raceStartId: widget.session.raceStartId ?? '',
      sailNumber: sailNumber,
      boatName: boatName,
      finishTimestamp: _pendingFinishTime!,
      elapsedSeconds: elapsed,
      letterScore: LetterScore.finished,
      position: _nextPosition,
    );

    final saved =
        await ref.read(timingRepositoryProvider).recordFinish(record);

    setState(() {
      _pendingFinishTime = null;
      _lastFinishId = saved.id;
      _lastUndoDeadline = DateTime.now().add(const Duration(seconds: 30));
      _nextPosition++;
    });
  }

  Future<void> _recordSpecial(LetterScore score) async {
    final checkinsAsync = ref.read(eventCheckinsProvider(widget.session.id));
    final checkins = checkinsAsync.value ?? [];

    final selected = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => _BoatPickerDialog(
        title: score.name.toUpperCase(),
        checkins: checkins,
      ),
    );
    if (selected == null) return;

    final record = FinishRecord(
      id: '',
      raceStartId: widget.session.raceStartId ?? '',
      sailNumber: selected['sailNumber']!,
      boatName: selected['boatName'] ?? '',
      finishTimestamp: DateTime.now(),
      elapsedSeconds: 0,
      letterScore: score,
      position: 0,
    );

    await ref.read(timingRepositoryProvider).recordFinish(record);
  }

  Future<void> _undoFinish(FinishRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Undo Finish?'),
        content: Text(
            'Remove ${record.sailNumber} at position ${record.position}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Undo'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(timingRepositoryProvider).deleteFinishRecord(record.id);
      setState(() {
        _nextPosition--;
        _lastFinishId = null;
        _lastUndoDeadline = null;
      });
    }
  }

  Future<void> _confirmAbandon() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Abandon Race?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This will end scoring and mark the race as abandoned.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('ABANDON'),
            ),
          ],
        );
      },
    );
    if (reason != null) {
      await ref
          .read(rcRaceRepositoryProvider)
          .abandonRace(widget.session.id, reason);
    }
  }

  Future<void> _autoMoveToReview() async {
    if (_autoReviewTriggered) return;
    _autoReviewTriggered = true;
    // Show a snackbar and auto-transition after a short delay
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All boats scored — moving to review...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      await ref
          .read(rcRaceRepositoryProvider)
          .moveToReview(widget.session.id);
    }
  }

  Future<void> _backToRunning() async {
    await ref
        .read(rcRaceRepositoryProvider)
        .updateStatus(widget.session.id, RaceSessionStatus.running);
  }

  Future<void> _moveToReview() async {
    await ref
        .read(rcRaceRepositoryProvider)
        .moveToReview(widget.session.id);
  }
}

class _ScoringClock extends StatelessWidget {
  const _ScoringClock({required this.startTime});

  final DateTime startTime;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final elapsed = DateTime.now().difference(startTime);
        final m = elapsed.inMinutes;
        final s = elapsed.inSeconds % 60;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: Colors.black,
          child: Text(
            '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }
}

/// Card shown after tapping FINISH — lets RC pick which boat crossed.
class _PendingFinishCard extends StatelessWidget {
  const _PendingFinishCard({
    required this.position,
    required this.pendingTime,
    required this.startTime,
    required this.checkins,
    required this.finishes,
    required this.onBoatSelected,
    required this.onCancel,
  });

  final int position;
  final DateTime pendingTime;
  final DateTime? startTime;
  final List checkins;
  final List<FinishRecord> finishes;
  final void Function(String sailNumber, String boatName) onBoatSelected;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    // Filter out boats that already finished
    final finishedSails =
        finishes.map((f) => f.sailNumber).toSet();
    final available = checkins
        .where((c) => !finishedSails.contains(c.sailNumber))
        .toList();

    final elapsed = startTime != null
        ? pendingTime.difference(startTime!).inSeconds
        : 0;
    final m = elapsed ~/ 60;
    final s = elapsed % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Position $position',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text(
                '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onCancel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Tap a boat:',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: available.map<Widget>((c) {
              return ActionChip(
                label: Text(c.sailNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                avatar: const Icon(Icons.sailing, size: 16),
                onPressed: () =>
                    onBoatSelected(c.sailNumber, c.boatName),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SpecialBtn extends StatelessWidget {
  const _SpecialBtn(this.label, this.color, this.onTap);

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 36,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _BoatPickerDialog extends StatelessWidget {
  const _BoatPickerDialog({required this.title, required this.checkins});

  final String title;
  final List checkins;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: checkins.length,
          itemBuilder: (_, i) {
            final c = checkins[i];
            return ListTile(
              leading: CircleAvatar(
                child: Text(c.sailNumber.length > 3
                    ? c.sailNumber.substring(c.sailNumber.length - 3)
                    : c.sailNumber,
                    style: const TextStyle(fontSize: 11)),
              ),
              title: Text('${c.boatName} (${c.sailNumber})'),
              onTap: () => Navigator.pop(context, {
                'sailNumber': c.sailNumber as String,
                'boatName': c.boatName as String,
              }),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
