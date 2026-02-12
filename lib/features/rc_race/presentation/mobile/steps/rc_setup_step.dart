import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../courses/data/models/course_config.dart';
import '../../../../courses/data/models/fleet_broadcast.dart';
import '../../../../courses/domain/courses_repository.dart';
import '../../../../courses/presentation/courses_providers.dart';
import '../../../data/models/race_session.dart';
import '../../rc_race_providers.dart';

/// Common VHF channels used for yacht racing.
const _vhfChannels = [
  '09', '16', '68', '69', '71', '72', '73', '74', '77', '78', '80',
];

/// Default fleet names — RC can add/remove up to 4.
const _defaultFleets = ['PHRF A', 'PHRF B', 'One Design', 'Cruiser'];

/// Step 1: Multi-fleet course selection for the race session.
class RcSetupStep extends ConsumerStatefulWidget {
  const RcSetupStep({super.key, required this.session});

  final RaceSession session;

  @override
  ConsumerState<RcSetupStep> createState() => _RcSetupStepState();
}

class _RcSetupStepState extends ConsumerState<RcSetupStep> {
  double _windDir = 0;
  String _vhfChannel = '72';

  /// Active fleets and their assigned course IDs.
  final List<String> _fleets = [];
  final Map<String, String> _fleetCourseIds = {};
  bool _initialized = false;

