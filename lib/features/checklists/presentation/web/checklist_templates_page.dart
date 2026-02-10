import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/checklist.dart';
import '../checklist_providers.dart';

class ChecklistTemplatesPage extends ConsumerStatefulWidget {
  const ChecklistTemplatesPage({super.key});

  @override
  ConsumerState<ChecklistTemplatesPage> createState() =>
      _ChecklistTemplatesPageState();
}

class _ChecklistTemplatesPageState
    extends ConsumerState<ChecklistTemplatesPage> {
  Checklist? _editing;

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(checklistTemplatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _createNew,
              icon: const Icon(Icons.add),
              label: const Text('New Template'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              // Template list
              Expanded(
                flex: 2,
                child: Card(
                  child: templatesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (templates) => ListView(
                      children: templates.map((t) {
                        final isSelected = _editing?.id == t.id;
                        return ListTile(
                          selected: isSelected,
                          title: Text(t.name),
                          subtitle: Text(
                            'v${t.version} • ${t.items.length} items',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: 'Duplicate',
                                onPressed: () => _duplicate(t),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _deleteTemplate(t),
                              ),
                            ],
                          ),
                          onTap: () => setState(() => _editing = t),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Editor
              Expanded(
                flex: 3,
                child: _editing != null
                    ? _TemplateEditor(
                        key: ValueKey(_editing!.id),
                        checklist: _editing!,
                        onSaved: (updated) =>
                            setState(() => _editing = updated),
                      )
                    : const Card(
                        child: Center(
                          child: Text('Select a template to edit'),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _createNew() {
    final now = DateTime.now();
    final newTemplate = Checklist(
      id: 'custom_${now.millisecondsSinceEpoch}',
      name: 'New Checklist',
      type: ChecklistType.custom,
      items: const [],
      version: 1,
      lastModifiedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
      lastModifiedAt: now,
      isActive: true,
    );
    ref.read(checklistsRepositoryProvider).saveTemplate(newTemplate);
    setState(() => _editing = newTemplate);
  }

  void _duplicate(Checklist t) {
    final now = DateTime.now();
    final dup = Checklist(
      id: '${t.id}_copy_${now.millisecondsSinceEpoch}',
      name: '${t.name} (Copy)',
      type: t.type,
      items: t.items,
      version: 1,
      lastModifiedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
      lastModifiedAt: now,
      isActive: true,
    );
    ref.read(checklistsRepositoryProvider).saveTemplate(dup);
  }

  Future<void> _deleteTemplate(Checklist t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${t.name}"? This cannot be undone.'),
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
    try {
      await ref.read(checklistsRepositoryProvider).deleteTemplate(t.id);
      if (_editing?.id == t.id) {
        setState(() => _editing = null);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _TemplateEditor extends ConsumerStatefulWidget {
  const _TemplateEditor({
    super.key,
    required this.checklist,
    required this.onSaved,
  });

  final Checklist checklist;
  final ValueChanged<Checklist> onSaved;

  @override
  ConsumerState<_TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends ConsumerState<_TemplateEditor> {
  late TextEditingController _nameController;
  late List<ChecklistItem> _items;
  late ChecklistType _type;
  String _changeNotes = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.checklist.name);
    _items = List.from(widget.checklist.items);
    _type = widget.checklist.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group items by category
    final categories = <String, List<ChecklistItem>>{};
    for (final item in _items) {
      categories.putIfAbsent(item.category, () => []).add(item);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<ChecklistType>(
                  value: _type,
                  items: ChecklistType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'v${widget.checklist.version} • Last modified ${DateFormat.yMMMd().format(widget.checklist.lastModifiedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.category),
                  label: const Text('Add Category'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _items.removeAt(oldIndex);
                    _items.insert(newIndex, item);
                    // Update order
                    for (var i = 0; i < _items.length; i++) {
                      _items[i] = _items[i].copyWith(order: i + 1);
                    }
                  });
                },
                children: _items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return ListTile(
                    key: ValueKey(item.id),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.category} • ${item.isCritical ? "CRITICAL" : ""} ${item.requiresPhoto ? "📷" : ""} ${item.requiresNote ? "📝" : ""}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.warning,
                            color: item.isCritical ? Colors.red : Colors.grey,
                          ),
                          tooltip: 'Toggle critical',
                          onPressed: () => setState(() {
                            _items[i] =
                                item.copyWith(isCritical: !item.isCritical);
                          }),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.camera_alt,
                            color:
                                item.requiresPhoto ? Colors.blue : Colors.grey,
                          ),
                          tooltip: 'Toggle photo required',
                          onPressed: () => setState(() {
                            _items[i] = item.copyWith(
                                requiresPhoto: !item.requiresPhoto);
                          }),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.note,
                            color:
                                item.requiresNote ? Colors.blue : Colors.grey,
                          ),
                          tooltip: 'Toggle note required',
                          onPressed: () => setState(() {
                            _items[i] = item.copyWith(
                                requiresNote: !item.requiresNote);
                          }),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              setState(() => _items.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Change notes'),
              onChanged: (v) => _changeNotes = v,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _save,
              child: const Text('Save Template'),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final id = 'item_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _items.add(ChecklistItem(
        id: id,
        title: 'New Item',
        description: '',
        category: _items.isNotEmpty ? _items.last.category : 'General',
        requiresPhoto: false,
        requiresNote: false,
        isCritical: false,
        order: _items.length + 1,
      ));
    });
  }

  void _addCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      _addItemToCategory(name);
    }
  }

  void _addItemToCategory(String category) {
    final id = 'item_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _items.add(ChecklistItem(
        id: id,
        title: 'New Item',
        description: '',
        category: category,
        requiresPhoto: false,
        requiresNote: false,
        isCritical: false,
        order: _items.length + 1,
      ));
    });
  }

  Future<void> _save() async {
    final updated = widget.checklist.copyWith(
      name: _nameController.text.trim(),
      type: _type,
      items: _items,
      version: widget.checklist.version + 1,
      lastModifiedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
      lastModifiedAt: DateTime.now(),
    );
    await ref.read(checklistsRepositoryProvider).saveTemplate(updated);
    widget.onSaved(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template saved')),
      );
    }
  }
}
