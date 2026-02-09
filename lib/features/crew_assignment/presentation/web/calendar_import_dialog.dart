import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/crew_assignment_repository.dart';
import '../crew_assignment_providers.dart';

class CalendarImportDialog extends ConsumerStatefulWidget {
  const CalendarImportDialog({super.key});

  @override
  ConsumerState<CalendarImportDialog> createState() =>
      _CalendarImportDialogState();
}

class _CalendarImportDialogState extends ConsumerState<CalendarImportDialog> {
  int _step = 0;
  List<Map<String, String>> _rows = [];
  final Map<String, String> _mapping = {
    'Event Name': 'Event Name',
    'Date': 'Date',
    'Series': 'Series',
    'Start Time': 'Start Time',
    'PRO': 'PRO',
    'Signal Boat': 'Signal Boat',
    'Mark Boat': 'Mark Boat',
    'Safety': 'Safety',
    'Notes': 'Notes',
  };
  List<String> _headers = [];
  List<String> _validationErrors = [];
  CalendarImportResult? _result;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 860,
        height: 620,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import Calendar',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Stepper(
                currentStep: _step,
                controlsBuilder: (_, __) => const SizedBox.shrink(),
                steps: [
                  Step(
                    title: const Text('Upload'),
                    content: _buildUploadStep(),
                  ),
                  Step(
                    title: const Text('Column Mapping'),
                    content: _buildMappingStep(),
                  ),
                  Step(
                    title: const Text('Validation Preview'),
                    content: _buildValidationStep(),
                  ),
                  Step(
                    title: const Text('Confirm & Import'),
                    content: _buildConfirmStep(),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  if (_step > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Back'),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_step == 3 ? 'Run Import' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.attach_file),
          label: const Text('Choose .xlsx or .csv'),
        ),
        const SizedBox(height: 8),
        Text('Parsed rows: ${_rows.length}'),
        const SizedBox(height: 8),
        if (_rows.isNotEmpty)
          SizedBox(
            height: 140,
            child: ListView(
              children: _rows.take(5).map((r) => Text(r.toString())).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildMappingStep() {
    if (_headers.isEmpty) {
      return const Text('Upload a file first.');
    }

    return Wrap(
      runSpacing: 8,
      spacing: 16,
      children: _mapping.keys.map((target) {
        return SizedBox(
          width: 260,
          child: DropdownButtonFormField<String>(
            value: _mapping[target],
            decoration: InputDecoration(labelText: target),
            items: _headers
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _mapping[target] = v);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildValidationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_validationErrors.isEmpty)
          const Text('No validation issues found.')
        else
          ..._validationErrors.map(
            (e) => Text('• $e', style: const TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    if (_result == null) {
      return const Text(
        'Ready to import and create/update RaceEvent + CrewAssignment records.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Created: ${_result!.created}'),
        Text('Updated: ${_result!.updated}'),
        Text('Skipped: ${_result!.skipped}'),
        if (_result!.errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._result!.errors.map((e) => Text('• $e')),
        ],
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    final ext = file.extension?.toLowerCase();
    if (ext == 'xlsx') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'XLSX upload accepted; using CSV-style parser in this scaffold.',
          ),
        ),
      );
    }

    final text = utf8.decode(file.bytes!);
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return;

    final headers = lines.first.split(',').map((e) => e.trim()).toList();
    final rows = <Map<String, String>>[];

    for (final line in lines.skip(1)) {
      final parts = line.split(',');
      final row = <String, String>{};
      for (var i = 0; i < headers.length && i < parts.length; i++) {
        row[headers[i]] = parts[i].trim();
      }
      rows.add(row);
    }

    setState(() {
      _headers = headers;
      _rows = rows;
      for (final key in _mapping.keys) {
        if (_headers.contains(key)) _mapping[key] = key;
      }
    });
  }

  void _validate() {
    final now = DateTime.now();
    final errors = <String>[];
    final seen = <String>{};

    for (final row in _mappedRows()) {
      final eventName = row['Event Name'] ?? '';
      final dateRaw = row['Date'] ?? '';
      final date = DateTime.tryParse(dateRaw);

      if (date == null) {
        errors.add('Invalid date: $dateRaw ($eventName)');
      } else if (date.isBefore(DateTime(now.year, now.month, now.day))) {
        errors.add('Past date found: $eventName on $dateRaw');
      }

      final key = '$eventName-$dateRaw';
      if (seen.contains(key)) {
        errors.add('Duplicate row: $eventName ($dateRaw)');
      }
      seen.add(key);

      for (final roleCol in ['PRO', 'Signal Boat', 'Mark Boat', 'Safety']) {
        final name = row[roleCol] ?? '';
        if (name.isNotEmpty && name.length < 3) {
          errors.add('Unknown member name in $roleCol: "$name"');
        }
      }
    }

    setState(() => _validationErrors = errors);
  }

  List<Map<String, String>> _mappedRows() {
    return _rows.map((source) {
      final mapped = <String, String>{};
      for (final entry in _mapping.entries) {
        mapped[entry.key] = source[entry.value] ?? '';
      }
      return mapped;
    }).toList();
  }

  Future<void> _next() async {
    if (_step < 3) {
      if (_step == 1) _validate();
      setState(() => _step++);
      return;
    }

    final repo = ref.read(crewAssignmentRepositoryProvider);
    final result = await repo.importCalendar(_mappedRows());
    setState(() => _result = result);
  }
}
