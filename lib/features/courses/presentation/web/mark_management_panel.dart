import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpyc_raceday/core/theme.dart';

import '../../data/models/mark.dart';
import '../../domain/courses_repository.dart';
import '../courses_providers.dart';
import '../widgets/course_map_widget.dart';

class MarkManagementPanel extends ConsumerStatefulWidget {
  const MarkManagementPanel({super.key});

  @override
  ConsumerState<MarkManagementPanel> createState() =>
      _MarkManagementPanelState();
}

class _MarkManagementPanelState extends ConsumerState<MarkManagementPanel> {
  Mark? _selectedMark;

  @override
  Widget build(BuildContext context) {
    final marksAsync = ref.watch(watchMarksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                'Race Marks',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _addMark,
                icon: const Icon(Icons.add_location_alt, size: 18),
                label: const Text('Add Mark'),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: marksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (marks) {
              final permanent =
                  marks.where((m) => m.type == 'permanent').toList();
              final government =
                  marks.where((m) => m.type == 'government').toList();
              final harbor =
                  marks.where((m) => m.type == 'harbor').toList();
              final temporary =
                  marks.where((m) => m.type == 'temporary').toList();

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mark list
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: marks.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text('No marks found.'),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.all(8),
                              children: [
                                if (permanent.isNotEmpty) ...[                                  _sectionHeader('Permanent Marks (Yellow Buoys)'),
                                  ...permanent.map((m) => _MarkListTile(
                                        mark: m,
                                        isSelected:
                                            _selectedMark?.id == m.id,
                                        onTap: () => setState(
                                            () => _selectedMark = m),
                                      )),
                                ],
                                if (government.isNotEmpty) ...[                                  const SizedBox(height: 8),
                                  _sectionHeader('Government Marks (Red Buoys)'),
                                  ...government.map((m) => _MarkListTile(
                                        mark: m,
                                        isSelected:
                                            _selectedMark?.id == m.id,
                                        onTap: () => setState(
                                            () => _selectedMark = m),
                                      )),
                                ],
                                if (harbor.isNotEmpty) ...[                                  const SizedBox(height: 8),
                                  _sectionHeader('Harbor Marks'),
                                  ...harbor.map((m) => _MarkListTile(
                                        mark: m,
                                        isSelected:
                                            _selectedMark?.id == m.id,
                                        onTap: () => setState(
                                            () => _selectedMark = m),
                                      )),
                                ],
                                if (temporary.isNotEmpty) ...[                                  const SizedBox(height: 8),
                                  _sectionHeader('Temporary / Inflatable Marks'),
                                  ...temporary.map((m) => _MarkListTile(
                                        mark: m,
                                        isSelected:
                                            _selectedMark?.id == m.id,
                                        onTap: () => setState(
                                            () => _selectedMark = m),
                                      )),
                                ],
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Detail / chart panel
                  Expanded(
                    flex: 3,
                    child: _selectedMark != null
                        ? _MarkDetailPanel(
                            mark: _selectedMark!,
                            allMarks: marks,
                            onEdit: () => _editMark(_selectedMark!),
                            onDelete: () => _deleteMark(_selectedMark!),
                          )
                        : Card(
                            child: Column(
                              children: [
                                // Show chart with all marks
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'All Race Marks',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: CourseMapWidget(
                                            marks: marks,
                                            height: double.infinity,
                                            onMarkTap: (m) => setState(
                                                () => _selectedMark = m),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _addMark() async {
    final result = await showDialog<Mark>(
      context: context,
      builder: (_) => const _MarkFormDialog(),
    );
    if (result == null) return;
    await ref.read(coursesRepositoryProvider).saveMark(result);
  }

  Future<void> _editMark(Mark mark) async {
    final result = await showDialog<Mark>(
      context: context,
      builder: (_) => _MarkFormDialog(mark: mark),
    );
    if (result == null) return;
    await ref.read(coursesRepositoryProvider).saveMark(result);
    setState(() => _selectedMark = result);
  }

  Future<void> _deleteMark(Mark mark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Mark'),
        content: Text(
            'Delete "${mark.name}"? This may affect courses using this mark.'),
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
    await ref.read(coursesRepositoryProvider).deleteMark(mark.id);
    setState(() => _selectedMark = null);
  }
}

// ═══════════════════════════════════════════════════════════════════
// Mark List Tile
// ═══════════════════════════════════════════════════════════════════

class _MarkListTile extends StatelessWidget {
  const _MarkListTile({
    required this.mark,
    required this.isSelected,
    required this.onTap,
  });

  final Mark mark;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasGps = mark.latitude != null && mark.longitude != null;

    Color avatarColor;
    switch (mark.type) {
      case 'government':
        avatarColor = Colors.red.shade700;
        break;
      case 'harbor':
        avatarColor = Colors.grey.shade600;
        break;
      case 'temporary':
        avatarColor = Colors.orange;
        break;
      default:
        avatarColor = Colors.amber.shade700;
    }

    return ListTile(
      selected: isSelected,
      selectedTileColor: AppColors.primary.withAlpha(20),
      onTap: onTap,
      dense: true,
      leading: CircleAvatar(
        backgroundColor: avatarColor,
        radius: 16,
        child: Text(
          mark.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        mark.name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        hasGps
            ? '${mark.latitude!.toStringAsFixed(6)}, ${mark.longitude!.toStringAsFixed(6)}'
            : 'No GPS position',
        style: TextStyle(
          fontSize: 11,
          color: hasGps ? Colors.grey.shade600 : Colors.orange.shade700,
        ),
      ),
      trailing: Icon(
        hasGps ? Icons.gps_fixed : Icons.gps_off,
        size: 16,
        color: hasGps ? Colors.green : Colors.orange,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Mark Detail Panel
// ═══════════════════════════════════════════════════════════════════

class _MarkDetailPanel extends StatelessWidget {
  const _MarkDetailPanel({
    required this.mark,
    required this.allMarks,
    required this.onEdit,
    required this.onDelete,
  });

  final Mark mark;
  final List<Mark> allMarks;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGps = mark.latitude != null && mark.longitude != null;

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
                        mark.name,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${mark.id} · Type: ${mark.type}',
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
                  icon:
                      const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Delete',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            const Divider(height: 24),

            // GPS info
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(
                  hasGps ? Icons.gps_fixed : Icons.gps_off,
                  hasGps
                      ? 'Lat: ${mark.latitude!.toStringAsFixed(6)}'
                      : 'No latitude',
                ),
                if (hasGps)
                  _infoChip(Icons.gps_fixed,
                      'Lon: ${mark.longitude!.toStringAsFixed(6)}'),
                _infoChip(
                  _typeIcon(mark.type),
                  _typeLabel(mark.type),
                ),
              ],
            ),

            if (mark.description != null &&
                mark.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Description',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  mark.description!,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Chart showing this mark highlighted
            Text('Location on Chart',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CourseMapWidget(
              marks: allMarks,
              selectedMarkId: mark.id,
              height: 400,
            ),
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

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'government': return Icons.flag;
      case 'harbor': return Icons.anchor;
      case 'temporary': return Icons.circle_outlined;
      default: return Icons.location_on;
    }
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'permanent': return 'Permanent (Yellow Buoy)';
      case 'government': return 'Government (Red Buoy)';
      case 'harbor': return 'Harbor Mark';
      case 'temporary': return 'Temporary / Inflatable';
      default: return type;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Mark Form Dialog
// ═══════════════════════════════════════════════════════════════════

class _MarkFormDialog extends StatefulWidget {
  const _MarkFormDialog({this.mark});

  final Mark? mark;

  @override
  State<_MarkFormDialog> createState() => _MarkFormDialogState();
}

class _MarkFormDialogState extends State<_MarkFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;
  late final TextEditingController _descCtrl;
  late String _type;

  bool get _isEditing => widget.mark != null;

  @override
  void initState() {
    super.initState();
    final m = widget.mark;
    _idCtrl = TextEditingController(text: m?.id ?? '');
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _latCtrl = TextEditingController(
        text: m?.latitude != null ? m!.latitude!.toStringAsFixed(6) : '');
    _lonCtrl = TextEditingController(
        text: m?.longitude != null ? m!.longitude!.toStringAsFixed(6) : '');
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _type = m?.type ?? 'permanent';
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _descCtrl.dispose();
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
                    _isEditing ? 'Edit Mark' : 'New Mark',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _idCtrl,
                          enabled: !_isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Mark ID',
                            hintText: 'e.g. MY1',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            hintText: 'e.g. MY 1',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'permanent', child: Text('Permanent (Yellow Buoy)')),
                      DropdownMenuItem(
                          value: 'government', child: Text('Government (Red Buoy)')),
                      DropdownMenuItem(
                          value: 'harbor', child: Text('Harbor Mark')),
                      DropdownMenuItem(
                          value: 'temporary', child: Text('Temporary / Inflatable')),
                    ],
                    onChanged: (v) =>
                        setState(() => _type = v ?? _type),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'GPS Coordinates',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter decimal degrees (e.g. 36.624333, -121.895667)',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            hintText: '36.624333',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.north, size: 18),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final d = double.tryParse(v.trim());
                            if (d == null) return 'Invalid number';
                            if (d < -90 || d > 90) return 'Range: -90 to 90';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lonCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            hintText: '-121.895667',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.east, size: 18),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final d = double.tryParse(v.trim());
                            if (d == null) return 'Invalid number';
                            if (d < -180 || d > 180) {
                              return 'Range: -180 to 180';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g. Red can "4" — Fl R 4s, bell',
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
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    final mark = Mark(
      id: _isEditing ? widget.mark!.id : _idCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      type: _type,
      latitude: lat,
      longitude: lon,
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );
    Navigator.pop(context, mark);
  }
}
