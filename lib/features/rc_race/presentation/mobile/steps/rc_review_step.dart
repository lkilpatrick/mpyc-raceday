import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../boat_checkin/presentation/boat_checkin_providers.dart';
import '../../../../demo/demo_mode_service.dart';
import '../../../../timing/data/models/timing_models.dart';
import '../../../../timing/presentation/timing_providers.dart';
import '../../../data/models/race_session.dart';
import '../../rc_race_providers.dart';

/// Step 6: Review results, finalize, and mark ready for Clubspot export.
class RcReviewStep extends ConsumerStatefulWidget {
  const RcReviewStep({super.key, required this.session});

  final RaceSession session;

  @override
  ConsumerState<RcReviewStep> createState() => _RcReviewStepState();
}

class _RcReviewStepState extends ConsumerState<RcReviewStep> {
  final _notesController = TextEditingController();
  bool _finalizing = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.session.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final raceStartId = session.raceStartId ?? '';
    final finishesAsync = ref.watch(finishRecordsProvider(raceStartId));
    final checkinCount = ref.watch(checkinCountProvider(session.id));
    final isFinalized = session.status == RaceSessionStatus.finalized;
    final isAbandoned = session.status == RaceSessionStatus.abandoned;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status card
        if (isFinalized)
          _StatusCard(
            icon: Icons.check_circle,
            color: Colors.green,
            title: 'Results Finalized',
            subtitle: session.finalizedAt != null
                ? 'Finalized ${DateFormat.yMMMd().add_jm().format(session.finalizedAt!)}'
                : 'Results are locked and ready for export.',
          ),
        if (isAbandoned)
          _StatusCard(
            icon: Icons.cancel,
            color: Colors.red,
            title: 'Race Abandoned',
            subtitle: session.abandonedReason?.isNotEmpty == true
                ? 'Reason: ${session.abandonedReason}'
                : 'Race was abandoned.',
          ),
        if (session.clubspotReady)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_upload, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Ready for Clubspot Export',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.indigo)),
              ],
            ),
          ),

        // Race summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Race Summary',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                _SummaryRow('Event', session.name),
                _SummaryRow('Date',
                    DateFormat.yMMMd().format(session.date)),
                _SummaryRow('Course',
                    'Course ${session.courseNumber ?? '?'} — ${session.courseName ?? 'Not set'}'),
                _SummaryRow('Boats Checked In', '$checkinCount'),
                if (session.startTime != null)
                  _SummaryRow('Start Time',
                      DateFormat.Hms().format(session.startTime!)),
                _SummaryRow('Start Method',
                    session.startMethod == 'horn'
                        ? 'Horn Detected'
                        : session.startMethod == 'manual'
                            ? 'Manual Override'
                            : '—'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Results table
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Results',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                finishesAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (finishes) {
                    if (finishes.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No finishes recorded',
                            style: TextStyle(color: Colors.grey)),
                      );
                    }

                    // Sort: finished boats by position, then specials
                    final sorted = [...finishes]..sort((a, b) {
                        if (a.letterScore == LetterScore.finished &&
                            b.letterScore == LetterScore.finished) {
                          return a.position.compareTo(b.position);
                        }
                        if (a.letterScore == LetterScore.finished) return -1;
                        if (b.letterScore == LetterScore.finished) return 1;
                        return 0;
                      });

                    return Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          color: Colors.grey.shade100,
                          child: const Row(
                            children: [
                              SizedBox(
                                  width: 36,
                                  child: Text('Pos',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              Expanded(
                                  child: Text('Boat',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              SizedBox(
                                  width: 70,
                                  child: Text('Elapsed',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              SizedBox(
                                  width: 50,
                                  child: Text('Status',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                            ],
                          ),
                        ),
                        ...sorted.map((f) {
                          final isFinished =
                              f.letterScore == LetterScore.finished;
                          final elapsed =
                              Duration(seconds: f.elapsedSeconds.toInt());
                          final elapsedStr = isFinished
                              ? '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}'
                              : '—';
                          final statusStr = isFinished
                              ? 'FIN'
                              : f.letterScore.name.toUpperCase();

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    isFinished ? '${f.position}' : '—',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isFinished
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${f.sailNumber}${f.boatName.isNotEmpty ? ' — ${f.boatName}' : ''}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                SizedBox(
                                  width: 70,
                                  child: Text(elapsedStr,
                                      style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12)),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isFinished
                                          ? Colors.green.shade50
                                          : Colors.orange.shade50,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      statusStr,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isFinished
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Notes
        if (!isFinalized)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Optional race notes...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Action buttons
        if (!isFinalized && !isAbandoned) ...[
          // Back to scoring
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _backToScoring(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Scoring'),
            ),
          ),
          const SizedBox(height: 8),
          // Finalize
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _finalizing ? null : () => _finalizeResults(),
              icon: _finalizing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock),
              label: Text(
                _finalizing ? 'Finalizing...' : 'Finalize Results',
                style: const TextStyle(fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
              ),
            ),
          ),
        ],

        if (isFinalized || isAbandoned) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home),
              label: const Text('Return to RC Home'),
            ),
          ),
          if (session.isDemo) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _resetDemo,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Demo Race'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _resetDemo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Demo Race?'),
        content: const Text(
          'This will clear all race data (check-ins, starts, finishes, broadcasts) '
          'and reset the demo race back to the setup step with fresh sample boats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await DemoModeService.resetDemoRace(widget.session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo race reset! Starting fresh.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }

  Future<void> _backToScoring() async {
    await ref
        .read(rcRaceRepositoryProvider)
        .updateStatus(widget.session.id, RaceSessionStatus.scoring);
  }

  Future<void> _finalizeResults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalize Results?'),
        content: const Text(
          'This will lock the results and mark them ready for Clubspot export.\n\n'
          'You will not be able to edit results after finalizing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('FINALIZE'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _finalizing = true);
    try {
      await ref.read(rcRaceRepositoryProvider).finalizeResults(
            widget.session.id,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _finalizing = false);
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
