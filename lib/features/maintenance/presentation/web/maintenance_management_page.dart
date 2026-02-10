import 'package:data_table_2/data_table_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/maintenance_request.dart';
import '../maintenance_providers.dart';
import 'maintenance_detail_panel.dart';

class MaintenanceManagementPage extends ConsumerStatefulWidget {
  const MaintenanceManagementPage({super.key});

  @override
  ConsumerState<MaintenanceManagementPage> createState() =>
      _MaintenanceManagementPageState();
}

class _MaintenanceManagementPageState
    extends ConsumerState<MaintenanceManagementPage> {
  String _boatFilter = 'All';
  MaintenancePriority? _priorityFilter;
  MaintenanceStatus? _statusFilter;
  String _search = '';
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(maintenanceRequestsProvider);

    return Column(
      children: [
        // Filters
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DropdownButton<String>(
              value: _boatFilter,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Boats')),
                DropdownMenuItem(value: "Duncan's Watch", child: Text("Duncan's Watch")),
                DropdownMenuItem(value: 'Signal Boat', child: Text('Signal Boat')),
                DropdownMenuItem(value: 'Mark Boat', child: Text('Mark Boat')),
                DropdownMenuItem(value: 'Safety Boat', child: Text('Safety Boat')),
              ],
              onChanged: (v) => setState(() => _boatFilter = v ?? 'All'),
            ),
            DropdownButton<MaintenancePriority?>(
              value: _priorityFilter,
              hint: const Text('Priority'),
              items: [
                const DropdownMenuItem<MaintenancePriority?>(
                    value: null, child: Text('Any Priority')),
                ...MaintenancePriority.values.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name[0].toUpperCase() + p.name.substring(1)))),
              ],
              onChanged: (v) => setState(() => _priorityFilter = v),
            ),
            DropdownButton<MaintenanceStatus?>(
              value: _statusFilter,
              hint: const Text('Status'),
              items: [
                const DropdownMenuItem<MaintenanceStatus?>(
                    value: null, child: Text('Any Status')),
                ...MaintenanceStatus.values.map((s) {
                  final label = switch (s) {
                    MaintenanceStatus.reported => 'Reported',
                    MaintenanceStatus.acknowledged => 'Acknowledged',
                    MaintenanceStatus.inProgress => 'In Progress',
                    MaintenanceStatus.awaitingParts => 'Awaiting Parts',
                    MaintenanceStatus.completed => 'Completed',
                    MaintenanceStatus.deferred => 'Deferred',
                  };
                  return DropdownMenuItem(value: s, child: Text(label));
                }),
              ],
              onChanged: (v) => setState(() => _statusFilter = v),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
            FilledButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Request'),
            ),
            if (_selectedIds.isNotEmpty) ...[
              FilledButton(
                onPressed: () => _bulkStatus(MaintenanceStatus.acknowledged),
                child: const Text('Acknowledge Selected'),
              ),
              OutlinedButton(
                onPressed: () => _bulkStatus(MaintenanceStatus.deferred),
                child: const Text('Defer Selected'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // Data table
        Expanded(
          child: requestsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (requests) {
              final filtered = requests.where(_matchesFilter).toList();
              return DataTable2(
                columns: const [
                  DataColumn2(label: Text('ID'), size: ColumnSize.S),
                  DataColumn2(label: Text('Boat')),
                  DataColumn2(label: Text('Title'), size: ColumnSize.L),
                  DataColumn2(label: Text('Category')),
                  DataColumn2(label: Text('Priority')),
                  DataColumn2(label: Text('Status')),
                  DataColumn2(label: Text('Reported By')),
                  DataColumn2(label: Text('Date')),
                  DataColumn2(label: Text('Assigned To')),
                  DataColumn2(label: Text('Age')),
                ],
                rows: filtered.map((r) {
                  final selected = _selectedIds.contains(r.id);
                  final age = DateTime.now().difference(r.reportedAt).inDays;
                  final priorityColor = switch (r.priority) {
                    MaintenancePriority.low => Colors.green,
                    MaintenancePriority.medium => Colors.orange,
                    MaintenancePriority.high => Colors.deepOrange,
                    MaintenancePriority.critical => Colors.red,
                  };
                  final statusLabel = switch (r.status) {
                    MaintenanceStatus.reported => 'Reported',
                    MaintenanceStatus.acknowledged => 'Acknowledged',
                    MaintenanceStatus.inProgress => 'In Progress',
                    MaintenanceStatus.awaitingParts => 'Awaiting Parts',
                    MaintenanceStatus.completed => 'Completed',
                    MaintenanceStatus.deferred => 'Deferred',
                  };

                  return DataRow2(
                    selected: selected,
                    color: WidgetStateProperty.resolveWith((states) {
                      if (r.priority == MaintenancePriority.critical) {
                        return Colors.red.withValues(alpha: 0.05);
                      }
                      if (r.priority == MaintenancePriority.high) {
                        return Colors.orange.withValues(alpha: 0.05);
                      }
                      return null;
                    }),
                    onSelectChanged: (_) => setState(() {
                      if (selected) {
                        _selectedIds.remove(r.id);
                      } else {
                        _selectedIds.add(r.id);
                      }
                    }),
                    onTap: () => _openDetail(r.id),
                    cells: [
                      DataCell(Text(r.id.length > 6
                          ? r.id.substring(0, 6)
                          : r.id)),
                      DataCell(Text(r.boatName)),
                      DataCell(Text(r.title)),
                      DataCell(Text(r.category.name)),
                      DataCell(Text(
                        r.priority.name.toUpperCase(),
                        style: TextStyle(
                            color: priorityColor,
                            fontWeight: FontWeight.bold),
                      )),
                      DataCell(Text(statusLabel)),
                      DataCell(Text(r.reportedBy)),
                      DataCell(Text(DateFormat.MMMd().format(r.reportedAt))),
                      DataCell(Text(r.assignedTo ?? '—')),
                      DataCell(Text('${age}d')),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _matchesFilter(MaintenanceRequest r) {
    if (_boatFilter != 'All' && r.boatName != _boatFilter) return false;
    if (_priorityFilter != null && r.priority != _priorityFilter) return false;
    if (_statusFilter != null && r.status != _statusFilter) return false;
    if (_search.isNotEmpty &&
        !r.title.toLowerCase().contains(_search.toLowerCase()) &&
        !r.description.toLowerCase().contains(_search.toLowerCase())) {
      return false;
    }
    return true;
  }

  void _openDetail(String requestId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MaintenanceDetailPanel(requestId: requestId),
    );
  }

  Future<void> _bulkStatus(MaintenanceStatus status) async {
    await ref
        .read(maintenanceRepositoryProvider)
        .bulkUpdateStatus(_selectedIds.toList(), status);
    setState(_selectedIds.clear);
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String boat = "Duncan's Watch";
    MaintenancePriority priority = MaintenancePriority.medium;
    MaintenanceCategory category = MaintenanceCategory.general;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('New Maintenance Request'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: boat,
                  decoration: const InputDecoration(labelText: 'Boat'),
                  items: ["Duncan's Watch", 'Signal Boat', 'Mark Boat', 'Safety Boat']
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => boat = v ?? boat),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<MaintenancePriority>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: MaintenancePriority.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => priority = v ?? priority),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<MaintenanceCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: MaintenanceCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name[0].toUpperCase() + c.name.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => category = v ?? category),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final request = MaintenanceRequest(
                  id: '',
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  priority: priority,
                  reportedBy:
                      FirebaseAuth.instance.currentUser?.displayName ?? 'Admin',
                  reportedAt: DateTime.now(),
                  status: MaintenanceStatus.reported,
                  photos: const [],
                  boatName: boat,
                  category: category,
                  comments: const [],
                );
                await ref
                    .read(maintenanceRepositoryProvider)
                    .createRequest(request);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
