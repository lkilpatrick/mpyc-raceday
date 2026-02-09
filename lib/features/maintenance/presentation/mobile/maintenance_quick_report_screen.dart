import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/maintenance_request.dart';
import '../maintenance_providers.dart';

class MaintenanceQuickReportScreen extends ConsumerStatefulWidget {
  const MaintenanceQuickReportScreen({super.key});

  @override
  ConsumerState<MaintenanceQuickReportScreen> createState() =>
      _MaintenanceQuickReportScreenState();
}

class _MaintenanceQuickReportScreenState
    extends ConsumerState<MaintenanceQuickReportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _picker = ImagePicker();

  String _boat = "Duncan's Watch";
  MaintenancePriority _priority = MaintenancePriority.medium;
  MaintenanceCategory _category = MaintenanceCategory.general;
  final List<Uint8List> _photos = [];
  bool _submitting = false;

  static const _boats = [
    "Duncan's Watch",
    'Signal Boat',
    'Mark Boat',
    'Safety Boat',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Boat selector
          Text('Boat', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _boats.map((boat) {
              final selected = _boat == boat;
              return ChoiceChip(
                label: Text(boat),
                selected: selected,
                onSelected: (_) => setState(() => _boat = boat),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'Brief description of the issue',
            ),
          ),
          const SizedBox(height: 12),

          // Description
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Add more detail later if needed',
            ),
          ),
          const SizedBox(height: 16),

          // Priority
          Text('Priority', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MaintenancePriority.values.map((p) {
              final color = switch (p) {
                MaintenancePriority.low => Colors.green,
                MaintenancePriority.medium => Colors.orange,
                MaintenancePriority.high => Colors.deepOrange,
                MaintenancePriority.critical => Colors.red,
              };
              final label = p.name[0].toUpperCase() + p.name.substring(1);
              return ChoiceChip(
                label: Text(label),
                selected: _priority == p,
                selectedColor: color.withValues(alpha: 0.3),
                avatar: CircleAvatar(backgroundColor: color, radius: 6),
                onSelected: (_) => setState(() => _priority = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Category
          Text('Category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MaintenanceCategory.values.map((c) {
              final label = c.name[0].toUpperCase() + c.name.substring(1);
              return ChoiceChip(
                label: Text(label),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Photos
          Text('Photos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._photos.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        entry.value,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _photos.removeAt(entry.key)),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              if (_photos.length < 5)
                InkWell(
                  onTap: _takePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt, size: 32),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Submit Report'),
          ),
        ],
      ),
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
    setState(() => _photos.add(Uint8List.fromList(bytes)));
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    setState(() => _submitting = true);
    final repo = ref.read(maintenanceRepositoryProvider);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final request = MaintenanceRequest(
      id: '',
      title: title,
      description: _descController.text.trim(),
      priority: _priority,
      reportedBy: userId,
      reportedAt: DateTime.now(),
      status: MaintenanceStatus.reported,
      photos: const [],
      boatName: _boat,
      category: _category,
      comments: const [],
    );

    final created = await repo.createRequest(request);

    // Upload photos
    for (final bytes in _photos) {
      await repo.uploadPhoto(requestId: created.id, imageBytes: bytes);
    }

    if (mounted) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue reported!')),
      );
      context.go('/maintenance/feed');
    }
  }
}
