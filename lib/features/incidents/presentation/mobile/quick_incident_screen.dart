import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../data/models/race_incident.dart';
import '../incidents_providers.dart';
import '../../../boat_checkin/data/models/boat_checkin.dart';
import '../../../boat_checkin/presentation/boat_checkin_providers.dart';

class QuickIncidentScreen extends ConsumerStatefulWidget {
  const QuickIncidentScreen({
    super.key,
    required this.eventId,
    this.raceNumber = 1,
  });

  final String eventId;
  final int raceNumber;

  @override
  ConsumerState<QuickIncidentScreen> createState() =>
      _QuickIncidentScreenState();
}

class _QuickIncidentScreenState extends ConsumerState<QuickIncidentScreen> {
  final _descriptionCtrl = TextEditingController();
  final _rulesSearchCtrl = TextEditingController();
  CourseLocationOnIncident _location = CourseLocationOnIncident.openWater;
  final List<_BoatSelection> _selectedBoats = [];
  final List<String> _selectedRules = [];
  final List<String> _attachmentUrls = [];
  bool _submitting = false;

  static const _commonRules = [
    '10 – On the Same Tack, Overlapped',
    '11 – On the Same Tack, Not Overlapped',
    '12 – On Opposite Tacks',
    '13 – While Tacking',
    '14 – Avoiding Contact',
    '15 – Acquiring Right of Way',
    '16 – Changing Course',
    '17 – On the Same Tack; Proper Course',
    '18 – Mark-Room',
    '19 – Room to Pass an Obstruction',
    '20 – Room to Tack at an Obstruction',
    '31 – Touching a Mark',
    '42 – Propulsion',
    '44 – Penalties at the Time of an Incident',
  ];

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _rulesSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkinsAsync = ref.watch(eventCheckinsProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Auto-filled info
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Text('Race ${widget.raceNumber}'),
                  const SizedBox(width: 16),
                  Text(TimeOfDay.now().format(context)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Location on course
          Text('Location on Course',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: CourseLocationOnIncident.values.map((loc) {
              final label = switch (loc) {
                CourseLocationOnIncident.startLine => 'Start Line',
                CourseLocationOnIncident.windwardMark => 'Windward Mark',
                CourseLocationOnIncident.gate => 'Gate',
                CourseLocationOnIncident.leewardMark => 'Leeward Mark',
                CourseLocationOnIncident.reachingMark => 'Reaching Mark',
                CourseLocationOnIncident.openWater => 'Open Water',
              };
              return ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                selected: _location == loc,
                onSelected: (_) => setState(() => _location = loc),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Boats involved
          Text('Boats Involved',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          checkinsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading boats: $e'),
            data: (checkins) => _buildBoatSelector(checkins),
          ),
          const SizedBox(height: 4),

          // Selected boats with roles
          if (_selectedBoats.isNotEmpty) ...[
            ..._selectedBoats.map((sel) => Card(
                  child: ListTile(
                    dense: true,
                    title: Text('${sel.boatName} (${sel.sailNumber})'),
                    subtitle: Text(sel.skipperName),
                    trailing: SegmentedButton<BoatInvolvedRole>(
                      segments: const [
                        ButtonSegment(
                            value: BoatInvolvedRole.protesting,
                            label: Text('P', style: TextStyle(fontSize: 10))),
                        ButtonSegment(
                            value: BoatInvolvedRole.protested,
                            label: Text('D', style: TextStyle(fontSize: 10))),
                        ButtonSegment(
                            value: BoatInvolvedRole.witness,
                            label: Text('W', style: TextStyle(fontSize: 10))),
                      ],
                      selected: {sel.role},
                      onSelectionChanged: (roles) {
                        setState(() => sel.role = roles.first);
                      },
                    ),
                  ),
                )),
            const SizedBox(height: 4),
            const Text('P = Protesting  D = Protested  W = Witness',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
          const SizedBox(height: 16),

          // Description
          Text('Description',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          TextField(
            controller: _descriptionCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Describe what happened...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Rules involved
          Text('Rules Involved',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _commonRules.map((rule) {
              final isSelected = _selectedRules.contains(rule);
              return FilterChip(
                label: Text(rule, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      _selectedRules.add(rule);
                    } else {
                      _selectedRules.remove(rule);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Photo/video
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _captureMedia(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Photo'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _captureMedia(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Gallery'),
              ),
              if (_attachmentUrls.isNotEmpty) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text('${_attachmentUrls.length} attached'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: const Text('SUBMIT INCIDENT',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBoatSelector(List<BoatCheckin> checkins) {
    final available = checkins
        .where((c) => !_selectedBoats.any((s) => s.boatId == c.boatId))
        .toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: available.map((c) {
        return ActionChip(
          avatar: const Icon(Icons.add, size: 16),
          label: Text('${c.sailNumber} ${c.boatName}',
              style: const TextStyle(fontSize: 12)),
          onPressed: () {
            setState(() {
              _selectedBoats.add(_BoatSelection(
                boatId: c.boatId,
                sailNumber: c.sailNumber,
                boatName: c.boatName,
                skipperName: c.skipperName,
              ));
            });
          },
        );
      }).toList(),
    );
  }

  Future<void> _captureMedia(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 70);
      if (file == null) return;

      final ref = FirebaseStorage.instance
          .ref('incidents/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();
      setState(() => _attachmentUrls.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedBoats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one boat')),
      );
      return;
    }
    if (_descriptionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a description')),
      );
      return;
    }

    setState(() => _submitting = true);

    final incident = RaceIncident(
      id: '',
      eventId: widget.eventId,
      raceNumber: widget.raceNumber,
      reportedAt: DateTime.now(),
      reportedBy: 'PRO',
      incidentTime: DateTime.now(),
      description: _descriptionCtrl.text.trim(),
      locationOnCourse: _location,
      involvedBoats: _selectedBoats
          .map((s) => BoatInvolved(
                boatId: s.boatId,
                sailNumber: s.sailNumber,
                boatName: s.boatName,
                skipperName: s.skipperName,
                role: s.role,
              ))
          .toList(),
      rulesAlleged: _selectedRules,
      status: RaceIncidentStatus.reported,
      attachments: _attachmentUrls,
    );

    await ref.read(incidentsRepositoryProvider).createIncident(incident);

    setState(() => _submitting = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident reported — PRO notified')),
      );
    }
  }
}

class _BoatSelection {
  _BoatSelection({
    required this.boatId,
    required this.sailNumber,
    required this.boatName,
    required this.skipperName,
  });

  final String boatId;
  final String sailNumber;
  final String boatName;
  final String skipperName;
  BoatInvolvedRole role = BoatInvolvedRole.protesting;
}
