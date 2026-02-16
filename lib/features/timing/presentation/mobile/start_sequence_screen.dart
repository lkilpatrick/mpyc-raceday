import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../boat_checkin/data/models/boat_checkin.dart';
import '../../../boat_checkin/presentation/boat_checkin_providers.dart';
import '../../../courses/data/models/fleet_broadcast.dart';
import '../../../courses/presentation/courses_providers.dart';
import '../../data/models/timing_models.dart';
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
  final String _className = 'Fleet';
  final int _raceNumber = 1;
  RaceStart? _currentStart;

  // Flag states
  bool _warningFlag = false;
  bool _prepFlag = false;
  bool _individualRecall = false;

  // Horn sound player
  final AudioPlayer _hornPlayer = AudioPlayer();

  @override
  void dispose() {
    _timer?.cancel();
    _hornPlayer.dispose();
    super.dispose();
  }

  /// Play the horn sound effect.
  Future<void> _playHorn() async {
    try {
      await _hornPlayer.stop();
      await _hornPlayer.play(AssetSource('racecalendar/horn.mp3'));
    } catch (_) {
      // Non-fatal — haptic fallback
    }
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
                    // Top row: General Recall + Postpone
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
                    const SizedBox(height: 12),
                    // Full-width Individual Recall button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton.icon(
                        onPressed: _individualRecallSignal,
                        icon: const Icon(Icons.flag, color: Colors.black),
                        label: const Text(
                          'INDIVIDUAL RECALL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.yellow.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Advance to next signal (skip timer forward)
                    if (_running && !_started)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _advanceToNextSignal,
                          icon: const Icon(Icons.skip_next, size: 22),
                          label: Text(
                            'ADVANCE TO $_nextSignalLabel',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.cyan.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (_running && !_started) const SizedBox(height: 12),
                    // Shorten Course + Abandon row
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _started ? _shortenCourse : null,
                              icon: const Icon(Icons.content_cut, size: 18),
                              label: const Text('SHORTEN\nCOURSE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.teal,
                                disabledBackgroundColor: Colors.teal.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _abandonRace,
                              icon: const Icon(Icons.cancel, size: 18),
                              label: const Text('ABANDON\nRACE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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

    // Fire warning signal — Rule 26: one horn at 5:00
    final warningTime = await signal.fireWarningSignal();
    _currentStart = _currentStart!.copyWith(warningSignalTime: warningTime);
    await repo.updateRaceStart(_currentStart!);

    setState(() {
      _running = true;
      _warningFlag = true;
      _countdownSeconds = 300;
    });

    _playHorn(); // Warning signal horn
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

  /// Label for the next signal point the timer would advance to.
  String get _nextSignalLabel {
    if (_countdownSeconds > 240) return 'PREP (4:00)';
    if (_countdownSeconds > 60) return 'PREP DOWN (1:00)';
    if (_countdownSeconds > 0) return 'START (0:00)';
    return 'START';
  }

  /// Advance the timer to the next signal point, firing the appropriate signal.
  void _advanceToNextSignal() {
    if (!_running || _started) return;

    if (_countdownSeconds > 240) {
      // Jump to 4:00 — fire prep signal
      setState(() => _countdownSeconds = 240);
      _firePrepSignal();
    } else if (_countdownSeconds > 60) {
      // Jump to 1:00 — remove prep
      setState(() => _countdownSeconds = 60);
      _removePrepSignal();
    } else if (_countdownSeconds > 0) {
      // Jump to 0:00 — start!
      setState(() => _countdownSeconds = 0);
      _fireStartSignal();
    }
  }

  Future<void> _firePrepSignal() async {
    final signal = ref.read(signalControllerProvider);
    final time = await signal.firePreparatorySignal();
    _currentStart = _currentStart!.copyWith(prepSignalTime: time);
    await ref.read(timingRepositoryProvider).updateRaceStart(_currentStart!);
    setState(() => _prepFlag = true);
    _playHorn(); // Rule 26: one horn at 4:00 (prep)
    _haptic();
  }

  Future<void> _removePrepSignal() async {
    await ref.read(signalControllerProvider).removePreparatorySignal();
    setState(() => _prepFlag = false);
    _playHorn(); // Rule 26: one long horn at 1:00 (prep removed)
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
    _playHorn(); // Rule 26: one horn at 0:00 (start)
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
    // Show boat selection dialog
    final checkinsAsync = ref.read(eventCheckinsProvider(widget.eventId));
    final checkins = checkinsAsync.value ?? [];

    final selected = await showDialog<List<BoatCheckin>>(
      context: context,
      builder: (dialogContext) => _RecallBoatPickerDialog(
        checkins: checkins,
      ),
    );
    if (selected == null || selected.isEmpty) return;

    final signal = ref.read(signalControllerProvider);
    await signal.fireIndividualRecallSignal();
    setState(() => _individualRecall = true);
    _playHorn();
    _haptic();

    // Send recall notification to selected boats via Firestore
    final batch = FirebaseFirestore.instance.batch();
    for (final boat in selected) {
      final notifRef = FirebaseFirestore.instance.collection('fleet_notifications').doc();
      batch.set(notifRef, {
        'eventId': widget.eventId,
        'type': 'individual_recall',
        'sailNumber': boat.sailNumber,
        'boatName': boat.boatName,
        'memberId': boat.boatId,
        'message': 'INDIVIDUAL RECALL: ${boat.sailNumber} — You were over the line at the start. Return and restart.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recall sent to ${selected.length} boat(s): ${selected.map((b) => b.sailNumber).join(", ")}'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    // Auto-clear X flag after a delay
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) setState(() => _individualRecall = false);
    });
  }

  /// Rule 32 — Shorten Course (S Flag + 2 horns)
  Future<void> _shortenCourse() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Shorten Course?'),
        content: const Text(
          'Rule 32: Display S Flag with two sound signals.\n'
          'Boats shall finish between the nearest mark and the RC boat.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Shorten Course')),
        ],
      ),
    );
    if (confirm != true) return;

    _playHorn();
    Future.delayed(const Duration(seconds: 2), _playHorn);
    _haptic();

    // Broadcast to fleet
    await ref.read(coursesRepositoryProvider).sendBroadcast(
          FleetBroadcast(
            id: '',
            eventId: widget.eventId,
            sentBy: 'RC',
            message: 'SHORTENED COURSE — S Flag displayed. Finish at the nearest mark.',
            type: BroadcastType.shortenCourse,
            sentAt: DateTime.now(),
            deliveryCount: 0,
            target: BroadcastTarget.everyone,
            requiresAck: false,
          ),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shortened course broadcast sent'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  /// Rule 32.1 — Abandon Race (N Flag + 3 horns)
  Future<void> _abandonRace() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Abandon Race — Select Reason'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'Too much wind'),
            child: const ListTile(
              leading: Icon(Icons.air, color: Colors.red),
              title: Text('Too Much Wind'),
              subtitle: Text('Unsafe conditions — wind exceeds limits'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'Too little wind'),
            child: const ListTile(
              leading: Icon(Icons.cloud_off, color: Colors.amber),
              title: Text('Too Little Wind'),
              subtitle: Text('Insufficient wind to complete the race'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'Shifting wind'),
            child: const ListTile(
              leading: Icon(Icons.explore, color: Colors.orange),
              title: Text('Shifting Wind'),
              subtitle: Text('Wind direction too unstable for fair racing'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'Safety concern'),
            child: const ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text('Safety Concern'),
              subtitle: Text('Other safety issue requiring abandonment'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'Other'),
            child: const ListTile(
              leading: Icon(Icons.more_horiz, color: Colors.grey),
              title: Text('Other'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
    if (reason == null) return;

    // 3 horns for abandonment
    _playHorn();
    Future.delayed(const Duration(seconds: 2), _playHorn);
    Future.delayed(const Duration(seconds: 4), _playHorn);
    _haptic();

    // Update race start
    if (_currentStart != null) {
      await ref.read(timingRepositoryProvider).updateRaceStart(
            _currentStart!.copyWith(isPostponed: true),
          );
    }

    // Determine broadcast type
    final broadcastType = switch (reason) {
      'Too much wind' => BroadcastType.abandonTooMuchWind,
      'Too little wind' => BroadcastType.abandonTooLittleWind,
      _ => BroadcastType.abandonment,
    };

    // Broadcast to fleet
    await ref.read(coursesRepositoryProvider).sendBroadcast(
          FleetBroadcast(
            id: '',
            eventId: widget.eventId,
            sentBy: 'RC',
            message: 'RACE ABANDONED — N Flag displayed. Reason: $reason. All boats return to harbor.',
            type: broadcastType,
            sentAt: DateTime.now(),
            deliveryCount: 0,
            target: BroadcastTarget.everyone,
            requiresAck: false,
          ),
        );

    _timer?.cancel();
    setState(() {
      _running = false;
      _started = false;
      _warningFlag = false;
      _prepFlag = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Race abandoned: $reason'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// AP Flag — Postpone (2 horns)
  Future<void> _postpone() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Postpone Race?'),
        content: const Text('AP Flag will be displayed with two sound signals.'),
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

    // 2 horns for postponement
    _playHorn();
    Future.delayed(const Duration(seconds: 2), _playHorn);

    if (_currentStart != null) {
      _currentStart = _currentStart!.copyWith(isPostponed: true);
      await ref.read(timingRepositoryProvider).updateRaceStart(_currentStart!);
    }

    // Broadcast to fleet
    await ref.read(coursesRepositoryProvider).sendBroadcast(
          FleetBroadcast(
            id: '',
            eventId: widget.eventId,
            sentBy: 'RC',
            message: 'RACE POSTPONED — AP Flag displayed. Stand by for further instructions.',
            type: BroadcastType.postponement,
            sentAt: DateTime.now(),
            deliveryCount: 0,
            target: BroadcastTarget.everyone,
            requiresAck: false,
          ),
        );

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

/// Multi-select dialog for picking boats to recall.
class _RecallBoatPickerDialog extends StatefulWidget {
  const _RecallBoatPickerDialog({required this.checkins});

  final List<BoatCheckin> checkins;

  @override
  State<_RecallBoatPickerDialog> createState() =>
      _RecallBoatPickerDialogState();
}

class _RecallBoatPickerDialogState extends State<_RecallBoatPickerDialog> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Boats to Recall'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: widget.checkins.isEmpty
            ? const Center(child: Text('No boats checked in'))
            : ListView.builder(
                itemCount: widget.checkins.length,
                itemBuilder: (_, i) {
                  final c = widget.checkins[i];
                  final isSelected = _selectedIds.contains(c.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIds.add(c.id);
                        } else {
                          _selectedIds.remove(c.id);
                        }
                      });
                    },
                    title: Text('${c.sailNumber} — ${c.boatName}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(c.skipperName),
                    secondary: CircleAvatar(
                      backgroundColor:
                          isSelected ? Colors.orange : Colors.grey.shade300,
                      child: Text(
                        c.sailNumber.length > 3
                            ? c.sailNumber.substring(c.sailNumber.length - 3)
                            : c.sailNumber,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () {
                  final selected = widget.checkins
                      .where((c) => _selectedIds.contains(c.id))
                      .toList();
                  Navigator.pop(context, selected);
                },
          style: FilledButton.styleFrom(backgroundColor: Colors.orange),
          child: Text('Recall ${_selectedIds.length} Boat(s)'),
        ),
      ],
    );
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
