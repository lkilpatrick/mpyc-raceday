import 'package:flutter/material.dart';

import '../../data/models/course_config.dart';

/// Reusable course create/edit form dialog.
/// Returns a [CourseConfig] on submit, or null on cancel.
class CourseFormDialog extends StatefulWidget {
  const CourseFormDialog({super.key, this.course});

  final CourseConfig? course;

  @override
  State<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _distCtrl;
  late final TextEditingController _notesCtrl;
  late String _band;
  late int _windMin;
  late int _windMax;
  late String _finish;
  late bool _canMultiply;
  late bool _requiresInflatable;
  late String? _inflatableType;

  bool get _isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _numberCtrl = TextEditingController(text: c?.courseNumber ?? '');
    _nameCtrl = TextEditingController(text: c?.courseName ?? '');
    _distCtrl =
        TextEditingController(text: c?.distanceNm.toString() ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _band = c?.windDirectionBand ?? 'S_SW';
    _windMin = c?.windDirMin ?? 0;
    _windMax = c?.windDirMax ?? 360;
    _finish = c?.finishLocation ?? 'committee_boat';
    _canMultiply = c?.canMultiply ?? false;
    _requiresInflatable = c?.requiresInflatable ?? false;
    _inflatableType = c?.inflatableType;
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _distCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing ? 'Edit Course' : 'New Course',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
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
                          value: _band,
                          decoration: const InputDecoration(
                            labelText: 'Wind Band',
                            border: OutlineInputBorder(),
                          ),
                          items: ['S_SW', 'W', 'NW', 'N', 'N_EXT', 'INFLATABLE', 'LONG']
                              .map((b) =>
                                  DropdownMenuItem(value: b, child: Text(b)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _band = v ?? _band),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _distCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Distance (nm)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _finish,
                    decoration: const InputDecoration(
                      labelText: 'Finish Location',
                      border: OutlineInputBorder(),
                    ),
                    items: ['committee_boat', 'mark', 'shore']
                        .map((f) =>
                            DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _finish = v ?? _finish),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _canMultiply,
                        onChanged: (v) =>
                            setState(() => _canMultiply = v ?? false),
                      ),
                      const Text('Can multiply (x2)'),
                      const SizedBox(width: 24),
                      Checkbox(
                        value: _requiresInflatable,
                        onChanged: (v) =>
                            setState(() => _requiresInflatable = v ?? false),
                      ),
                      const Text('Requires inflatable'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.course;
    final course = CourseConfig(
      id: existing?.id ?? '',
      courseNumber: _numberCtrl.text.trim(),
      courseName: _nameCtrl.text.trim(),
      marks: existing?.marks ?? const [],
      distanceNm: double.tryParse(_distCtrl.text.trim()) ?? 0,
      windDirectionBand: _band,
      windDirMin: _windMin,
      windDirMax: _windMax,
      finishLocation: _finish,
      canMultiply: _canMultiply,
      requiresInflatable: _requiresInflatable,
      inflatableType: _requiresInflatable ? _inflatableType : null,
      notes: _notesCtrl.text.trim(),
    );
    Navigator.pop(context, course);
  }
}
