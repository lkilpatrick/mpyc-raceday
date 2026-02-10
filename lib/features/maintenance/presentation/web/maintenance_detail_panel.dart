import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/maintenance_request.dart';
import '../maintenance_providers.dart';

class MaintenanceDetailPanel extends ConsumerStatefulWidget {
  const MaintenanceDetailPanel({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<MaintenanceDetailPanel> createState() =>
      _MaintenanceDetailPanelState();
}

class _MaintenanceDetailPanelState
    extends ConsumerState<MaintenanceDetailPanel> {
  final _commentController = TextEditingController();
  final _costController = TextEditingController();
  final _completionNotesController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    _costController.dispose();
    _completionNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(maintenanceDetailProvider(widget.requestId));

    return SizedBox(
      width: 720,
      child: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (request) {
          _costController.text =
              request.estimatedCost?.toStringAsFixed(2) ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(request.boatName)),
                    Chip(label: Text(request.category.name)),
                    Chip(
                      label: Text(request.priority.name.toUpperCase()),
                      backgroundColor: _priorityColor(request.priority)
                          .withValues(alpha: 0.15),
                    ),
                  ],
                ),
                Text(
                  'Reported by ${request.reportedBy} on ${DateFormat.yMMMd().add_jm().format(request.reportedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (request.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(request.description),
                ],

                // Photo gallery
                if (request.photos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: request.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _showLightbox(context, request.photos, i),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            request.photos[i],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const Divider(height: 24),

                // Status workflow
                Text('Status',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<MaintenanceStatus>(
                  value: request.status,
                  items: MaintenanceStatus.values.map((s) {
                    final label = _statusLabel(s);
                    return DropdownMenuItem(value: s, child: Text(label));
                  }).toList(),
                  onChanged: (s) {
                    if (s == null) return;
                    if (s == MaintenanceStatus.completed) {
                      _showCompletionDialog(request);
                    } else {
                      ref
                          .read(maintenanceRepositoryProvider)
                          .updateStatus(request.id, s);
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Assignment
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Assigned To',
                    hintText: request.assignedTo ?? 'Unassigned',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        // Use the current hint as a simple text field
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      ref
                          .read(maintenanceRepositoryProvider)
                          .assignRequest(request.id, value.trim());
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Estimated cost
                TextField(
                  controller: _costController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Cost (\$)',
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (value) {
                    final cost = double.tryParse(value);
                    if (cost != null) {
                      ref
                          .read(maintenanceRepositoryProvider)
                          .updateRequest(request.copyWith(estimatedCost: cost));
                    }
                  },
                ),

                if (request.completionNotes != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Completion Notes',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(request.completionNotes!),
                        ],
                      ),
                    ),
                  ),
                ],

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
                                Text(c.authorName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text(
                                  DateFormat.MMMd()
                                      .add_jm()
                                      .format(c.createdAt),
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
                                child: Image.network(c.photoUrl!,
                                    height: 80, fit: BoxFit.cover),
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
                      icon: const Icon(Icons.send),
                      onPressed: () => _addComment(request),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _priorityColor(MaintenancePriority p) => switch (p) {
        MaintenancePriority.low => Colors.green,
        MaintenancePriority.medium => Colors.orange,
        MaintenancePriority.high => Colors.deepOrange,
        MaintenancePriority.critical => Colors.red,
      };

  String _statusLabel(MaintenanceStatus s) => switch (s) {
        MaintenanceStatus.reported => 'Reported',
        MaintenanceStatus.acknowledged => 'Acknowledged',
        MaintenanceStatus.inProgress => 'In Progress',
        MaintenanceStatus.awaitingParts => 'Awaiting Parts',
        MaintenanceStatus.completed => 'Completed',
        MaintenanceStatus.deferred => 'Deferred',
      };

  void _showLightbox(
      BuildContext context, List<String> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 600,
          height: 500,
          child: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: photos.length,
            itemBuilder: (_, i) => Image.network(photos[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _showCompletionDialog(MaintenanceRequest request) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Completion Notes Required'),
        content: TextField(
          controller: _completionNotesController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'What was done?'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(
                dialogContext, _completionNotesController.text.trim()),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );
    if (notes != null && notes.isNotEmpty) {
      await ref.read(maintenanceRepositoryProvider).updateStatus(
            request.id,
            MaintenanceStatus.completed,
            completionNotes: notes,
          );
    }
  }

  Future<void> _addComment(MaintenanceRequest request) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    await ref.read(maintenanceRepositoryProvider).addComment(
          request.id,
          MaintenanceComment(
            id: 'c_${DateTime.now().millisecondsSinceEpoch}',
            authorId: 'admin',
            authorName: 'Admin',
            text: text,
            createdAt: DateTime.now(),
          ),
        );
    _commentController.clear();
  }
}
