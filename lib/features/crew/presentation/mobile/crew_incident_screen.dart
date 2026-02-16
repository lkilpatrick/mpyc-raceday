import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../incidents/data/models/race_incident.dart';
import '../../../incidents/presentation/incidents_providers.dart';
import '../../../skipper/presentation/widgets/weather_header.dart';

/// Crew incident / protest form — same as skipper but tagged with
/// crew role and boat position from crew_profiles.
class CrewIncidentScreen extends ConsumerStatefulWidget {
  const CrewIncidentScreen({super.key});

  @override
  ConsumerState<CrewIncidentScreen> createState() =>
      _CrewIncidentScreenState();
}

class _CrewIncidentScreenState extends ConsumerState<CrewIncidentScreen> {
  final _descCtrl = TextEditingController();
  final _otherSailCtrl = TextEditingController();

  String _type = 'incident';
  String _location = 'open_water';
  bool _submitting = false;
  bool _submitted = false;
  String? _refId;

  // Auto-captured
  Position? _gpsPosition;
  WeatherSnapshot? _weatherSnap;
  String _eventId = '';
  String _eventName = '';

  // Crew profile
  String _crewName = '';
  String _crewPosition = '';
  String _crewBoatLabel = '';

  @override
  void initState() {
    super.initState();
    _captureContext();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _otherSailCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureContext() async {
    // Load crew profile
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final profileSnap = await FirebaseFirestore.instance
            .collection('crew_profiles')
            .doc(uid)
            .get();
        if (profileSnap.exists) {
          final d = profileSnap.data()!;
          _crewName = d['displayName'] as String? ?? '';
          _crewPosition = d['boatPosition'] as String? ?? '';
          _crewBoatLabel = d['boatLabel'] as String? ?? '';
        }
      } catch (_) {}
    }

