import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/boat.dart';
import '../../data/models/boat_checkin.dart';
import '../boat_checkin_providers.dart';

class EventCheckinPage extends ConsumerStatefulWidget {
  const EventCheckinPage({super.key});

  @override
  ConsumerState<EventCheckinPage> createState() => _EventCheckinPageState();
}

class _EventCheckinPageState extends ConsumerState<EventCheckinPage> {
  String _eventId = '';
  final _eventIdCtrl = TextEditingController();

  @override
  void dispose() {
    _eventIdCtrl.dispose();
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
              Text('Event Check-Ins',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _eventIdCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter Event ID...',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () =>
                          setState(() => _eventId = _eventIdCtrl.text.trim()),
                    ),
                  ),
                  onSubmitted: (v) =>
                      setState(() => _eventId = v.trim()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_eventId.isEmpty)
          const Expanded(
            child: Center(
              child: Text('Enter an event ID to view check-ins'),
            ),
          )
        else
          Expanded(child: _EventCheckinTable(eventId: _eventId)),
      ],
    );
  }
}

class _EventCheckinTable extends ConsumerWidget {
  const _EventCheckinTable({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(eventCheckinsProvider(eventId));
    final closedAsync = ref.watch(checkinsClosedProvider(eventId));
    final isClosed = closedAsync.valueOrNull ?? false;

    return checkinsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (checkins) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('${checkins.length} boats checked in',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  if (isClosed) ...[
                    const SizedBox(width: 8),
                    const Chip(
                      label: Text('CLOSED',
                          style: TextStyle(fontSize: 10, color: Colors.white)),
                      backgroundColor: Colors.red,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                  const Spacer(),
                  if (!isClosed)
                    OutlinedButton.icon(
                      onPressed: () => _lateCheckin(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Late Check-In'),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _exportStartList(context, checkins),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export Start List'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Sail #')),
                      DataColumn(label: Text('Boat Name')),
                      DataColumn(label: Text('Skipper')),
                      DataColumn(label: Text('Class')),
                      DataColumn(label: Text('Crew')),
                      DataColumn(label: Text('PHRF')),
                      DataColumn(label: Text('Time')),
                      DataColumn(label: Text('Safety')),
                    ],
                    rows: checkins.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      return DataRow(cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(Text(c.sailNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold))),
                        DataCell(Text(c.boatName)),
                        DataCell(Text(c.skipperName)),
                        DataCell(Text(c.boatClass)),
                        DataCell(Text('${c.crewCount}')),
                        DataCell(Text(c.phrfRating?.toString() ?? '—')),
                        DataCell(
                            Text(DateFormat.Hm().format(c.checkedInAt))),
                        DataCell(c.safetyEquipmentVerified
                            ? const Icon(Icons.verified_user,
                                color: Colors.green, size: 18)
                            : const Icon(Icons.warning,
                                color: Colors.orange, size: 18)),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _lateCheckin(BuildContext context, WidgetRef ref) {
    final sailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final skipperCtrl = TextEditingController();
    final classCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Late Check-In'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: sailCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Sail Number')),
              TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Boat Name')),
              TextField(
                  controller: skipperCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Skipper')),
              TextField(
                  controller: classCtrl,
                  decoration: const InputDecoration(labelText: 'Class')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final checkin = BoatCheckin(
                id: '',
                eventId: eventId,
                boatId: '',
                sailNumber: sailCtrl.text.trim(),
                boatName: nameCtrl.text.trim(),
                skipperName: skipperCtrl.text.trim(),
                boatClass: classCtrl.text.trim(),
                checkedInAt: DateTime.now(),
                checkedInBy: 'admin_late',
                crewCount: 1,
                safetyEquipmentVerified: false,
                notes: 'Late check-in via web admin',
              );
              await ref
                  .read(boatCheckinRepositoryProvider)
                  .checkInBoat(checkin);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Check In'),
          ),
        ],
      ),
    );
  }

  void _exportStartList(BuildContext context, List<BoatCheckin> checkins) {
    final csv = StringBuffer();
    csv.writeln('Sail #,Boat Name,Skipper,Class,PHRF,Crew,Time,Safety');
    for (final c in checkins) {
      csv.writeln(
          '${c.sailNumber},${c.boatName},${c.skipperName},${c.boatClass},${c.phrfRating ?? ""},${c.crewCount},${DateFormat.Hm().format(c.checkedInAt)},${c.safetyEquipmentVerified ? "Yes" : "No"}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Start list exported (${checkins.length} boats)'),
        action: SnackBarAction(label: 'Copy', onPressed: () {}),
      ),
    );
  }
}
