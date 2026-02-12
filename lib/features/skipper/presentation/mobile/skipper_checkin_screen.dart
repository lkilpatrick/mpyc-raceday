import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../auth/data/auth_providers.dart';
import '../../../boat_checkin/data/models/boat.dart';
import '../../../boat_checkin/presentation/boat_checkin_providers.dart';
import '../widgets/weather_header.dart';

/// Skipper check-in screen — select/change boat, then check in with GPS.
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
  bool _initialized = false;

  // Boat selection state
  Boat? _selectedFleetBoat; // null = custom / manual entry
  bool _useCustomBoat = false;
  final _sailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _phrfCtrl = TextEditingController();

  @override
  void dispose() {
    _sailCtrl.dispose();
    _nameCtrl.dispose();
    _classCtrl.dispose();
    _phrfCtrl.dispose();
    super.dispose();
  }

  /// Initialize form from member's saved boat, matching against fleet.
  void _initFromMember(List<Boat> fleet) {
    if (_initialized) return;
    _initialized = true;

    final member = ref.read(currentUserProvider).value;
    if (member == null) return;

    final savedSail = member.sailNumber ?? '';
    if (savedSail.isNotEmpty) {
      // Try to match member's saved boat to a fleet entry
      final match = fleet.where(
        (b) => b.sailNumber.toLowerCase() == savedSail.toLowerCase(),
      );
      if (match.isNotEmpty) {
        _selectedFleetBoat = match.first;
        _populateFromBoat(match.first);
        return;
      }
    }

    // No fleet match — populate from member profile
    _sailCtrl.text = savedSail;
    _nameCtrl.text = member.boatName ?? '';
    _classCtrl.text = member.boatClass ?? '';
    _phrfCtrl.text = member.phrfRating?.toString() ?? '';
    if (savedSail.isEmpty) _useCustomBoat = true;
  }

  void _populateFromBoat(Boat boat) {
    _sailCtrl.text = boat.sailNumber;
    _nameCtrl.text = boat.boatName;
    _classCtrl.text = boat.boatClass;
    _phrfCtrl.text = boat.phrfRating?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(currentUserProvider);
    final member = memberAsync.value;
    final fleetAsync = ref.watch(fleetProvider);
    final fleet = fleetAsync.value ?? [];

    // Initialize once when fleet loads
    _initFromMember(fleet);

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

                return ListView(
                  padding: const EdgeInsets.all(16),
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

                    // ── Boat Selection ──
                    const Text('Select Your Boat',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),

                    if (!_useCustomBoat && fleet.isNotEmpty) ...[
                      // Fleet dropdown
                      DropdownButtonFormField<Boat>(
                        value: _selectedFleetBoat,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          labelText: 'Boat from fleet',
                        ),
                        items: fleet.map((b) {
                          return DropdownMenuItem<Boat>(
                            value: b,
                            child: Text(
                              '${b.sailNumber} — ${b.boatName}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (boat) {
                          if (boat != null) {
                            setState(() {
                              _selectedFleetBoat = boat;
                              _populateFromBoat(boat);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() {
                            _useCustomBoat = true;
                            _selectedFleetBoat = null;
                            _sailCtrl.clear();
                            _nameCtrl.clear();
                            _classCtrl.clear();
                            _phrfCtrl.clear();
                          }),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Check in with a different boat'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.teal,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],

                    if (_useCustomBoat || fleet.isEmpty) ...[
                      if (fleet.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _useCustomBoat = false;
                            }),
                            icon: const Icon(Icons.list, size: 18),
                            label: const Text('Select from fleet list'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.teal,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 12),

                    // Editable boat fields (always visible)
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _sailCtrl,
                            decoration: InputDecoration(
                              labelText: 'Sail Number *',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Boat Name *',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _classCtrl,
                            decoration: InputDecoration(
                              labelText: 'Class',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _phrfCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'PHRF',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Boat info will be saved to your profile for next time.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),

                    const SizedBox(height: 20),

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
                    if (!_done) ...[
                      const SizedBox(height: 4),
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
                              _checking
                                  ? 'Checking in...'
                                  : 'Check In Now',
                              style: const TextStyle(fontSize: 18)),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doCheckIn() async {
    final sail = _sailCtrl.text.trim();
    final boatName = _nameCtrl.text.trim();
    if (sail.isEmpty || boatName.isEmpty) {
      setState(() => _error = 'Sail number and boat name are required.');
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      // 1. Ensure location permission
      final hasLocation = await _ensureLocationPermission();
      if (!hasLocation) {
        setState(() {
          _error =
              'Location permission is required to check in and transmit GPS.';
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
      final boatClass = _classCtrl.text.trim();
      final phrf = int.tryParse(_phrfCtrl.text.trim());

      // 2. Save boat info to member profile (persists for next time)
      await FirebaseFirestore.instance
          .collection('members')
          .doc(member?.id ?? uid)
          .update({
        'boatName': boatName,
        'sailNumber': sail,
        'boatClass': boatClass,
        'phrfRating': phrf,
      });

      // 3. Update fleet record if this boat exists, or create one
      if (_selectedFleetBoat != null) {
        // Update existing fleet boat if fields changed
        final fb = _selectedFleetBoat!;
        if (fb.boatName != boatName ||
            fb.boatClass != boatClass ||
            fb.phrfRating != phrf) {
          await FirebaseFirestore.instance
              .collection('boats')
              .doc(fb.id)
              .update({
            'boatName': boatName,
            'boatClass': boatClass,
            'phrfRating': phrf,
          });
        }
      } else if (_useCustomBoat && sail.isNotEmpty) {
        // Check if this sail number already exists in fleet
        final existing = await FirebaseFirestore.instance
            .collection('boats')
            .where('sailNumber', isEqualTo: sail)
            .limit(1)
            .get();
        if (existing.docs.isEmpty) {
          // Create new fleet entry
          await FirebaseFirestore.instance.collection('boats').add({
            'sailNumber': sail,
            'boatName': boatName,
            'ownerName': member?.displayName ?? '',
            'boatClass': boatClass,
            'phrfRating': phrf,
            'isActive': true,
            'isRCFleet': false,
            'raceCount': 0,
          });
        } else {
          // Update existing fleet entry
          await FirebaseFirestore.instance
              .collection('boats')
              .doc(existing.docs.first.id)
              .update({
            'boatName': boatName,
            'boatClass': boatClass,
            'phrfRating': phrf,
          });
        }
      }

      // 4. Create check-in record
      await FirebaseFirestore.instance.collection('boat_checkins').add({
        'eventId': widget.eventId,
        'memberId': uid,
        'sailNumber': sail,
        'boatName': boatName,
        'boatClass': boatClass,
        'phrfRating': phrf,
        'skipperName': member?.displayName ?? '',
        'status': 'checked_in',
        'checkedInAt': FieldValue.serverTimestamp(),
      });

      // 5. Write initial live position
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
          'boatName': boatName,
          'sailNumber': sail,
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
