import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../auth/data/auth_providers.dart';

class SkipperCheckinScreen extends ConsumerStatefulWidget {
  const SkipperCheckinScreen({super.key});

  @override
  ConsumerState<SkipperCheckinScreen> createState() =>
      _SkipperCheckinScreenState();
}

class _SkipperCheckinScreenState extends ConsumerState<SkipperCheckinScreen> {
  int _soulsOnBoard = 2;
  bool _checkedIn = false;
  bool _loading = false;
  String? _eventId;
  String _eventName = '';

  @override
  void initState() {
    super.initState();
    _loadTodaysEvent();
  }

  Future<void> _loadTodaysEvent() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    try {
      final snap = await FirebaseFirestore.instance
          .collection('race_events')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        final d = snap.docs.first.data();
        setState(() {
          _eventId = snap.docs.first.id;
          _eventName = d['name'] as String? ?? 'Race Day';
        });
        _checkExistingCheckin();
      }
    } catch (_) {}
  }

  Future<void> _checkExistingCheckin() async {
    if (_eventId == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('boat_checkins')
          .where('eventId', isEqualTo: _eventId)
          .where('skipperUid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        setState(() => _checkedIn = true);
      }
    } catch (_) {}
  }

  Future<void> _remoteCheckin() async {
    if (_eventId == null) return;
    setState(() => _loading = true);

    Position? position;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      }
    } catch (_) {}

    final member = ref.read(currentUserProvider).value;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      await FirebaseFirestore.instance.collection('boat_checkins').add({
        'eventId': _eventId,
        'skipperUid': uid,
        'skipperName': member?.displayName ?? '',
        'sailNumber': member?.sailNumber ?? '',
        'boatName': member?.boatName ?? '',
        'boatClass': member?.boatClass ?? '',
        'soulsOnBoard': _soulsOnBoard,
        'checkinMethod': 'remote_gps',
        'checkinTime': FieldValue.serverTimestamp(),
        if (position != null) 'lat': position.latitude,
        if (position != null) 'lon': position.longitude,
      });

      if (mounted) {
        setState(() {
          _checkedIn = true;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Checked in with $_soulsOnBoard souls on board'
              '${position != null ? " • GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}" : ""}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Race Check-In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_eventId == null) ...[
              const Expanded(
                child: Center(
                  child: Text('No race event today',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              ),
            ] else ...[
              // Event info
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.sailing, color: Colors.teal.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_eventName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            if (member?.boatName != null)
                              Text('${member!.boatName} • ${member.sailNumber ?? ""}',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_checkedIn) ...[
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 72, color: Colors.green),
                        SizedBox(height: 12),
                        Text('Checked In',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        SizedBox(height: 4),
                        Text('Race Committee has been notified',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Souls on board
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Souls on Board',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        const Text(
                          'How many people are on your boat?',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filled(
                              onPressed: _soulsOnBoard > 1
                                  ? () => setState(() => _soulsOnBoard--)
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            const SizedBox(width: 24),
                            Text('$_soulsOnBoard',
                                style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 24),
                            IconButton.filled(
                              onPressed: () =>
                                  setState(() => _soulsOnBoard++),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),

                // Check-in button
                SizedBox(
                  height: 64,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _remoteCheckin,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.gps_fixed, size: 24),
                    label: Text(
                      _loading ? 'Checking in...' : 'Check In via GPS',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your GPS position and souls on board will be sent to the Race Committee',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
