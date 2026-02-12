import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpyc_raceday/core/theme.dart';

import '../../data/models/course_config.dart';
import '../../data/models/mark.dart';
import '../../domain/courses_repository.dart';
import '../courses_providers.dart';
import '../widgets/course_map_diagram.dart';
import '../widgets/course_map_widget.dart';
import 'course_form_dialog.dart';
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


  Future<void> _addCourse() async {
    final result = await showDialog<CourseConfig>(
      context: context,
      builder: (_) => const CourseFormDialog(),
    );
    if (result == null) return;
    await ref.read(coursesRepositoryProvider).saveCourse(result);
  }

  Future<void> _editCourse(CourseConfig course) async {
    final result = await showDialog<CourseConfig>(
      context: context,
      builder: (_) => CourseFormDialog(course: course),
    );
    if (result == null) return;
    await ref.read(coursesRepositoryProvider).saveCourse(result);
    setState(() => _selectedCourse = result);
  }

  Future<void> _deleteCourse(CourseConfig course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Course'),
        content:
            Text('Delete "${course.courseName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
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
        backgroundColor: _parseHex(course.windGroup?.color),
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
        '${course.distanceNm > 0 ? "${course.distanceNm.toStringAsFixed(1)} nm" : "Variable"} · ${course.markSequenceDisplay}',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
                _infoChip(Icons.explore, 'Wind: ${course.windGroup?.label ?? course.windDirectionBand}'),
                _infoChip(Icons.straighten,
                    '${course.distanceNm.toStringAsFixed(1)} nm'),
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
                      if (m.isStart || m.isFinish)
                        Icon(
                          m.isStart ? Icons.flag : Icons.sports_score,
                          size: 12,
                          color: m.isStart ? Colors.blue : Colors.green,
                        )
                      else
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: m.rounding == MarkRounding.port
                              ? Colors.red
                              : Colors.green,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        m.isStart
                            ? 'START (at Mark 1)'
                            : m.isFinish
                                ? 'FINISH (at ${m.markName})'
                                : '${m.markName} (${m.rounding.name})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: (m.isStart || m.isFinish)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (m.isStart)
                        _badge('START', Colors.blue),
                      if (m.isFinish)
                        _badge('FINISH', Colors.green),
                    ],
                  ),
                )),
            const SizedBox(height: 20),

            // Interactive map with marks
            Text('Race Area Map',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CourseMapWidget(
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

  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

Color _parseHex(String? hex) {
  if (hex != null && hex.startsWith('#') && hex.length == 7) {
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }
  return AppColors.primary;
}
