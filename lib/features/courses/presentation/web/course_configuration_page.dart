import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpyc_raceday/core/theme.dart';

import '../../data/models/course_config.dart';
import '../../data/models/mark.dart';
import '../../domain/courses_repository.dart';
import '../courses_providers.dart';
import '../widgets/course_map_diagram.dart';
import '../widgets/nautical_chart_widget.dart';
import 'mark_management_panel.dart';

class CourseConfigurationPage extends ConsumerStatefulWidget {
  const CourseConfigurationPage({super.key});

  @override
  ConsumerState<CourseConfigurationPage> createState() =>
      _CourseConfigurationPageState();
}

class _CourseConfigurationPageState
    extends ConsumerState<CourseConfigurationPage>
    with SingleTickerProviderStateMixin {
  String _filterBand = 'All';
  CourseConfig? _selectedCourse;
  late final TabController _tabCtrl;

  static const _bands = [
    'All',
    'S_SW',
    'W',
    'NW',
    'N',
    'N_EXT',
    'INFLATABLE',
    'LONG',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab bar
        TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.route, size: 18), text: 'Courses'),
            Tab(icon: Icon(Icons.pin_drop, size: 18), text: 'Race Marks'),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildCoursesTab(),
              const MarkManagementPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesTab() {
    final coursesAsync = ref.watch(allCoursesProvider);
    final distancesAsync = ref.watch(markDistancesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Toolbar ──
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                'Course Configuration',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _filterBand,
                items: _bands
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _filterBand = v ?? 'All';
                  _selectedCourse = null;
                }),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _seedFromAsset,
                icon: const Icon(Icons.cloud_upload, size: 18),
                label: const Text('Seed Data'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _addCourse,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Course'),
              ),
            ],
          ),
        ),

        // ── Content ──
        Expanded(
          child: coursesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (courses) {
              final filtered = _filterBand == 'All'
                  ? courses
                  : courses
                      .where((c) => c.windDirectionBand == _filterBand)
                      .toList();

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course list
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text('No courses found for this filter.'),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final course = filtered[i];
                                final isSelected =
                                    _selectedCourse?.id == course.id;
                                return _CourseListTile(
                                  course: course,
                                  isSelected: isSelected,
                                  onTap: () => setState(
                                      () => _selectedCourse = course),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Detail panel
                  Expanded(
                    flex: 3,
                    child: _selectedCourse != null
                        ? _CourseDetailPanel(
                            course: _selectedCourse!,
                            distances:
                                distancesAsync.value ?? const [],
                            marks: ref.watch(marksProvider).value ?? const [],
                            onEdit: () => _editCourse(_selectedCourse!),
                            onDelete: () =>
                                _deleteCourse(_selectedCourse!),
                          )
                        : const Card(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.map, size: 48, color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text(
                                      'Select a course to view details',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _seedFromAsset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Seed Course Data'),
        content: const Text(
          'This will load all marks, distances, and courses from the '
          'built-in course sheet into Firestore.\n\n'
          'Existing data with matching IDs will be overwritten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Seed Data'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final jsonString =
          await rootBundle.loadString('assets/courses_seed.json');
      await ref.read(coursesRepositoryProvider).seedFromJson(jsonString);
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course data seeded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seed failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addCourse() async {
    final result = await showDialog<CourseConfig>(
      context: context,
      builder: (_) => const _CourseFormDialog(),
    );
    if (result == null) return;
    await ref.read(coursesRepositoryProvider).saveCourse(result);
  }

  Future<void> _editCourse(CourseConfig course) async {
    final result = await showDialog<CourseConfig>(
      context: context,
      builder: (_) => _CourseFormDialog(course: course),
    );
    if (result == null) return;
    await ref.read(coursesRepositoryProvider).saveCourse(result);
    setState(() => _selectedCourse = result);
  }

  Future<void> _deleteCourse(CourseConfig course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Course'),
        content:
            Text('Delete "${course.courseName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(coursesRepositoryProvider).deleteCourse(course.id);
    setState(() => _selectedCourse = null);
  }
}

// ═══════════════════════════════════════════════════════════════════
// Course List Tile
// ═══════════════════════════════════════════════════════════════════

class _CourseListTile extends StatelessWidget {
  const _CourseListTile({
    required this.course,
    required this.isSelected,
    required this.onTap,
  });

  final CourseConfig course;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppColors.primary.withAlpha(20),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        radius: 18,
        child: Text(
          course.courseNumber,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        course.courseName,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${course.windDirectionBand} · ${course.distanceNm} nm · ${course.marks.length} marks',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (course.requiresInflatable)
            Tooltip(
              message: 'Requires inflatable: ${course.inflatableType ?? ""}',
              child: const Icon(Icons.circle, size: 10, color: Colors.orange),
            ),
          if (course.canMultiply)
            const Tooltip(
              message: 'Can multiply (x2)',
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.repeat, size: 14, color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Course Detail Panel
// ═══════════════════════════════════════════════════════════════════

class _CourseDetailPanel extends StatelessWidget {
  const _CourseDetailPanel({
    required this.course,
    required this.distances,
    required this.marks,
    required this.onEdit,
    required this.onDelete,
  });

  final CourseConfig course;
  final List distances;
  final List marks;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course ${course.courseNumber}',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.courseName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            const Divider(height: 24),

            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(Icons.explore, 'Wind: ${course.windDirectionBand}'),
                _infoChip(Icons.straighten,
                    '${course.distanceNm} nm'),
                _infoChip(Icons.pin_drop,
                    'Wind ${course.windDirMin}°–${course.windDirMax}°'),
                _infoChip(Icons.flag, 'Finish: ${course.finishLocation}'),
                if (course.canMultiply)
                  _infoChip(Icons.repeat, 'Can multiply (x2)'),
                if (course.requiresInflatable)
                  _infoChip(Icons.circle,
                      'Inflatable: ${course.inflatableType ?? "yes"}'),
              ],
            ),
            const SizedBox(height: 20),

            // Mark sequence
            Text('Mark Sequence',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                course.markSequenceDisplay,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Marks table
            ...course.marks.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${m.order}.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: m.rounding == MarkRounding.port
                            ? Colors.red
                            : Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${m.markName} (${m.rounding.name})',
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (m.isFinish)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Chip(
                            label: Text('FINISH',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.green)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),

            // Nautical chart with marks
            Text('Nautical Chart',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            NauticalChartWidget(
              marks: marks.cast(),
              course: course,
              height: 400,
            ),
            const SizedBox(height: 20),

            // Course diagram
            Text('Course Diagram',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CourseMapDiagram(
                  course: course,
                  distances: distances.cast(),
                  size: const Size(400, 400),
                ),
              ),
            ),

            if (course.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Notes',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(course.notes,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade700)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Course Form Dialog
// ═══════════════════════════════════════════════════════════════════

class _CourseFormDialog extends StatefulWidget {
  const _CourseFormDialog({this.course});

  final CourseConfig? course;

  @override
  State<_CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<_CourseFormDialog> {
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
