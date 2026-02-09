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
          padding: const EdgeInsets.all(12),
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
        Expanded(
          child: fleetAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (boats) {
              var filtered = boats;
              if (_searchQuery.isNotEmpty) {
                filtered = boats
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing != null ? 'Edit Boat' : 'Add Boat'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sailCtrl,
                decoration: const InputDecoration(labelText: 'Sail Number'),
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Boat Name'),
              ),
              TextField(
                controller: ownerCtrl,
                decoration:
                    const InputDecoration(labelText: 'Owner/Skipper'),
              ),
              TextField(
                controller: classCtrl,
                decoration: const InputDecoration(labelText: 'Class'),
              ),
              TextField(
                controller: phrfCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'PHRF Rating'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
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
              );
              await ref
                  .read(boatCheckinRepositoryProvider)
                  .saveBoat(boat);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBoat(Boat boat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Boat?'),
        content: Text('Remove ${boat.boatName} (${boat.sailNumber})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(boatCheckinRepositoryProvider).deleteBoat(boat.id);
  }
}
