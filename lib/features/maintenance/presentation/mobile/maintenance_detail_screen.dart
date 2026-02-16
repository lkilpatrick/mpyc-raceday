import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/models/maintenance_request.dart';
import '../maintenance_providers.dart';

class MaintenanceDetailScreen extends ConsumerStatefulWidget {
  const MaintenanceDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<MaintenanceDetailScreen> createState() =>
      _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState
    extends ConsumerState<MaintenanceDetailScreen> {
  final _commentController = TextEditingController();
  final _picker = ImagePicker();
  int _photoPage = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(maintenanceDetailProvider(widget.requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Issue Detail')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (request) {
          final priorityColor = switch (request.priority) {
            MaintenancePriority.low => Colors.green,
            MaintenancePriority.medium => Colors.orange,
            MaintenancePriority.high => Colors.deepOrange,
            MaintenancePriority.critical => Colors.red,
          };
          final statusLabel = switch (request.status) {
            MaintenanceStatus.reported => 'Reported',
            MaintenanceStatus.acknowledged => 'Acknowledged',
            MaintenanceStatus.inProgress => 'In Progress',
            MaintenanceStatus.awaitingParts => 'Awaiting Parts',
            MaintenanceStatus.completed => 'Completed',
            MaintenanceStatus.deferred => 'Deferred',
          };

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // Title & meta
              Text(
                request.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(request.boatName),
                    avatar: const Icon(Icons.sailing, size: 16),
                  ),
                  Chip(
                    label: Text(request.priority.name.toUpperCase()),
                    backgroundColor: priorityColor.withValues(alpha: 0.15),
                  ),
                  Chip(label: Text(statusLabel)),
                  Chip(
                    label: Text(request.category.name),
                    avatar: const Icon(Icons.category, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Reported ${DateFormat.yMMMd().add_jm().format(request.reportedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (request.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(request.description),
              ],

              // Photo gallery
              if (request.photos.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: request.photos.length,
                    onPageChanged: (i) => setState(() => _photoPage = i),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        request.photos[i],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                ),
                if (request.photos.length > 1)
                  Center(
                    child: Text(
                      '${_photoPage + 1} / ${request.photos.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],

              // Status update (for assigned crew)
              const Divider(height: 24),
              Text(
                'Update Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: MaintenanceStatus.values.map((s) {
                  final label = switch (s) {
                    MaintenanceStatus.reported => 'Reported',
                    MaintenanceStatus.acknowledged => 'Acknowledged',
                    MaintenanceStatus.inProgress => 'In Progress',
                    MaintenanceStatus.awaitingParts => 'Awaiting Parts',
                    MaintenanceStatus.completed => 'Completed',
                    MaintenanceStatus.deferred => 'Deferred',
                  };
                  return ChoiceChip(
                    label: Text(label),
                    selected: request.status == s,
                    onSelected: (_) => _updateStatus(request, s),
                  );
                }).toList(),
              ),

              // Comments
              const Divider(height: 24),
              Text(
                'Comments (${request.comments.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...request.comments.map((c) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                c.authorName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat.MMMd().add_jm().format(c.createdAt),
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(c.text),
                          if (c.photoUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  c.photoUrl!,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () => _addCommentWithPhoto(request),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _addComment(request),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(
      MaintenanceRequest request, MaintenanceStatus status) async {
    if (status == MaintenanceStatus.completed) {
      final controller = TextEditingController();
      final notes = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Completion Notes'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration:
                const InputDecoration(labelText: 'What was done?'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Complete'),
            ),
          ],
        ),
      );
      if (notes == null) return;
      await ref
          .read(maintenanceRepositoryProvider)
          .updateStatus(request.id, status, completionNotes: notes);
    } else {
      await ref
          .read(maintenanceRepositoryProvider)
          .updateStatus(request.id, status);
    }
  }

  Future<void> _addComment(MaintenanceRequest request) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    await ref.read(maintenanceRepositoryProvider).addComment(
          request.id,
          MaintenanceComment(
            id: 'c_${DateTime.now().millisecondsSinceEpoch}',
            authorId: userId,
            authorName: userId,
            text: text,
            createdAt: DateTime.now(),
          ),
        );
    _commentController.clear();
  }

  Future<void> _addCommentWithPhoto(MaintenanceRequest request) async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    final repo = ref.read(maintenanceRepositoryProvider);
    final url = await repo.uploadPhoto(
      requestId: request.id,
      imageBytes: Uint8List.fromList(bytes),
      fileName: 'comment_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    await repo.addComment(
      request.id,
      MaintenanceComment(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        authorId: userId,
        authorName: userId,
        text: _commentController.text.trim().isEmpty
            ? 'Photo added'
            : _commentController.text.trim(),
        photoUrl: url,
        createdAt: DateTime.now(),
      ),
    );
    _commentController.clear();
  }
}
