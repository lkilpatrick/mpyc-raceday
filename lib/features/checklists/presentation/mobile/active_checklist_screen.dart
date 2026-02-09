import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/models/checklist.dart';
import '../checklist_providers.dart';

class ActiveChecklistScreen extends ConsumerStatefulWidget {
  const ActiveChecklistScreen({super.key, required this.completionId});

  final String completionId;

  @override
  ConsumerState<ActiveChecklistScreen> createState() =>
      _ActiveChecklistScreenState();
}

class _ActiveChecklistScreenState
    extends ConsumerState<ActiveChecklistScreen> {
  final _signOffController = TextEditingController();

  @override
  void dispose() {
    _signOffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completionAsync = ref.watch(completionProvider(widget.completionId));
    final templatesAsync = ref.watch(checklistTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Active Checklist')),
      body: completionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (completion) {
          final template = templatesAsync.value
              ?.where((t) => t.id == completion.checklistId)
              .firstOrNull;
          if (template == null) {
            return const Center(child: Text('Template not found'));
          }

          final checked = completion.items.where((i) => i.checked).length;
          final total = completion.items.length;
          final progress = total > 0 ? checked / total : 0.0;

          // Group items by category
          final categories = <String, List<ChecklistItem>>{};
          for (final item in template.items) {
            categories.putIfAbsent(item.category, () => []).add(item);
          }

          // Check if all critical items are done
          final criticalItems = template.items.where((i) => i.isCritical);
          final allCriticalDone = criticalItems.every((ci) {
            final completed = completion.items
                .where((i) => i.itemId == ci.id)
                .firstOrNull;
            return completed?.checked ?? false;
          });

          return Column(
            children: [
              // Sticky progress header
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Started ${DateFormat.jm().format(completion.startedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 4),
                    Text(
                      '$checked / $total items complete',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Checklist items grouped by category
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: categories.entries.map((entry) {
                    final catItems = entry.value;
                    final catChecked = catItems.where((ci) {
                      final done = completion.items
                          .where((i) => i.itemId == ci.id)
                          .firstOrNull;
                      return done?.checked ?? false;
                    }).length;

                    return ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(entry.key),
                      subtitle: Text('$catChecked / ${catItems.length}'),
                      children: catItems.map((templateItem) {
                        final completedItem = completion.items
                            .where((i) => i.itemId == templateItem.id)
                            .firstOrNull;
                        return _ChecklistItemTile(
                          templateItem: templateItem,
                          completedItem: completedItem,
                          completionId: widget.completionId,
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: completionAsync.when(
        loading: () => null,
        error: (_, __) => null,
        data: (completion) {
          if (completion.status != ChecklistCompletionStatus.inProgress) {
            return null;
          }
          final templatesVal = templatesAsync.value;
          final template = templatesVal
              ?.where((t) => t.id == completion.checklistId)
              .firstOrNull;
          final criticalItems =
              template?.items.where((i) => i.isCritical) ?? [];
          final allCriticalDone = criticalItems.every((ci) {
            final completed = completion.items
                .where((i) => i.itemId == ci.id)
                .firstOrNull;
            return completed?.checked ?? false;
          });

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed:
                    allCriticalDone ? () => _requestSignOff(completion) : null,
                icon: const Icon(Icons.check_circle),
                label: Text(
                  allCriticalDone
                      ? 'Complete & Request Sign-Off'
                      : 'Complete all critical items first',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _requestSignOff(ChecklistCompletion completion) async {
    final repo = ref.read(checklistsRepositoryProvider);
    await repo.requestSignOff(widget.completionId);
    if (!mounted) return;

    // Show sign-off dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Sign-Off Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A second crew member must enter their member number to co-sign this checklist.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _signOffController,
              decoration: const InputDecoration(
                labelText: 'Member number',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              final signOffId = _signOffController.text.trim();
              if (signOffId.isEmpty) return;
              await repo.signOff(
                completionId: widget.completionId,
                signOffUserId: signOffId,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checklist signed off!')),
                );
              }
            },
            child: const Text('Sign Off'),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItemTile extends ConsumerStatefulWidget {
  const _ChecklistItemTile({
    required this.templateItem,
    required this.completedItem,
    required this.completionId,
  });

  final ChecklistItem templateItem;
  final CompletedItem? completedItem;
  final String completionId;

  @override
  ConsumerState<_ChecklistItemTile> createState() => _ChecklistItemTileState();
}

class _ChecklistItemTileState extends ConsumerState<_ChecklistItemTile> {
  final _noteController = TextEditingController();
  final _picker = ImagePicker();
  bool _showNote = false;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.completedItem?.note ?? '';
  }

  @override
  void didUpdateWidget(covariant _ChecklistItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completedItem?.note != oldWidget.completedItem?.note) {
      _noteController.text = widget.completedItem?.note ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.templateItem;
    final completed = widget.completedItem;
    final isChecked = completed?.checked ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _toggle(!isChecked),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Large checkbox for gloved/wet hands
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Checkbox(
                        value: isChecked,
                        onChanged: (v) => _toggle(v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (item.isCritical)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.warning_amber,
                                    color: Colors.red.shade700,
                                    size: 18,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: item.isCritical
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    decoration: isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (item.description.isNotEmpty)
                            Text(
                              item.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (isChecked && completed != null)
                            Text(
                              'Checked ${DateFormat.jm().format(completed.timestamp)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.green),
                            ),
                        ],
                      ),
                    ),
                    // Action icons
                    if (item.requiresPhoto)
                      IconButton(
                        icon: Icon(
                          completed?.photoUrl != null
                              ? Icons.photo
                              : Icons.camera_alt,
                          color: completed?.photoUrl != null
                              ? Colors.green
                              : null,
                        ),
                        onPressed: _takePhoto,
                      ),
                    if (item.requiresNote)
                      IconButton(
                        icon: Icon(
                          Icons.note_add,
                          color: (completed?.note?.isNotEmpty ?? false)
                              ? Colors.green
                              : null,
                        ),
                        onPressed: () =>
                            setState(() => _showNote = !_showNote),
                      ),
                  ],
                ),
              ),
            ),
            // Photo thumbnail
            if (completed?.photoUrl != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(60, 0, 12, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    completed!.photoUrl!,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
              ),
            // Note field
            if (_showNote || (item.requiresNote && isChecked))
              Padding(
                padding: const EdgeInsets.fromLTRB(60, 0, 12, 8),
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    isDense: true,
                  ),
                  maxLines: 2,
                  onSubmitted: (value) => _saveNote(value),
                  onTapOutside: (_) => _saveNote(_noteController.text),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(bool checked) async {
    final repo = ref.read(checklistsRepositoryProvider);
    await repo.updateItem(
      completionId: widget.completionId,
      itemId: widget.templateItem.id,
      checked: checked,
    );
  }

  Future<void> _saveNote(String note) async {
    final repo = ref.read(checklistsRepositoryProvider);
    await repo.updateItem(
      completionId: widget.completionId,
      itemId: widget.templateItem.id,
      checked: widget.completedItem?.checked ?? false,
      note: note,
    );
  }

  Future<void> _takePhoto() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    final repo = ref.read(checklistsRepositoryProvider);
    final url = await repo.uploadPhoto(
      completionId: widget.completionId,
      itemId: widget.templateItem.id,
      imageBytes: Uint8List.fromList(bytes),
    );
    await repo.updateItem(
      completionId: widget.completionId,
      itemId: widget.templateItem.id,
      checked: widget.completedItem?.checked ?? true,
      photoUrl: url,
    );
  }
}
