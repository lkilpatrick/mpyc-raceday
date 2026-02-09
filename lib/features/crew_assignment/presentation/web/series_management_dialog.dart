import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/crew_assignment_repository.dart';
import '../crew_assignment_providers.dart';

class SeriesManagementDialog extends ConsumerStatefulWidget {
  const SeriesManagementDialog({super.key});

  @override
  ConsumerState<SeriesManagementDialog> createState() =>
      _SeriesManagementDialogState();
}

class _SeriesManagementDialogState
    extends ConsumerState<SeriesManagementDialog> {
  final _nameController = TextEditingController();
  DateTimeRange? _range;
  int? _weekday;
  Color _color = Colors.blue;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(seriesProvider);

    return Dialog(
      child: SizedBox(
        width: 720,
        height: 520,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Series Management',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: seriesAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e')),
                          data: (series) => ListView(
                            children: series
                                .map(
                                  (s) => ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: s.color,
                                    ),
                                    title: Text(s.name),
                                    subtitle: Text(
                                      '${s.startDate.month}/${s.startDate.day} - ${s.endDate.month}/${s.endDate.day}',
                                    ),
                                    trailing: Text(
                                      s.recurringWeekday?.toString() ??
                                          'One-off',
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _nameController.text = s.name;
                                        _range = DateTimeRange(
                                          start: s.startDate,
                                          end: s.endDate,
                                        );
                                        _weekday = s.recurringWeekday;
                                        _color = s.color;
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Series Name',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Color:'),
                                  const SizedBox(width: 8),
                                  ...[
                                    Colors.blue,
                                    Colors.orange,
                                    Colors.green,
                                    Colors.purple,
                                    Colors.red,
                                  ].map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: InkWell(
                                        onTap: () => setState(() => _color = c),
                                        child: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: c,
                                          child: _color == c
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: _pickRange,
                                child: Text(
                                  _range == null
                                      ? 'Pick date range'
                                      : '${_range!.start.month}/${_range!.start.day} - ${_range!.end.month}/${_range!.end.day}',
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int?>(
                                value: _weekday,
                                decoration: const InputDecoration(
                                  labelText: 'Recurring day',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text('None'),
                                  ),
                                  DropdownMenuItem(
                                    value: DateTime.monday,
                                    child: Text('Monday'),
                                  ),
                                  DropdownMenuItem(
                                    value: DateTime.tuesday,
                                    child: Text('Tuesday'),
                                  ),
                                  DropdownMenuItem(
                                    value: DateTime.wednesday,
                                    child: Text('Wednesday'),
                                  ),
                                  DropdownMenuItem(
                                    value: DateTime.thursday,
                                    child: Text('Thursday'),
                                  ),
                                  DropdownMenuItem(
                                    value: DateTime.friday,
                                    child: Text('Friday'),
                                  ),
                                  DropdownMenuItem(
                                    value: DateTime.saturday,
                                    child: Text('Saturday'),
                                  ),
                                  DropdownMenuItem(
                                    value: DateTime.sunday,
                                    child: Text('Sunday'),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _weekday = value),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: _saveSeries,
                                    child: const Text('Save Series'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonal(
                                    onPressed: _bulkGenerate,
                                    child: const Text('Bulk-generate events'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _range,
    );
    if (range != null) {
      setState(() => _range = range);
    }
  }

  Future<void> _saveSeries() async {
    if (_nameController.text.trim().isEmpty || _range == null) return;
    final repo = ref.read(crewAssignmentRepositoryProvider);
    final id = _nameController.text.trim().toLowerCase().replaceAll(' ', '_');
    await repo.saveSeries(
      SeriesDefinition(
        id: id,
        name: _nameController.text.trim(),
        color: _color,
        startDate: _range!.start,
        endDate: _range!.end,
        recurringWeekday: _weekday,
      ),
    );
  }

  Future<void> _bulkGenerate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final id = name.toLowerCase().replaceAll(' ', '_');
    await ref.read(crewAssignmentRepositoryProvider).generateSeriesEvents(id);
  }
}
