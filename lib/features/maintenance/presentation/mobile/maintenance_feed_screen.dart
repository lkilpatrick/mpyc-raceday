import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/maintenance_request.dart';
import '../maintenance_providers.dart';

class MaintenanceFeedScreen extends ConsumerStatefulWidget {
  const MaintenanceFeedScreen({super.key});

  @override
  ConsumerState<MaintenanceFeedScreen> createState() =>
      _MaintenanceFeedScreenState();
}

class _MaintenanceFeedScreenState
    extends ConsumerState<MaintenanceFeedScreen> {
  String _boatFilter = 'All';
  MaintenanceStatus? _statusFilter;
  MaintenancePriority? _priorityFilter;

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(maintenanceRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/maintenance/report'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(_boatFilter),
                  onSelected: (_) => _cycleBoat(),
                ),
                const SizedBox(width: 8),
                ...MaintenancePriority.values.map((p) {
                  final label = p.name[0].toUpperCase() + p.name.substring(1);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(label),
                      selected: _priorityFilter == p,
                      onSelected: (sel) => setState(
                          () => _priorityFilter = sel ? p : null),
                    ),
                  );
                }),
                FilterChip(
                  label: const Text('Open'),
                  selected: _statusFilter == MaintenanceStatus.reported,
                  onSelected: (sel) => setState(() => _statusFilter =
                      sel ? MaintenanceStatus.reported : null),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Completed'),
                  selected: _statusFilter == MaintenanceStatus.completed,
                  onSelected: (sel) => setState(() => _statusFilter =
                      sel ? MaintenanceStatus.completed : null),
                ),
              ],
            ),
          ),
          // Feed
          Expanded(
            child: requestsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (requests) {
                final filtered = requests.where((r) {
                  if (_boatFilter != 'All' && r.boatName != _boatFilter) {
                    return false;
                  }
                  if (_statusFilter != null && r.status != _statusFilter) {
                    return false;
                  }
                  if (_priorityFilter != null &&
                      r.priority != _priorityFilter) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No maintenance requests.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final r = filtered[index];
                    return _RequestCard(request: r);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _cycleBoat() {
    const boats = ['All', "Duncan's Watch", 'Signal Boat', 'Mark Boat', 'Safety Boat'];
    final idx = boats.indexOf(_boatFilter);
    setState(() => _boatFilter = boats[(idx + 1) % boats.length]);
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final MaintenanceRequest request;

  @override
  Widget build(BuildContext context) {
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

    return Card(
      child: InkWell(
        onTap: () => context.go('/maintenance/detail/${request.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Photo thumbnail or icon
              if (request.photos.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    request.photos.first,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.build, size: 40),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.build, size: 28),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${request.boatName} • ${DateFormat.MMMd().format(request.reportedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request.priority.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: priorityColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
