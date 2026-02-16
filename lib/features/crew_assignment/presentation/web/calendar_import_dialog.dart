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
    'Title': 'Title',
    'Start Date': 'Start Date',
    'Start Time': 'Start Time',
    'Description': 'Description',
    'Location': 'Location',
    'Contact': 'Contact',
    'Extra Info': 'Extra Info',
    'RC Fleet': 'RC Fleet',
    'Race Committee': 'Race Committee',
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
                controlsBuilder: (context, details) => const SizedBox.shrink(),
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
            // ignore: deprecated_member_use
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

  /// Parse a CSV line respecting quoted fields (e.g. "Sunday, March 08, 2026")
  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        // Handle escaped quotes ""
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        fields.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    }
    fields.add(current.toString().trim());
    return fields;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    final text = utf8.decode(file.bytes!);
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return;

    // Find the header row (contains "Title" and "Start Date")
    var headerIdx = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains('Title') && lines[i].contains('Start Date')) {
        headerIdx = i;
        break;
      }
    }

    final headers = _parseCsvLine(lines[headerIdx]);
    final rows = <Map<String, String>>[];

    for (final line in lines.skip(headerIdx + 1)) {
      final parts = _parseCsvLine(line);
      // Skip filler rows (month headers, empty rows)
      if (parts.every((p) => p.isEmpty)) continue;
      final row = <String, String>{};
      for (var i = 0; i < headers.length && i < parts.length; i++) {
        row[headers[i]] = parts[i];
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
    final errors = <String>[];
    final seen = <String>{};
    var validCount = 0;

    for (final row in _mappedRows()) {
      final eventName = (row['Title'] ?? '').trim();
      final dateRaw = (row['Start Date'] ?? '').trim();

      // Skip filler rows
      if (eventName.isEmpty && dateRaw.isEmpty) continue;
      if (eventName.isEmpty || dateRaw.isEmpty) {
        if (eventName.isNotEmpty && !RegExp(r'^[A-Z]+$').hasMatch(eventName)) {
          errors.add('Missing date for: $eventName');
        }
        continue;
      }

      // Skip revision header
      if (eventName.toLowerCase().startsWith('revision')) continue;

      final key = '$eventName-$dateRaw';
      if (seen.contains(key)) {
        errors.add('Duplicate: $eventName ($dateRaw)');
      }
      seen.add(key);
      validCount++;
    }

    if (validCount == 0) {
      errors.insert(0, 'No valid events found in the CSV.');
    } else {
      errors.insert(0, '$validCount events ready to import.');
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
