import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../auth/data/auth_providers.dart';
import '../widgets/weather_header.dart';

/// Skipper check-in screen — shows race details, checks in the boat,
/// starts GPS tracking automatically on success.
class SkipperCheckinScreen extends ConsumerStatefulWidget {
  const SkipperCheckinScreen({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<SkipperCheckinScreen> createState() =>
      _SkipperCheckinScreenState();
}

class _SkipperCheckinScreenState extends ConsumerState<SkipperCheckinScreen> {
  bool _checking = false;
  bool _done = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(currentUserProvider);
    final member = memberAsync.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Check In')),
      body: Column(
        children: [
          const WeatherHeader(),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('race_events')
                  .doc(widget.eventId)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || !snap.data!.exists) {
                  return const Center(
                      child: Text('Race event not found',
                          style: TextStyle(color: Colors.grey)));
                }

                final d = snap.data!.data() as Map<String, dynamic>;
                final name = d['name'] as String? ?? 'Race Day';
                final status = d['status'] as String? ?? 'setup';
                final courseName = d['courseName'] as String?;
                final courseNumber = d['courseNumber'] as String?;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Race info card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.sailing,
                                      color: Colors.teal, size: 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (courseName != null)
                                Text(
                                    'Course ${courseNumber ?? ''} — $courseName',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700)),
                              Text('Status: $status',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Your boat info
                      if (member != null) ...[
                        Card(
                          color: Colors.teal.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Icon(Icons.directions_boat,
                                    color: Colors.teal),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Your Boat',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      Text(
                                        member.boatName ?? 'No boat name',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      if (member.sailNumber != null)
                                        Text('Sail: ${member.sailNumber}',
                                            style: const TextStyle(
                                                fontSize: 13)),
                                      if (member.boatClass != null)
                                        Text('Class: ${member.boatClass}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (member.sailNumber == null ||
                            member.sailNumber!.isEmpty)
                          Card(
                            color: Colors.orange.shade50,
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber,
                                      color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No sail number on your profile. '
                                      'Ask RC to update your member record.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],

                      const Spacer(),

                      // Error
                      if (_error != null) ...[
                        Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.error,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(_error!,
                                        style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 13))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Success
                      if (_done) ...[
                        Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 48),
                                const SizedBox(height: 8),
                                const Text(
                                  'You are checked in and transmitting!',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'GPS tracking has started automatically.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  child: const Text('Back to Home'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Check-in button
                      if (!_done)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: _checking ? null : _doCheckIn,
                            icon: _checking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(Icons.how_to_reg, size: 24),
                            label: Text(
                                _checking ? 'Checking in...' : 'Check In Now',
                                style: const TextStyle(fontSize: 18)),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doCheckIn() async {
    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      // 1. Ensure location permission
      final hasLocation = await _ensureLocationPermission();
      if (!hasLocation) {
        setState(() {
          _error = 'Location permission is required to check in and transmit GPS.';
          _checking = false;
        });
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        setState(() {
          _error = 'Not logged in.';
          _checking = false;
        });
        return;
      }

      final member = ref.read(currentUserProvider).value;

      // 2. Create check-in record
      await FirebaseFirestore.instance.collection('boat_checkins').add({
        'eventId': widget.eventId,
        'memberId': uid,
        'sailNumber': member?.sailNumber ?? '',
        'boatName': member?.boatName ?? '',
        'boatClass': member?.boatClass ?? '',
        'phrfRating': member?.phrfRating,
        'skipperName': member?.displayName ?? '',
        'status': 'checked_in',
        'checkedInAt': FieldValue.serverTimestamp(),
      });

      // 3. Write initial live position
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        await FirebaseFirestore.instance
            .collection('live_positions')
            .doc(uid)
            .set({
          'lat': pos.latitude,
          'lon': pos.longitude,
          'speedKnots': 0,
          'heading': pos.heading,
          'accuracy': pos.accuracy,
          'eventId': widget.eventId,
          'memberId': uid,
          'boatName': member?.boatName ?? '',
          'sailNumber': member?.sailNumber ?? '',
          'source': 'skipper',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Non-fatal — position will be written once race mode starts
      }

      HapticFeedback.heavyImpact();
      setState(() {
        _done = true;
        _checking = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Check-in failed: $e';
        _checking = false;
      });
    }
  }

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }
}
