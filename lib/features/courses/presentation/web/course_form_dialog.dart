import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/course_config.dart';
import '../../data/models/mark.dart';
import '../courses_providers.dart';

/// Reusable course create/edit form dialog with Course Sequence Builder.
/// Returns a [CourseConfig] on submit, or null on cancel.
class CourseFormDialog extends ConsumerStatefulWidget {
  const CourseFormDialog({super.key, this.course});

  final CourseConfig? course;

  @override
  ConsumerState<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends ConsumerState<CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  late String _band;
  late int _windMin;
  late int _windMax;
  late String _finish;
  late String _finishType;
  late String? _finishMarkId;
  late bool _canMultiply;
  late bool _requiresInflatable;
  late String? _inflatableType;

  /// The ordered sequence of course legs (no START/FINISH pseudo-marks).
  final List<_LegEntry> _legs = [];

  /// Currently selected mark to add.
  String? _selectedMarkToAdd;

  /// Validation error for sequence.
  String? _sequenceError;

  bool get _isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _numberCtrl = TextEditingController(text: c?.courseNumber ?? '');
    _nameCtrl = TextEditingController(text: c?.courseName ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _band = c?.windDirectionBand ?? 'S_SW';
    _windMin = c?.windDirMin ?? 0;
    _windMax = c?.windDirMax ?? 360;
    _finish = c?.finishLocation ?? 'committee_boat';
    _finishType = c?.finishType ?? 'committee_boat';
    _finishMarkId = c?.finishMarkId;
    _canMultiply = c?.canMultiply ?? false;
    _requiresInflatable = c?.requiresInflatable ?? false;
    _inflatableType = c?.inflatableType;

    // Load existing sequence marks
    if (c != null) {
      for (final m in c.sequenceMarks) {
        _legs.add(_LegEntry(
          markId: m.markId,
          markName: m.markName,
          rounding: m.rounding,
        ));
      }
    }
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marksAsync = ref.watch(watchMarksProvider);
    final marks = marksAsync.value ?? [];

    // Compute auto distance
    final autoDistance = _computeDistance(marks);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 900),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  _isEditing ? 'Edit Course' : 'New Course',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                // Main content: two columns
                Flexible(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column: form fields + sequence builder
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBasicFields(),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildSequenceBuilder(marks),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildFinishSelector(marks),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildOptionsRow(),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _notesCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Notes',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right column: live preview
                      Expanded(
                        flex: 2,
                        child: _buildPreviewPanel(marks, autoDistance),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bottom actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_sequenceError != null) ...[
                      Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(_sequenceError!,
                            style: TextStyle(
                                color: Colors.orange.shade800, fontSize: 12)),
                      ),
                    ] else
                      const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(_isEditing ? 'Save' : 'Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Basic Fields ──

  Widget _buildBasicFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _numberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Number',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _band,
                decoration: const InputDecoration(
                  labelText: 'Wind Band',
                  border: OutlineInputBorder(),
                ),
                items: ['S_SW', 'W', 'NW', 'N', 'N_EXT', 'INFLATABLE', 'LONG']
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => _band = v ?? _band),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _finish,
                decoration: const InputDecoration(
                  labelText: 'Finish Location',
                  border: OutlineInputBorder(),
                ),
                items: ['committee_boat', 'mark', 'shore']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _finish = v ?? _finish),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Course Sequence Builder ──

  Widget _buildSequenceBuilder(List<Mark> marks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.route, size: 18),
            const SizedBox(width: 6),
            Text('Course Sequence',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${_legs.length} legs',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 8),

        // Add mark row
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedMarkToAdd,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select mark to add',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: marks
                    .map((m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(
                            '${m.name}${m.code != null && m.code != m.name ? " (${m.code})" : ""}'
                            '${m.latitude != null ? " \u2713" : " \u2717"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: m.latitude != null
                                  ? null
                                  : Colors.red.shade400,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMarkToAdd = v),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _selectedMarkToAdd != null ? _addLeg : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Sequence list
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(7)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(child: Text('Mark', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    SizedBox(width: 80, child: Text('Rounding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    SizedBox(width: 96, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
              ),
              // Locked START row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Icon(Icons.flag, size: 14, color: Colors.green.shade700),
                    ),
                    Expanded(
                      child: Text('START (Mark 1)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.green.shade700)),
                    ),
                    const SizedBox(width: 80),
                    SizedBox(
                      width: 96,
                      child: Icon(Icons.lock_outline,
                          size: 14, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
              // User-added rows
              if (_legs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: const Text('Add marks to define the course.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              else
                for (var i = 0; i < _legs.length; i++)
                  _buildLegRow(i, marks),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegRow(int index, List<Mark> marks) {
    final leg = _legs[index];
    final isFirst = index == 0;
    final isLast = index == _legs.length - 1;
    final mark = marks.where((m) => m.name == leg.markName).firstOrNull;
    final hasCoords = mark?.latitude != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        color: !hasCoords ? Colors.red.shade50 : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('${index + 1}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Row(
              children: [
                Text(leg.markName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (!hasCoords)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Tooltip(
                      message: 'No coordinates — distance will be incomplete',
                      child: Icon(Icons.warning_amber,
                          size: 14, color: Colors.red.shade400),
                    ),
                  ),
              ],
            ),
          ),
          // Rounding toggle — red P / green S
          SizedBox(
            width: 80,
            child: Row(
              children: [
                _RoundingButton(
                  label: 'P',
                  color: Colors.red,
                  selected: leg.rounding == MarkRounding.port,
                  onTap: () => setState(() =>
                      _legs[index] = leg.copyWith(rounding: MarkRounding.port)),
                ),
                const SizedBox(width: 4),
                _RoundingButton(
                  label: 'S',
                  color: Colors.green,
                  selected: leg.rounding == MarkRounding.starboard,
                  onTap: () => setState(() =>
                      _legs[index] = leg.copyWith(rounding: MarkRounding.starboard)),
                ),
              ],
            ),
          ),
          // Actions
          SizedBox(
            width: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  onPressed: isFirst ? null : () => _moveUp(index),
                  tooltip: 'Move up',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  iconSize: 16,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  onPressed: isLast ? null : () => _moveDown(index),
                  tooltip: 'Move down',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  iconSize: 16,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 16, color: Colors.red.shade400),
                  onPressed: () => _removeLeg(index),
                  tooltip: 'Remove',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  iconSize: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Finish Selector ──

  Widget _buildFinishSelector(List<Mark> marks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sports_score, size: 18),
            const SizedBox(width: 6),
            Text('Finish Type',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        RadioListTile<String>(
          value: 'committee_boat',
          // ignore: deprecated_member_use
          groupValue: _finishType,
          // ignore: deprecated_member_use
          onChanged: (v) {
            setState(() {
              _finishType = v!;
              _finishMarkId = null;
            });
          },
          title: const Text('Committee Boat',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          subtitle: const Text('Finish between Committee Boat and Mark 1',
              style: TextStyle(fontSize: 11)),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          value: 'club_mark',
          // ignore: deprecated_member_use
          groupValue: _finishType,
          // ignore: deprecated_member_use
          onChanged: (v) {
            setState(() {
              _finishType = v!;
              _finishMarkId = null;
            });
          },
          title: const Text('Club Mark',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          subtitle: const Text(
              'Finish between Club House and a specified mark',
              style: TextStyle(fontSize: 11)),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        if (_finishType == 'club_mark')
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _finishMarkId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Finish Mark',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: marks
                  .map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _finishMarkId = v),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Select a finish mark' : null,
            ),
          ),
      ],
    );
  }

  // ── Options Row ──

  Widget _buildOptionsRow() {
    return Row(
      children: [
        Checkbox(
          value: _canMultiply,
          onChanged: (v) => setState(() => _canMultiply = v ?? false),
        ),
        const Text('Can multiply (x2)', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 24),
        Checkbox(
          value: _requiresInflatable,
          onChanged: (v) =>
              setState(() => _requiresInflatable = v ?? false),
        ),
        const Text('Requires inflatable', style: TextStyle(fontSize: 13)),
      ],
    );
  }

  // ── Preview Panel ──

  Widget _buildPreviewPanel(List<Mark> marks, double autoDistance) {
    // Build the sequence display
    final seqParts = <String>['START'];
    for (final leg in _legs) {
      final r = leg.rounding == MarkRounding.port ? 'p' : 's';
      seqParts.add('${leg.markName}$r');
    }
    if (_finishType == 'club_mark' && _finishMarkId != null) {
      final finishName = marks.where((m) => m.id == _finishMarkId).firstOrNull?.name ?? _finishMarkId;
      seqParts.add('FINISH($finishName)');
    } else {
      seqParts.add('FINISH');
    }

    // Build map points for polyline (start at Mark 1, end at finish)
    final points = <_LatLng>[];
    final markNames = <String>[];
    final mark1 = marks.where((m) => m.name == '1').firstOrNull;
    if (mark1?.latitude != null && mark1?.longitude != null) {
      points.add(_LatLng(mark1!.latitude!, mark1.longitude!));
      markNames.add('1');
    }
    for (final leg in _legs) {
      final mark = marks.where((m) => m.name == leg.markName).firstOrNull;
      if (mark?.latitude != null && mark?.longitude != null) {
        points.add(_LatLng(mark!.latitude!, mark.longitude!));
        markNames.add(leg.markName);
      }
    }
    // Add finish point
    if (_legs.isNotEmpty) {
      if (_finishType == 'club_mark' && _finishMarkId != null) {
        final fm = marks.where((m) => m.id == _finishMarkId).firstOrNull;
        if (fm?.latitude != null && fm?.longitude != null) {
          points.add(_LatLng(fm!.latitude!, fm.longitude!));
          markNames.add(fm.name);
        }
      } else if (mark1?.latitude != null && mark1?.longitude != null) {
        // Committee boat finish = back to Mark 1
        points.add(_LatLng(mark1!.latitude!, mark1.longitude!));
        markNames.add('1');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.preview, size: 18),
            const SizedBox(width: 6),
            Text('Preview',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),

        // Course sequence display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            seqParts.join(' \u2192 '),
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),

        // Auto distance
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.straighten, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                autoDistance > 0
                    ? '${autoDistance.toStringAsFixed(1)} nm'
                    : 'N/A',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Auto',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Map preview
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: points.length >= 2
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: _CourseMapPreview(
                      points: points,
                      markNames: markNames,
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Add 2+ marks with coordinates\nto see map preview',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Sequence Actions ──

  void _addLeg() {
    if (_selectedMarkToAdd == null) return;
    final marks = ref.read(watchMarksProvider).value ?? [];
    final mark = marks.where((m) => m.id == _selectedMarkToAdd).firstOrNull;
    if (mark == null) return;
    setState(() {
      _legs.add(_LegEntry(
        markId: mark.name,
        markName: mark.name,
        rounding: MarkRounding.port,
      ));
    });
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() {
      final item = _legs.removeAt(index);
      _legs.insert(index - 1, item);
    });
  }

  void _moveDown(int index) {
    if (index >= _legs.length - 1) return;
    setState(() {
      final item = _legs.removeAt(index);
      _legs.insert(index + 1, item);
    });
  }

  void _removeLeg(int index) {
    setState(() => _legs.removeAt(index));
  }

  // ── Distance Calculation ──

  double _computeDistance(List<Mark> marks) {
    if (_legs.isEmpty) return 0;

    final points = <_LatLng>[];
    // Start at Mark 1
    final mark1 = marks.where((m) => m.name == '1').firstOrNull;
    if (mark1?.latitude != null && mark1?.longitude != null) {
      points.add(_LatLng(mark1!.latitude!, mark1.longitude!));
    }
    for (final leg in _legs) {
      final mark = marks.where((m) => m.name == leg.markName).firstOrNull;
      if (mark?.latitude != null && mark?.longitude != null) {
        points.add(_LatLng(mark!.latitude!, mark.longitude!));
      }
    }
    // Add finish point
    if (_finishType == 'club_mark' && _finishMarkId != null) {
      final fm = marks.where((m) => m.id == _finishMarkId).firstOrNull;
      if (fm?.latitude != null && fm?.longitude != null) {
        points.add(_LatLng(fm!.latitude!, fm.longitude!));
      }
    } else if (mark1?.latitude != null && mark1?.longitude != null) {
      points.add(_LatLng(mark1!.latitude!, mark1.longitude!));
    }
    if (points.length < 2) return 0;

    double total = 0;
    for (var i = 0; i < points.length - 1; i++) {
      total += _haversineNm(points[i], points[i + 1]);
    }
    return total;
  }

  static double _haversineNm(_LatLng a, _LatLng b) {
    const earthRadiusNm = 3440.065; // nautical miles
    final dLat = _toRad(b.lat - a.lat);
    final dLon = _toRad(b.lon - a.lon);
    final aLat = _toRad(a.lat);
    final bLat = _toRad(b.lat);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(aLat) * math.cos(bLat) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * earthRadiusNm * math.asin(math.sqrt(h));
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  // ── Submit ──

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Validate finish
    if (_finishType == 'club_mark' &&
        (_finishMarkId == null || _finishMarkId!.isEmpty)) {
      setState(() => _sequenceError = 'Select a finish mark for Club Mark finish type');
      return;
    }

    // Build marks list with proper order
    final courseMarks = <CourseMark>[];
    for (var i = 0; i < _legs.length; i++) {
      final leg = _legs[i];
      courseMarks.add(CourseMark(
        markId: leg.markId,
        markName: leg.markName,
        order: i + 1,
        rounding: leg.rounding,
      ));
    }

    // Compute auto distance
    final marks = ref.read(watchMarksProvider).value ?? [];
    final autoDistance = _computeDistance(marks);

    final existing = widget.course;
    final course = CourseConfig(
      id: existing?.id ?? '',
      courseNumber: _numberCtrl.text.trim(),
      courseName: _nameCtrl.text.trim(),
      marks: courseMarks,
      distanceNm: autoDistance > 0 ? autoDistance : 0,
      windDirectionBand: _band,
      windDirMin: _windMin,
      windDirMax: _windMax,
      finishLocation: _finish,
      finishType: _finishType,
      finishMarkId: _finishType == 'club_mark'
          ? marks.where((m) => m.id == _finishMarkId).firstOrNull?.name ?? _finishMarkId
          : null,
      canMultiply: _canMultiply,
      requiresInflatable: _requiresInflatable,
      inflatableType: _requiresInflatable ? _inflatableType : null,
      notes: _notesCtrl.text.trim(),
    );
    Navigator.pop(context, course);
  }
}

// ── Rounding Button ──

class _RoundingButton extends StatelessWidget {
  const _RoundingButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 28,
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? color.withAlpha(200) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

// ── Helper types ──

class _LegEntry {
  _LegEntry({
    required this.markId,
    required this.markName,
    required this.rounding,
  });

  final String markId;
  final String markName;
  final MarkRounding rounding;

  _LegEntry copyWith({MarkRounding? rounding}) => _LegEntry(
        markId: markId,
        markName: markName,
        rounding: rounding ?? this.rounding,
      );
}

class _LatLng {
  const _LatLng(this.lat, this.lon);
  final double lat;
  final double lon;
}

// ── Map Preview (read-only) ──

class _CourseMapPreview extends StatelessWidget {
  const _CourseMapPreview({required this.points, required this.markNames});

  final List<_LatLng> points;
  final List<String> markNames;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (points.isEmpty) return const SizedBox.shrink();

        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final padding = 32.0;

        // Compute bounds
        double minLat = points.first.lat, maxLat = points.first.lat;
        double minLon = points.first.lon, maxLon = points.first.lon;
        for (final p in points) {
          if (p.lat < minLat) minLat = p.lat;
          if (p.lat > maxLat) maxLat = p.lat;
          if (p.lon < minLon) minLon = p.lon;
          if (p.lon > maxLon) maxLon = p.lon;
        }

        // Add small padding to bounds
        final latRange = (maxLat - minLat).clamp(0.001, double.infinity);
        final lonRange = (maxLon - minLon).clamp(0.001, double.infinity);

        Offset toScreen(_LatLng p) {
          final x = padding +
              ((p.lon - minLon) / lonRange) * (w - 2 * padding);
          final y = padding +
              ((maxLat - p.lat) / latRange) * (h - 2 * padding);
          return Offset(x, y);
        }

        return CustomPaint(
          size: Size(w, h),
          painter: _CourseLinePainter(
            points: points.map(toScreen).toList(),
            markNames: markNames,
          ),
        );
      },
    );
  }
}

class _CourseLinePainter extends CustomPainter {
  _CourseLinePainter({required this.points, required this.markNames});

  final List<Offset> points;
  final List<String> markNames;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Draw polyline
    final linePaint = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Draw mark dots and labels
    final dotPaint = Paint()
      ..color = Colors.red.shade700
      ..style = PaintingStyle.fill;
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 6, bgPaint);
      canvas.drawCircle(p, 4, dotPaint);

      // Label
      if (i < markNames.length) {
        final tp = TextPainter(
          text: TextSpan(
            text: markNames[i],
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(p.dx + 8, p.dy - tp.height / 2));
      }
    }

    // Start label
    if (points.isNotEmpty) {
      final startTp = TextPainter(
        text: TextSpan(
          text: 'S',
          style: TextStyle(
            color: Colors.green.shade700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final sp = points.first;
      canvas.drawCircle(sp, 8, Paint()..color = Colors.green.shade100);
      startTp.paint(canvas, Offset(sp.dx - startTp.width / 2, sp.dy - startTp.height / 2));
    }

    // Finish label
    if (points.length >= 2) {
      final finTp = TextPainter(
        text: TextSpan(
          text: 'F',
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final fp = points.last;
      canvas.drawCircle(fp, 8, Paint()..color = Colors.red.shade100);
      finTp.paint(canvas, Offset(fp.dx - finTp.width / 2, fp.dy - finTp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _CourseLinePainter oldDelegate) => true;
}