  void _initFromSession() {
    if (_initialized) return;
    _initialized = true;
    final fc = widget.session.fleetCourses;
    if (fc.isNotEmpty) {
      _fleets.addAll(fc.keys);
      for (final entry in fc.entries) {
        _fleetCourseIds[entry.key] = entry.value['courseId'] ?? '';
      }
    } else if (widget.session.courseId != null &&
        widget.session.courseId!.isNotEmpty) {
      // Migrate legacy single-course to first fleet
      _fleets.add(_defaultFleets.first);
      _fleetCourseIds[_defaultFleets.first] = widget.session.courseId!;
    } else {
      // Start with one fleet
      _fleets.add(_defaultFleets.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromSession();
    final coursesAsync = ref.watch(allCoursesProvider);
    final recommended = ref.watch(recommendedCoursesProvider(_windDir));

    return Column(
      children: [
        // VHF Channel selector
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.shade100),
          ),
          child: Row(
            children: [
              const Icon(Icons.radio, color: Colors.indigo, size: 22),
              const SizedBox(width: 10),
              const Text('VHF Channel',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              DropdownButton<String>(
                value: _vhfChannel,
                underline: const SizedBox.shrink(),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
                items: _vhfChannels
                    .map((ch) => DropdownMenuItem(
                          value: ch,
                          child: Text('Ch $ch'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null && v != _vhfChannel) {
                    setState(() => _vhfChannel = v);
                    _broadcastVhfChange(v);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Wind direction slider
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.explore, size: 20),
              const SizedBox(width: 8),
              Text('Wind: ${_windDir.toInt()}°',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Expanded(
                child: Slider(
                  value: _windDir,
                  min: 0,
                  max: 359,
                  divisions: 359,
                  onChanged: (v) => setState(() => _windDir = v),
                ),
              ),
            ],
          ),
        ),

        // Fleet course assignments
        Expanded(
          child: coursesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (courses) {
              final recommendedIds =
                  recommended.map((c) => c.id).toSet();
              final sorted = [...courses]..sort((a, b) {
                  final aRec = recommendedIds.contains(a.id) ? 0 : 1;
                  final bRec = recommendedIds.contains(b.id) ? 0 : 1;
                  if (aRec != bRec) return aRec.compareTo(bRec);
                  final aNum = int.tryParse(a.courseNumber) ?? 9999;
                  final bNum = int.tryParse(b.courseNumber) ?? 9999;
                  return aNum.compareTo(bNum);
                });

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // Fleet cards
                  for (var fi = 0; fi < _fleets.length; fi++)
                    _FleetCourseCard(
                      fleetName: _fleets[fi],
                      courses: sorted,
                      selectedCourseId: _fleetCourseIds[_fleets[fi]] ?? '',
                      recommendedIds: recommendedIds,
                      onCourseSelected: (courseId) {
                        setState(() {
                          _fleetCourseIds[_fleets[fi]] = courseId;
                        });
                      },
                      onRemove: _fleets.length > 1
                          ? () {
                              setState(() {
                                final name = _fleets.removeAt(fi);
                                _fleetCourseIds.remove(name);
                              });
                            }
                          : null,
                      onRename: (newName) {
                        setState(() {
                          final old = _fleets[fi];
                          final courseId = _fleetCourseIds.remove(old);
                          _fleets[fi] = newName;
                          if (courseId != null) {
                            _fleetCourseIds[newName] = courseId;
                          }
                        });
                      },
                    ),

                  // Add fleet button
                  if (_fleets.length < 4)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: OutlinedButton.icon(
                        onPressed: _addFleet,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Fleet'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          side: const BorderSide(color: Colors.indigo),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        // Bottom actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              // Save & Broadcast
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _hasAnyCourse ? _saveAndBroadcast : null,
                  icon: const Icon(Icons.campaign, size: 20),
                  label: const Text('Save & Broadcast Courses',
                      style: TextStyle(fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(
                        color: _hasAnyCourse
                            ? Colors.red.shade700
                            : Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Proceed
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _hasAnyCourse ? _proceedToCheckin : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Proceed to Check-In',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _hasAnyCourse =>
      _fleetCourseIds.values.any((id) => id.isNotEmpty);

  void _addFleet() {
    final available =
        _defaultFleets.where((f) => !_fleets.contains(f)).toList();
    if (available.isEmpty) return;
    setState(() => _fleets.add(available.first));
  }

  Future<void> _saveAndBroadcast() async {
    await _saveFleetCourses();

    // Build broadcast message
    final coursesAsync = ref.read(allCoursesProvider);
    final courses = coursesAsync.value ?? [];
    final lines = <String>[];
    for (final fleet in _fleets) {
      final cid = _fleetCourseIds[fleet] ?? '';
      if (cid.isEmpty) continue;
      final course = courses.where((c) => c.id == cid).firstOrNull;
      if (course != null) {
        lines.add('$fleet → Course ${course.courseNumber} (${course.courseName})');
      }
    }
    if (lines.isEmpty) return;

    await ref.read(coursesRepositoryProvider).sendBroadcast(
          FleetBroadcast(
            id: '',
            eventId: widget.session.id,
            sentBy: 'RC',
            message: 'COURSE ASSIGNMENTS:\n${lines.join('\n')}',
            type: BroadcastType.courseChange,
            sentAt: DateTime.now(),
            deliveryCount: 0,
            target: BroadcastTarget.everyone,
            requiresAck: true,
          ),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fleet courses saved & broadcast sent'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveFleetCourses() async {
    final coursesAsync = ref.read(allCoursesProvider);
    final courses = coursesAsync.value ?? [];

    // Build fleetCourses map for Firestore
    final fleetCoursesMap = <String, Map<String, String>>{};
    String? firstCourseId;
    String? firstCourseName;
    String? firstCourseNumber;

    for (final fleet in _fleets) {
      final cid = _fleetCourseIds[fleet] ?? '';
      if (cid.isEmpty) continue;
      final course = courses.where((c) => c.id == cid).firstOrNull;
      if (course != null) {
        fleetCoursesMap[fleet] = {
          'courseId': course.id,
          'courseName': course.courseName,
          'courseNumber': course.courseNumber,
        };
        firstCourseId ??= course.id;
        firstCourseName ??= course.courseName;
        firstCourseNumber ??= course.courseNumber;
      }
    }

    // Save to Firestore — keep legacy courseId for backward compat
    await FirebaseFirestore.instance
        .collection('race_events')
        .doc(widget.session.id)
        .update({
      'fleetCourses': fleetCoursesMap,
      if (firstCourseId != null) 'courseId': firstCourseId,
      if (firstCourseName != null) 'courseName': firstCourseName,
      if (firstCourseNumber != null) 'courseNumber': firstCourseNumber,
    });
  }

  Future<void> _broadcastVhfChange(String channel) async {
    await FirebaseFirestore.instance
        .collection('race_events')
        .doc(widget.session.id)
        .update({'vhfChannel': channel});

    await ref.read(coursesRepositoryProvider).sendBroadcast(
          FleetBroadcast(
            id: '',
            eventId: widget.session.id,
            sentBy: 'RC',
            message: 'VHF race channel changed to Ch $channel',
            type: BroadcastType.vhfChannelChange,
            sentAt: DateTime.now(),
            deliveryCount: 0,
            target: BroadcastTarget.everyone,
            requiresAck: true,
          ),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('VHF channel broadcast: Ch $channel')),
      );
    }
  }

  Future<void> _proceedToCheckin() async {
    await _saveFleetCourses();
    await ref
        .read(rcRaceRepositoryProvider)
        .updateStatus(widget.session.id, RaceSessionStatus.checkinOpen);
  }
}

// ─────────────────────────────────────────────────────────────────
// Fleet Course Card — one per fleet, with course dropdown
// ─────────────────────────────────────────────────────────────────

class _FleetCourseCard extends StatelessWidget {
  const _FleetCourseCard({
    required this.fleetName,
    required this.courses,
    required this.selectedCourseId,
    required this.recommendedIds,
    required this.onCourseSelected,
    this.onRemove,
    required this.onRename,
  });

  final String fleetName;
  final List<CourseConfig> courses;
  final String selectedCourseId;
  final Set<String> recommendedIds;
  final ValueChanged<String> onCourseSelected;
  final VoidCallback? onRemove;
  final ValueChanged<String> onRename;

  @override
  Widget build(BuildContext context) {
    final selectedCourse = selectedCourseId.isNotEmpty
        ? courses.where((c) => c.id == selectedCourseId).firstOrNull
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selectedCourse != null ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fleet header
            Row(
              children: [
                const Icon(Icons.sailing, size: 18, color: Colors.indigo),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _editFleetName(context),
                    child: Row(
                      children: [
                        Text(fleetName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 14, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
                if (selectedCourse != null)
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 18),
                if (onRemove != null)
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: Colors.red.shade300),
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Remove fleet',
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Course dropdown
            DropdownButtonFormField<String>(
              value: selectedCourseId.isNotEmpty &&
                      courses.any((c) => c.id == selectedCourseId)
                  ? selectedCourseId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Select course for $fleetName',
                prefixIcon: const Icon(Icons.map, size: 20),
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: courses.map((c) {
                final isRec = recommendedIds.contains(c.id);
                return DropdownMenuItem(
                  value: c.id,
                  child: Text(
                    '${c.courseNumber} — ${c.courseName} (${c.distanceNm} nm)${isRec ? ' ★' : ''}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRec ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (id) {
                if (id != null) onCourseSelected(id);
              },
            ),

            // Show selected course details
            if (selectedCourse != null) ...[
              const SizedBox(height: 6),
              Text(
                '${selectedCourse.windDirectionBand} · ${selectedCourse.distanceNm} nm · ${selectedCourse.marks.length} marks',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _editFleetName(BuildContext context) {
    final ctrl = TextEditingController(text: fleetName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Fleet'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Fleet Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty && name != fleetName) {
                onRename(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