    // GPS
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        _gpsPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      }
    } catch (_) {}

    // Weather
    try {
      final weatherDoc = await FirebaseFirestore.instance
          .collection('weather')
          .doc('mpyc_station')
          .get();
      if (weatherDoc.exists) {
        final d = weatherDoc.data()!;
        _weatherSnap = WeatherSnapshot(
          windSpeedKts: (d['speedKts'] as num?)?.toDouble(),
          windSpeedMph: (d['speedMph'] as num?)?.toDouble(),
          windDirDeg: (d['dirDeg'] as num?)?.toInt(),
          windDirLabel: d['windDirLabel'] as String?,
          gustKts: (d['gustKts'] as num?)?.toDouble(),
          tempF: (d['tempF'] as num?)?.toDouble(),
          humidity: (d['humidity'] as num?)?.toDouble(),
          pressureInHg: (d['pressureInHg'] as num?)?.toDouble(),
          source: d['source'] as String?,
          stationName: d['station']?['name'] as String?,
        );
      }
    } catch (_) {}

    // Today's event
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
      if (snap.docs.isNotEmpty) {
        _eventId = snap.docs.first.id;
        _eventName =
            (snap.docs.first.data())['name'] as String? ?? '';
      }
    } catch (_) {}

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Incident')),
      body: Column(
        children: [
          const WeatherHeader(),
          Expanded(
            child: _submitted ? _successView() : _formView(),
          ),
        ],
      ),
    );
  }

  Widget _successView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            const Text('Report Submitted',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Reference: ${_refId ?? '—'}',
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontFamily: 'monospace')),
            const SizedBox(height: 4),
            const Text(
              'RC has been notified and will review your report.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Crew identity badge
        if (_crewName.isNotEmpty)
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(_crewName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  if (_crewPosition.isNotEmpty) ...[
                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                    Text(_crewPosition,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                  if (_crewBoatLabel.isNotEmpty) ...[
                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                    Expanded(
                      child: Text(_crewBoatLabel,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Type selector
        const Text('Report Type',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
                value: 'protest',
                label: Text('Protest'),
                icon: Icon(Icons.gavel)),
            ButtonSegment(
                value: 'incident',
                label: Text('Incident'),
                icon: Icon(Icons.warning)),
            ButtonSegment(
                value: 'note',
                label: Text('Note'),
                icon: Icon(Icons.note)),
          ],
          selected: {_type},
          onSelectionChanged: (v) => setState(() => _type = v.first),
        ),
        const SizedBox(height: 16),

        // Auto-captured context
        Card(
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Auto-Captured',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 4),
                if (_eventName.isNotEmpty)
                  _contextRow(Icons.sailing, 'Race: $_eventName'),
                if (_gpsPosition != null)
                  _contextRow(Icons.gps_fixed,
                      'GPS: ${_gpsPosition!.latitude.toStringAsFixed(5)}, ${_gpsPosition!.longitude.toStringAsFixed(5)}'),
                if (_weatherSnap != null)
                  _contextRow(Icons.air,
                      'Wind: ${_weatherSnap!.windSpeedKts?.toStringAsFixed(0) ?? "?"} kts ${_weatherSnap!.windDirLabel ?? "${_weatherSnap!.windDirDeg ?? "?"}°"}'),
                _contextRow(Icons.access_time,
                    'Time: ${TimeOfDay.now().format(context)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Location on course
        const Text('Location on Course',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _locationChip('start_line', 'Start Line'),
            _locationChip('windward_mark', 'Windward Mark'),
            _locationChip('leeward_mark', 'Leeward Mark'),
            _locationChip('gate', 'Gate'),
            _locationChip('open_water', 'Open Water'),
            _locationChip('reaching_mark', 'Reaching Mark'),
          ],
        ),
        const SizedBox(height: 16),

        // Other boat
        TextField(
          controller: _otherSailCtrl,
          decoration: const InputDecoration(
            labelText: 'Other boat sail number(s)',
            hintText: 'e.g. 1234, 5678',
            prefixIcon: Icon(Icons.directions_boat),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // Description
        TextField(
          controller: _descCtrl,
          decoration: const InputDecoration(
            labelText: 'Describe what happened',
            hintText: 'Brief description of the incident...',
            prefixIcon: Icon(Icons.edit),
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 20),

        // Submit
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            label: Text(_submitting ? 'Sending...' : 'Send to RC',
                style: const TextStyle(fontSize: 16)),
            style: FilledButton.styleFrom(
              backgroundColor: _type == 'protest' ? Colors.red : Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _contextRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _locationChip(String value, String label) {
    final selected = _location == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _location = value),
      visualDensity: VisualDensity.compact,
    );
  }

  CourseLocationOnIncident _mapLocation(String loc) => switch (loc) {
        'start_line' => CourseLocationOnIncident.startLine,
        'windward_mark' => CourseLocationOnIncident.windwardMark,
        'leeward_mark' => CourseLocationOnIncident.leewardMark,
        'gate' => CourseLocationOnIncident.gate,
        'reaching_mark' => CourseLocationOnIncident.reachingMark,
        _ => CourseLocationOnIncident.openWater,
      };

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what happened')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final gpsNote = _gpsPosition != null
          ? 'GPS: ${_gpsPosition!.latitude.toStringAsFixed(5)}, ${_gpsPosition!.longitude.toStringAsFixed(5)}'
          : '';

      // Build description with crew metadata
      final crewTag = [
        'Reporter: $_crewName (crew)',
        if (_crewPosition.isNotEmpty) 'Position: $_crewPosition',
        if (_crewBoatLabel.isNotEmpty) 'Boat: $_crewBoatLabel',
      ].join(' | ');

      final fullDesc = '$crewTag\n\n${_descCtrl.text.trim()}';

      final status = _type == 'protest'
          ? RaceIncidentStatus.protestFiled
          : RaceIncidentStatus.reported;

      final incident = RaceIncident(
        id: '',
        eventId: _eventId,
        eventName: _eventName,
        raceNumber: 0,
        reportedAt: DateTime.now(),
        reportedBy: uid,
        incidentTime: DateTime.now(),
        description: fullDesc,
        locationOnCourse: _mapLocation(_location),
        locationDetail: gpsNote,
        courseName: '',
        involvedBoats: _otherSailCtrl.text
            .trim()
            .split(RegExp(r'[,\s]+'))
            .where((s) => s.isNotEmpty)
            .map((sail) => BoatInvolved(
                  boatId: '',
                  sailNumber: sail.trim(),
                  boatName: '',
                  skipperName: '',
                  role: BoatInvolvedRole.protested,
                ))
            .toList(),
        rulesAlleged: const [],
        status: status,
        weatherSnapshot: _weatherSnap,
      );

      final repo = ref.read(incidentsRepositoryProvider);
      final createdId = await repo.createIncident(incident);

      if (mounted) {
        setState(() {
          _submitting = false;
          _submitted = true;
          _refId = createdId.isNotEmpty
              ? createdId.substring(0, 8).toUpperCase()
              : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }
}
