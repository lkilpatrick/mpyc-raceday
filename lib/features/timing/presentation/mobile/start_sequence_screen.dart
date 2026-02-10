import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/timing_models.dart';
import '../../domain/signal_controller.dart';
import '../timing_providers.dart';

class StartSequenceScreen extends ConsumerStatefulWidget {
  const StartSequenceScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<StartSequenceScreen> createState() =>
      _StartSequenceScreenState();
}

class _StartSequenceScreenState extends ConsumerState<StartSequenceScreen> {
  Timer? _timer;
  int _countdownSeconds = 300; // 5 minutes
  bool _running = false;
  bool _started = false;
  String _className = 'Fleet';
  int _raceNumber = 1;
  RaceStart? _currentStart;

  // Flag states
  bool _warningFlag = false;
  bool _prepFlag = false;
  bool _individualRecall = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = _countdownSeconds.abs() ~/ 60;
    final secs = _countdownSeconds.abs() % 60;
    final isCountUp = _countdownSeconds < 0;
    final under10 = _countdownSeconds > 0 && _countdownSeconds <= 10;

    // Colors
    final bgColor = under10
        ? Colors.red.shade900
        : (_started ? Colors.green.shade900 : const Color(0xFF0D1B2A));
    final textColor = Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Race $_raceNumber — $_className',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Flag indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FlagIndicator(
                    label: 'CLASS',
                    active: _warningFlag,
                    color: Colors.yellow,
                  ),
                  _FlagIndicator(
                    label: 'PREP',
                    active: _prepFlag,
                    color: Colors.blue,
                  ),
                  _FlagIndicator(
                    label: 'X FLAG',
                    active: _individualRecall,
                    color: Colors.yellow.shade700,
                  ),
                  _FlagIndicator(
                    label: 'RACING',
                    active: _started,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode label
            Text(
              _started
                  ? 'RACING'
                  : (_running ? 'SEQUENCE RUNNING' : 'READY'),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),

            // LARGE countdown/countup display
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCountUp)
                      Text(
                        '+',
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Control buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  if (!_running && !_started)
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton(
                        onPressed: _startSequence,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'START SEQUENCE',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_running || _started) ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: FilledButton(
                              onPressed: _generalRecall,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'GENERAL\nRECALL',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: FilledButton(
                              onPressed: _individualRecallSignal,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.yellow.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'INDIVIDUAL\nRECALL',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: FilledButton(
                              onPressed: _postpone,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'POSTPONE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startSequence() async {
    final repo = ref.read(timingRepositoryProvider);
    final signal = ref.read(signalControllerProvider);

    // Create race start record
    _currentStart = await repo.createRaceStart(RaceStart(
      id: '',
      eventId: widget.eventId,
      raceNumber: _raceNumber,
      className: _className,
    ));

    // Fire warning signal
    final warningTime = await signal.fireWarningSignal();
    _currentStart = _currentStart!.copyWith(warningSignalTime: warningTime);
    await repo.updateRaceStart(_currentStart!);

    setState(() {
      _running = true;
      _warningFlag = true;
      _countdownSeconds = 300;
    });

    _haptic();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    setState(() {
      _countdownSeconds--;
    });

    // Signal events
    if (_countdownSeconds == 240) {
      // 4:00 — Preparatory
      _firePrepSignal();
    } else if (_countdownSeconds == 60) {
      // 1:00 — Remove prep
      _removePrepSignal();
    } else if (_countdownSeconds == 0) {
      // 0:00 — Start!
      _fireStartSignal();
    }

    // Audible beeps at minute marks
    if (_countdownSeconds > 0 &&
        _countdownSeconds % 60 == 0 &&
        _countdownSeconds <= 300) {
      _haptic();
    }

    // Rapid beeps at 10-second countdown
    if (_countdownSeconds > 0 && _countdownSeconds <= 10) {
      _haptic();
    }
  }

  Future<void> _firePrepSignal() async {
    final signal = ref.read(signalControllerProvider);
    final time = await signal.firePreparatorySignal();
    _currentStart = _currentStart!.copyWith(prepSignalTime: time);
    await ref.read(timingRepositoryProvider).updateRaceStart(_currentStart!);
    setState(() => _prepFlag = true);
    _haptic();
  }

  Future<void> _removePrepSignal() async {
    await ref.read(signalControllerProvider).removePreparatorySignal();
    setState(() => _prepFlag = false);
    _haptic();
  }

  Future<void> _fireStartSignal() async {
    final signal = ref.read(signalControllerProvider);
    final time = await signal.fireStartSignal();
    _currentStart = _currentStart!.copyWith(startTime: time);
    await ref.read(timingRepositoryProvider).updateRaceStart(_currentStart!);
    setState(() {
      _started = true;
      _running = false;
      _warningFlag = false;
      _prepFlag = false;
    });
    _haptic();
    // Timer continues counting up (negative countdown)
  }

  Future<void> _generalRecall() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('General Recall?'),
        content: const Text('This will reset the start sequence.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Recall')),
        ],
      ),
    );
    if (confirm != true) return;

    final signal = ref.read(signalControllerProvider);
    await signal.fireRecallSignal();

    if (_currentStart != null) {
      _currentStart = _currentStart!.copyWith(isGeneralRecall: true);
      await ref.read(timingRepositoryProvider).updateRaceStart(_currentStart!);
    }

    _timer?.cancel();
    setState(() {
      _running = false;
      _started = false;
      _warningFlag = false;
      _prepFlag = false;
      _individualRecall = false;
      _countdownSeconds = 300;
    });
    _haptic();
  }

  Future<void> _individualRecallSignal() async {
    final signal = ref.read(signalControllerProvider);
    await signal.fireIndividualRecallSignal();
    setState(() => _individualRecall = true);
    _haptic();
    // Auto-clear X flag after a delay
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) setState(() => _individualRecall = false);
    });
  }

  Future<void> _postpone() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Postpone Race?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Postpone')),
        ],
      ),
    );
    if (confirm != true) return;

    final signal = ref.read(signalControllerProvider);
    await signal.firePostponeSignal();

    if (_currentStart != null) {
      _currentStart = _currentStart!.copyWith(isPostponed: true);
      await ref.read(timingRepositoryProvider).updateRaceStart(_currentStart!);
    }

    _timer?.cancel();
    setState(() {
      _running = false;
      _started = false;
      _warningFlag = false;
      _prepFlag = false;
    });
    _haptic();
  }

  void _haptic() {
    HapticFeedback.heavyImpact();
  }
}

class _FlagIndicator extends StatelessWidget {
  const _FlagIndicator({
    required this.label,
    required this.active,
    required this.color,
  });

  final String label;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : Colors.grey.shade800,
            border: Border.all(
              color: active ? color : Colors.grey.shade600,
              width: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
