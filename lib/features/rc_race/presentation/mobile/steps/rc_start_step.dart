import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../timing/data/models/timing_models.dart';
import '../../../../timing/presentation/timing_providers.dart';
import '../../../data/models/race_session.dart';
import '../../rc_race_providers.dart';

/// Step 3: Listen for horn start signal or manual override.
class RcStartStep extends ConsumerStatefulWidget {
  const RcStartStep({super.key, required this.session});

  final RaceSession session;

  @override
  ConsumerState<RcStartStep> createState() => _RcStartStepState();
}

class _RcStartStepState extends ConsumerState<RcStartStep> {
  bool _listening = false;
  bool _starting = false;
  double _currentDb = 0;
  double _peakDb = 0;
  int _listenSecondsLeft = 120; // 2 minutes
  Timer? _countdownTimer;
  StreamSubscription<NoiseReading>? _noiseSub;
  NoiseMeter? _noiseMeter;
  bool _hornDetected = false;
  bool _micPermissionDenied = false;

  // Horn detection threshold — a loud horn is typically > 85 dB
  static const _hornThresholdDb = 85.0;

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() => _micPermissionDenied = true);
      }
      return;
    }

    _noiseMeter = NoiseMeter();
    setState(() {
      _listening = true;
      _hornDetected = false;
      _listenSecondsLeft = 120;
      _currentDb = 0;
      _peakDb = 0;
    });

    // Start countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _listenSecondsLeft--;
      });
      if (_listenSecondsLeft <= 0) {
        _stopListening();
      }
    });

    // Start noise meter
    try {
      _noiseSub = _noiseMeter!.noise.listen((reading) {
        if (!mounted) return;
        final db = reading.meanDecibel;
        setState(() {
          _currentDb = db;
          if (db > _peakDb) _peakDb = db;
        });

        // Check for horn
        if (db >= _hornThresholdDb && !_hornDetected) {
          setState(() => _hornDetected = true);
          HapticFeedback.heavyImpact();
          _stopListening();
          _recordStart('horn');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _listening = false;
          _micPermissionDenied = true;
        });
      }
    }
  }

  void _stopListening() {
    _noiseSub?.cancel();
    _noiseSub = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (mounted) {
      setState(() => _listening = false);
    }
  }

  Future<void> _recordStart(String method) async {
    if (_starting) return;
    setState(() => _starting = true);

    try {
      final now = DateTime.now();

      // Create a race_start document
      final raceStart = await ref.read(timingRepositoryProvider).createRaceStart(
        RaceStart(
          id: '',
          eventId: widget.session.id,
          raceNumber: widget.session.raceNumber,
          className: widget.session.fleetClass ?? '',
          startTime: now,
        ),
      );

      // Update the session with start info
      await ref.read(rcRaceRepositoryProvider).recordStart(
            widget.session.id,
            raceStartId: raceStart.id,
            startTime: now,
            method: method,
          );

      if (mounted) {
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Start failed: $e')),
        );
        setState(() => _starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Course info
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.map, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Course ${widget.session.courseNumber ?? '?'} — ${widget.session.courseName ?? 'Not set'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_micPermissionDenied && !_listening) ...[
            Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.mic_off, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Microphone permission denied. Use Manual Start instead.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Listening state
          if (_listening) ...[
            // Sound level meter
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _hornDetected
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hornDetected ? Colors.green : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _hornDetected ? Icons.check_circle : Icons.mic,
                    size: 48,
                    color: _hornDetected ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _hornDetected ? 'HORN DETECTED!' : 'Listening for horn...',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _hornDetected ? Colors.green : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // dB meter bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_currentDb / 120).clamp(0, 1),
                      minHeight: 20,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        _currentDb >= _hornThresholdDb
                            ? Colors.red
                            : _currentDb >= 70
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_currentDb.toStringAsFixed(0)} dB',
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 16)),
                      Text('Peak: ${_peakDb.toStringAsFixed(0)} dB',
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Countdown
                  Text(
                    '${(_listenSecondsLeft ~/ 60)}:${(_listenSecondsLeft % 60).toString().padLeft(2, '0')} remaining',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cancel listening
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _stopListening,
                child: const Text('Stop Listening'),
              ),
            ),
          ],

          const Spacer(),

          // Big action buttons
          if (!_listening && !_starting) ...[
            // Listen for horn button
            SizedBox(
              width: double.infinity,
              height: 72,
              child: FilledButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.mic, size: 28),
                label: const Text('Listen for Horn',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Manual start button
            SizedBox(
              width: double.infinity,
              height: 72,
              child: FilledButton.icon(
                onPressed: () => _confirmManualStart(),
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text('Manual Start',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "Listen for Horn" to auto-detect the start signal,\nor use "Manual Start" to begin immediately.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],

          if (_starting)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Starting race...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmManualStart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Manual Start?'),
        content: const Text(
          'Start the race now with a manual timestamp.\n'
          'This will be recorded as a manual start in the race log.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('START NOW'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _recordStart('manual');
    }
  }
}
