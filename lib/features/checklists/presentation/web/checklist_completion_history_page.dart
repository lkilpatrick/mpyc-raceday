import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/checklist.dart';
import '../checklist_providers.dart';

class ChecklistCompletionHistoryPage extends ConsumerStatefulWidget {
  const ChecklistCompletionHistoryPage({super.key});

  @override
  ConsumerState<ChecklistCompletionHistoryPage> createState() =>
      _ChecklistCompletionHistoryPageState();
}

class _ChecklistCompletionHistoryPageState
    extends ConsumerState<ChecklistCompletionHistoryPage> {
  String _checklistFilter = 'All';
  DateTimeRange? _dateRange;
  String _crewFilter = '';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(allCompletionHistoryProvider);
    final templatesAsync = ref.watch(checklistTemplatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DropdownButton<String>(
              value: _checklistFilter,
              items: [
                const DropdownMenuItem(value: 'All', child: Text('All Checklists')),
                ...templatesAsync.whenOrNull(
                      data: (templates) => templates.map(
                        (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                      ),
                    ) ??
                    [],
              ],
              onChanged: (v) => setState(() => _checklistFilter = v ?? 'All'),
            ),
            OutlinedButton(
              onPressed: _pickDateRange,
              child: Text(
                _dateRange == null
                    ? 'Date range'
                    : '${DateFormat.Md().format(_dateRange!.start)} - ${DateFormat.Md().format(_dateRange!.end)}',
              ),
            ),
            SizedBox(
              width: 200,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Crew member',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _crewFilter = v.trim()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (completions) {
              final templates = templatesAsync.valueOrNull ?? [];
              final filtered = completions.where((c) {
                if (_checklistFilter != 'All' &&
                    c.checklistId != _checklistFilter) {
                  return false;
                }
                if (_dateRange != null) {
                  if (c.startedAt.isBefore(_dateRange!.start) ||
                      c.startedAt.isAfter(
                          _dateRange!.end.add(const Duration(days: 1)))) {
                    return false;
                  }
                }
                if (_crewFilter.isNotEmpty &&
                    !c.completedBy
                        .toLowerCase()
                        .contains(_crewFilter.toLowerCase())) {
                  return false;
                }
                return true;
              }).toList();

              return DataTable2(
                columns: const [
                  DataColumn2(label: Text('Date')),
                  DataColumn2(label: Text('Event')),
                  DataColumn2(size: ColumnSize.L, label: Text('Checklist')),
                  DataColumn2(label: Text('Completed By')),
                  DataColumn2(label: Text('Signed Off By')),
                  DataColumn2(label: Text('Duration')),
                  DataColumn2(label: Text('Status')),
                ],
                rows: filtered.map((c) {
                  final template = templates
                      .where((t) => t.id == c.checklistId)
                      .firstOrNull;
                  final duration = c.completedAt != null
                      ? c.completedAt!.difference(c.startedAt)
                      : null;
                  final statusLabel = switch (c.status) {
                    ChecklistCompletionStatus.inProgress => 'In Progress',
                    ChecklistCompletionStatus.completedPendingSignoff =>
                      'Pending Sign-Off',
                    ChecklistCompletionStatus.signedOff => 'Signed Off',
                  };

                  return DataRow2(
                    onTap: () => _showDetail(c, template),
                    cells: [
                      DataCell(
                          Text(DateFormat.yMMMd().format(c.startedAt))),
                      DataCell(Text(c.eventId)),
                      DataCell(Text(template?.name ?? c.checklistId)),
                      DataCell(Text(c.completedBy)),
                      DataCell(Text(c.signOffBy ?? '—')),
                      DataCell(Text(duration != null
                          ? '${duration.inMinutes}m'
                          : '—')),
                      DataCell(Text(statusLabel)),
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (range != null) setState(() => _dateRange = range);
  }

  void _showDetail(ChecklistCompletion c, Checklist? template) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 700,
          height: 600,
          child: _CompletionDetailView(completion: c, template: template),
        ),
      ),
    );
  }
}

class _CompletionDetailView extends StatelessWidget {
  const _CompletionDetailView({required this.completion, this.template});

  final ChecklistCompletion completion;
  final Checklist? template;

  @override
  Widget build(BuildContext context) {
    final categories = <String, List<ChecklistItem>>{};
    for (final item in template?.items ?? <ChecklistItem>[]) {
      categories.putIfAbsent(item.category, () => []).add(item);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  template?.name ?? 'Checklist',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            '${DateFormat.yMMMd().add_jm().format(completion.startedAt)} • ${completion.completedBy}',
          ),
          if (completion.signOffBy != null)
            Text('Signed off by: ${completion.signOffBy}'),
          const Divider(height: 16),
          Expanded(
            child: ListView(
              children: categories.entries.expand((entry) {
                return [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ...entry.value.map((templateItem) {
                    final completed = completion.items
                        .where((i) => i.itemId == templateItem.id)
                        .firstOrNull;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        (completed?.checked ?? false)
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: (completed?.checked ?? false)
                            ? Colors.green
                            : Colors.grey,
                      ),
                      title: Text(templateItem.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (completed?.note?.isNotEmpty ?? false)
                            Text('Note: ${completed!.note}'),
                          if (completed?.photoUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Image.network(
                                completed!.photoUrl!,
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ];
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
