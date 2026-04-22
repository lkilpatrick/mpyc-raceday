import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/race_session.dart';
import '../rc_race_providers.dart';
import 'steps/rc_setup_step.dart';
import 'steps/rc_checkin_step.dart';
import 'steps/rc_start_step.dart';
import 'steps/rc_running_step.dart';
import 'steps/rc_scoring_step.dart';
import 'steps/rc_review_step.dart';

/// Guided RC race flow — stepper that walks through the full race lifecycle.
///
/// Uses ConsumerStatefulWidget to cache the session and avoid rebuilding the
/// entire step widget tree on every Firestore field change. Only status
/// transitions cause the step content to switch.
class RcRaceFlowScreen extends ConsumerStatefulWidget {
  const RcRaceFlowScreen({super.key, required this.eventId});

  final String eventId;

  static const _stepLabels = [
    'Setup',
    'Check-In',
    'Start',
    'Racing',
    'Scoring',
    'Review',
  ];

  @override
  ConsumerState<RcRaceFlowScreen> createState() => _RcRaceFlowScreenState();
}

class _RcRaceFlowScreenState extends ConsumerState<RcRaceFlowScreen> {
  RaceSession? _cachedSession;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionByIdProvider(widget.eventId));

    return Scaffold(
      body: sessionAsync.when(
        loading: () {
          // While loading, show cached session if available to avoid flash
          if (_cachedSession != null) {
            return _buildBody(_cachedSession!);
          }
          return const Center(child: CircularProgressIndicator());
        },
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (session) {
          if (session == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('Race session not found'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          _cachedSession = session;
          return _buildBody(session);
        },
      ),
    );
  }

  Widget _buildBody(RaceSession session) {
    final currentStep = session.status.stepIndex;

    return SafeArea(
      child: Column(
        children: [
          // Status banner
          _StatusBanner(session: session),

          // Step indicator
          _StepIndicator(
            currentStep: currentStep,
            status: session.status,
            onStepTapped: (stepIndex) => _onStepTapped(session, stepIndex),
          ),

          // Step content — keyed by status so it only rebuilds on status change
          Expanded(
            child: KeyedSubtree(
              key: ValueKey(session.status),
              child: _buildStepContent(session),
            ),
          ),
        ],
      ),
    );
  }

  /// Map step index back to the status it represents.
  static const _stepStatuses = [
    RaceSessionStatus.setup,
    RaceSessionStatus.checkinOpen,
    RaceSessionStatus.startPending,
    RaceSessionStatus.running,
    RaceSessionStatus.scoring,
    RaceSessionStatus.review,
  ];

  Future<void> _onStepTapped(RaceSession session, int stepIndex) async {
    final current = session.status.stepIndex;
    // Only allow tapping completed (earlier) steps or the current step
    if (stepIndex >= current) return;
    // Don't allow navigation from terminal states except abandoned
    if (session.status == RaceSessionStatus.finalized) return;

    final targetStatus = _stepStatuses[stepIndex];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Go Back?'),
        content: Text(
          'Return the race to "${targetStatus.label}"?\n\n'
          'No data will be lost — you can progress forward again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('GO BACK'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final repo = ref.read(rcRaceRepositoryProvider);
    if (session.status == RaceSessionStatus.abandoned) {
      await repo.unAbandonRace(widget.eventId, restoreTo: targetStatus);
    } else {
      await repo.updateStatus(widget.eventId, targetStatus);
    }
  }

  Widget _buildStepContent(RaceSession session) {
    return switch (session.status) {
      RaceSessionStatus.setup => RcSetupStep(session: session),
      RaceSessionStatus.checkinOpen => RcCheckinStep(session: session),
      RaceSessionStatus.startPending => RcStartStep(session: session),
      RaceSessionStatus.running => RcRunningStep(session: session),
      RaceSessionStatus.scoring => RcScoringStep(session: session),
      RaceSessionStatus.review ||
      RaceSessionStatus.finalized =>
        RcReviewStep(session: session),
      RaceSessionStatus.abandoned => RcReviewStep(session: session),
    };
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.session});

  final RaceSession session;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (session.status) {
      RaceSessionStatus.setup => (Colors.orange, Icons.settings),
      RaceSessionStatus.checkinOpen => (Colors.teal, Icons.how_to_reg),
      RaceSessionStatus.startPending => (Colors.amber, Icons.timer),
      RaceSessionStatus.running => (Colors.green, Icons.sailing),
      RaceSessionStatus.scoring => (Colors.blue, Icons.sports_score),
      RaceSessionStatus.review => (Colors.purple, Icons.rate_review),
      RaceSessionStatus.finalized => (Colors.indigo, Icons.check_circle),
      RaceSessionStatus.abandoned => (Colors.red, Icons.cancel),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                if (session.startTime != null &&
                    session.status == RaceSessionStatus.running)
                  _ElapsedClock(startTime: session.startTime!),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              session.status.label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElapsedClock extends StatelessWidget {
  const _ElapsedClock({required this.startTime});

  final DateTime startTime;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final elapsed = DateTime.now().difference(startTime);
        final h = elapsed.inHours;
        final m = elapsed.inMinutes % 60;
        final s = elapsed.inSeconds % 60;
        final label = h > 0
            ? '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s'
            : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        return Text('Race time: $label',
            style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold));
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.status,
    this.onStepTapped,
  });

  final int currentStep;
  final RaceSessionStatus status;
  final ValueChanged<int>? onStepTapped;

  static const _icons = [
    Icons.settings,
    Icons.how_to_reg,
    Icons.play_arrow,
    Icons.sailing,
    Icons.sports_score,
    Icons.check_circle,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(6, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          final isTappable = isDone &&
              status != RaceSessionStatus.finalized;
          final color = status.isTerminal && i == currentStep
              ? (status == RaceSessionStatus.abandoned
                  ? Colors.red
                  : Colors.green)
              : isActive
                  ? Colors.blue
                  : isDone
                      ? Colors.green
                      : Colors.grey.shade300;

          return Expanded(
            child: GestureDetector(
              onTap: isTappable ? () => onStepTapped?.call(i) : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDone || isActive
                          ? color
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check : _icons[i],
                      size: 16,
                      color: isDone || isActive
                          ? Colors.white
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    RcRaceFlowScreen._stepLabels[i],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
