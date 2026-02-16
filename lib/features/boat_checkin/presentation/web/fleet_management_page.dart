import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../../courses/data/models/fleet.dart';
import '../../data/models/boat.dart';
import '../boat_checkin_providers.dart';

class FleetManagementPage extends ConsumerStatefulWidget {
  const FleetManagementPage({super.key});

  @override
  ConsumerState<FleetManagementPage> createState() =>
      _FleetManagementPageState();
}

class _FleetManagementPageState extends ConsumerState<FleetManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _searchQuery = '';
  String _classFilter = 'All';

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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Text('Fleet Management',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              if (_tabCtrl.index == 0) ...[
                OutlinedButton.icon(
                  onPressed: _importCsv,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import CSV'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _showBoatDialog(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Boat'),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: () => _showFleetDefDialog(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Fleet'),
                ),
              ],
            ],
          ),
        ),
        TabBar(
          controller: _tabCtrl,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Boats'),
            Tab(text: 'Fleet Definitions'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildBoatsTab(),
              _buildFleetDefsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Boats Tab ──

  Widget _buildBoatsTab() {
    final fleetAsync = ref.watch(fleetProvider);
    final fleetDefs = ref.watch(fleetDefinitionsProvider).value ?? [];
    final dynamicFilters = [
      'All',
      ...fleetDefs.map((f) => f.name),
      'RC Fleet',
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search fleet...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: dynamicFilters.map((f) {
                      final isActive = _classFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(f, style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          )),
                          selected: isActive,
                          onSelected: (_) => setState(() => _classFilter = f),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: fleetAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (boats) {
              var filtered = boats;
              if (_classFilter == 'RC Fleet') {
                filtered = filtered.where((b) => b.isRCFleet).toList();
              } else if (_classFilter != 'All') {
                filtered = filtered.where((b) =>
                    (b.fleet ?? b.boatClass).toLowerCase() == _classFilter.toLowerCase()).toList();
              }
              if (_searchQuery.isNotEmpty) {
                filtered = filtered
                    .where((b) =>
                        b.sailNumber.toLowerCase().contains(_searchQuery) ||
                        b.boatName.toLowerCase().contains(_searchQuery) ||
                        b.ownerName.toLowerCase().contains(_searchQuery) ||
                        b.boatClass.toLowerCase().contains(_searchQuery) ||
                        (b.fleet ?? '').toLowerCase().contains(_searchQuery))
                    .toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sailing, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        boats.isEmpty
                            ? 'No boats in the fleet yet'
                            : 'No boats match your search',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      if (boats.isEmpty) ...[
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _showBoatDialog(null),
                          icon: const Icon(Icons.add),
                          label: const Text('Add your first boat'),
                        ),
                      ],
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Sail #')),
                      DataColumn(label: Text('Boat Name')),
                      DataColumn(label: Text('Owner/Skipper')),
                      DataColumn(label: Text('Class')),
                      DataColumn(label: Text('Fleet')),
                      DataColumn(label: Text('PHRF')),
                      DataColumn(label: Text('RC')),
                      DataColumn(label: Text('Last Raced')),
                      DataColumn(label: Text('Race Count')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: filtered.map((b) {
                      return DataRow(cells: [
                        DataCell(Text(b.sailNumber,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(b.boatName)),
                        DataCell(Text(b.ownerName)),
                        DataCell(Text(b.boatClass)),
                        DataCell(Text(b.fleet ?? '—')),
                        DataCell(Text(b.phrfRating?.toString() ?? '—')),
                        DataCell(b.isRCFleet
                            ? Icon(Icons.anchor, size: 16, color: Colors.blue.shade700)
                            : const SizedBox.shrink()),
                        DataCell(Text(b.lastRacedAt != null
                            ? DateFormat.yMMMd().format(b.lastRacedAt!)
                            : 'Never')),
                        DataCell(Text('${b.raceCount}')),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _showBoatDialog(b),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18,
                                  color: Colors.red),
                              onPressed: () => _deleteBoat(b),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Fleet Definitions Tab ──

  Widget _buildFleetDefsTab() {
    final defsAsync = ref.watch(fleetDefinitionsProvider);
    final boatsAsync = ref.watch(fleetProvider);

    return defsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (defs) {
        final boats = boatsAsync.value ?? [];
        if (defs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('No fleet definitions yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 4),
                const Text(
                  'Define fleets like "PHRF A", "One Design", etc.\n'
                  'Then assign boats to each fleet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _seedDefaultFleets,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Seed Default Fleets'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showFleetDefDialog(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Custom Fleet'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: defs.length,
          itemBuilder: (_, i) {
            final fleet = defs[i];
            final boatCount = boats.where((b) => b.fleet == fleet.name).length;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: fleet.type == 'one_design'
                      ? Colors.teal.shade100
                      : Colors.indigo.shade100,
                  child: Icon(
                    fleet.type == 'one_design'
                        ? Icons.sailing
                        : Icons.speed,
                    color: fleet.type == 'one_design'
                        ? Colors.teal
                        : Colors.indigo,
                    size: 20,
                  ),
                ),
                title: Text(fleet.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${fleet.type == 'one_design' ? 'One Design' : 'Handicap'}'
                  '${fleet.description.isNotEmpty ? ' — ${fleet.description}' : ''}'
                  ' • $boatCount boat${boatCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _showFleetDefDialog(fleet),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () => _deleteFleetDef(fleet),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final csvContent = String.fromCharCodes(bytes);

    try {
      await ref
          .read(boatCheckinRepositoryProvider)
          .importFleetFromCsv(csvContent);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fleet imported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    }
  }

  void _showBoatDialog(Boat? existing) {
    final sailCtrl =
        TextEditingController(text: existing?.sailNumber ?? '');
    final nameCtrl =
        TextEditingController(text: existing?.boatName ?? '');
    final ownerCtrl =
        TextEditingController(text: existing?.ownerName ?? '');
    final classCtrl =
        TextEditingController(text: existing?.boatClass ?? '');
    final phrfCtrl = TextEditingController(
        text: existing?.phrfRating?.toString() ?? '');
    bool isRCFleet = existing?.isRCFleet ?? false;
    String? selectedFleet = existing?.fleet;

    final fleetDefs = ref.read(fleetDefinitionsProvider).value ?? [];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Boat' : 'Add Boat'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Sail Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Boat Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Owner/Skipper',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: classCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Boat Class',
                          hintText: 'e.g. J/24, Shields',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: phrfCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'PHRF Rating',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Fleet assignment dropdown
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: selectedFleet != null &&
                          fleetDefs.any((f) => f.name == selectedFleet)
                      ? selectedFleet
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Fleet',
                    hintText: 'Assign to a fleet',
                    prefixIcon: Icon(Icons.groups, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No fleet assigned',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    ...fleetDefs.map((f) => DropdownMenuItem(
                          value: f.name,
                          child: Text(f.name),
                        )),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedFleet = v),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Race Committee Fleet'),
                  subtitle: const Text('Club-owned boat used for RC duties'),
                  value: isRCFleet,
                  onChanged: (v) => setDialogState(() => isRCFleet = v),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final boat = Boat(
                  id: existing?.id ?? '',
                  sailNumber: sailCtrl.text.trim(),
                  boatName: nameCtrl.text.trim(),
                  ownerName: ownerCtrl.text.trim(),
                  boatClass: classCtrl.text.trim(),
                  phrfRating: int.tryParse(phrfCtrl.text),
                  lastRacedAt: existing?.lastRacedAt,
                  raceCount: existing?.raceCount ?? 0,
                  isRCFleet: isRCFleet,
                  fleet: selectedFleet,
                );
                await ref
                    .read(boatCheckinRepositoryProvider)
                    .saveBoat(boat);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFleetDefDialog(Fleet? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String type = existing?.type ?? 'handicap';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Fleet' : 'Create Fleet'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Fleet Name',
                    hintText: 'e.g. PHRF A, One Design, Cruiser',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Fleet Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'handicap', child: Text('Handicap (PHRF)')),
                    DropdownMenuItem(
                        value: 'one_design', child: Text('One Design')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => type = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                await ref
                    .read(boatCheckinRepositoryProvider)
                    .saveFleetDefinition(Fleet(
                      id: existing?.id ?? '',
                      name: name,
                      type: type,
                      description: descCtrl.text.trim(),
                    ));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFleetDef(Fleet fleet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Fleet?'),
        content: Text(
          'Delete "${fleet.name}"?\n'
          'Boats assigned to this fleet will keep their assignment '
          'but it won\'t appear in dropdowns.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref
        .read(boatCheckinRepositoryProvider)
        .deleteFleetDefinition(fleet.id);
  }

  Future<void> _seedDefaultFleets() async {
    final repo = ref.read(boatCheckinRepositoryProvider);
    final defaults = [
      const Fleet(id: '', name: 'Shields', type: 'one_design', description: 'Shields one-design fleet'),
      const Fleet(id: '', name: 'Santana 22', type: 'one_design', description: 'Santana 22 one-design fleet'),
      const Fleet(id: '', name: 'PHRF A', type: 'handicap', description: 'PHRF handicap fleet A (fast)'),
      const Fleet(id: '', name: 'PHRF B', type: 'handicap', description: 'PHRF handicap fleet B'),
      const Fleet(id: '', name: 'Cruiser', type: 'handicap', description: 'Cruiser/cruiser-racer fleet'),
    ];
    for (final fleet in defaults) {
      await repo.saveFleetDefinition(fleet);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default fleets created!')),
      );
    }
  }

  Future<void> _deleteBoat(Boat boat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Boat?'),
        content: Text('Remove ${boat.boatName} (${boat.sailNumber})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(boatCheckinRepositoryProvider).deleteBoat(boat.id);
  }
}
