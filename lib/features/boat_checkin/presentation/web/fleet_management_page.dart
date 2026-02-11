import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../data/models/boat.dart';
import '../boat_checkin_providers.dart';

class FleetManagementPage extends ConsumerStatefulWidget {
  const FleetManagementPage({super.key});

  @override
  ConsumerState<FleetManagementPage> createState() =>
      _FleetManagementPageState();
}

class _FleetManagementPageState extends ConsumerState<FleetManagementPage> {
  String _searchQuery = '';
  String _classFilter = 'All';

  static const _classFilters = ['All', 'Shields', 'Santana 22', 'PHRF A', 'PHRF B', 'RC Fleet'];

  @override
  Widget build(BuildContext context) {
    final fleetAsync = ref.watch(fleetProvider);

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
            ],
          ),
        ),
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
                    children: _classFilters.map((f) {
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
              // Class filter
              if (_classFilter == 'RC Fleet') {
                filtered = filtered.where((b) => b.isRCFleet).toList();
              } else if (_classFilter != 'All') {
                filtered = filtered.where((b) =>
                    b.boatClass.toLowerCase() == _classFilter.toLowerCase()).toList();
              }
              if (_searchQuery.isNotEmpty) {
                filtered = filtered
                    .where((b) =>
                        b.sailNumber.toLowerCase().contains(_searchQuery) ||
                        b.boatName.toLowerCase().contains(_searchQuery) ||
                        b.ownerName.toLowerCase().contains(_searchQuery) ||
                        b.boatClass.toLowerCase().contains(_searchQuery))
                    .toList();
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
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: classCtrl.text.isNotEmpty ? classCtrl.text : null,
                        decoration: const InputDecoration(
                          labelText: 'Class / Fleet',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Shields', child: Text('Shields')),
                          DropdownMenuItem(value: 'Santana 22', child: Text('Santana 22')),
                          DropdownMenuItem(value: 'PHRF A', child: Text('PHRF A')),
                          DropdownMenuItem(value: 'PHRF B', child: Text('PHRF B')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (v) => classCtrl.text = v ?? '',
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
