import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/timing_models.dart';
import '../timing_providers.dart';

enum HandicapSystem { timeOnTime, timeOnDistance }

class TimingResultsScreen extends ConsumerStatefulWidget {
  const TimingResultsScreen({super.key, required this.raceStartId});

  final String raceStartId;

  @override
  ConsumerState<TimingResultsScreen> createState() =>
      _TimingResultsScreenState();
}

class _TimingResultsScreenState extends ConsumerState<TimingResultsScreen> {
  HandicapSystem _system = HandicapSystem.timeOnTime;
  double _courseDistance = 3.0; // nautical miles, for time-on-distance

  @override
  Widget build(BuildContext context) {
    final finishesAsync =
        ref.watch(finishRecordsProvider(widget.raceStartId));
    final ratingsAsync = ref.watch(handicapRatingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Race Results'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'csv') _exportCsv();
              if (v == 'clipboard') _copyToClipboard();
              if (v == 'publish') _publishResults();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'publish', child: Text('Publish Results')),
              PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              PopupMenuItem(value: 'clipboard', child: Text('Copy to Clipboard')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Handicap system toggle
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Time-on-Time'),
                  selected: _system == HandicapSystem.timeOnTime,
                  onSelected: (_) =>
                      setState(() => _system = HandicapSystem.timeOnTime),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Time-on-Distance'),
                  selected: _system == HandicapSystem.timeOnDistance,
                  onSelected: (_) =>
                      setState(() => _system = HandicapSystem.timeOnDistance),
                ),
                if (_system == HandicapSystem.timeOnDistance) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'NM',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final d = double.tryParse(v);
                        if (d != null) setState(() => _courseDistance = d);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Results table
          Expanded(
            child: finishesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (finishes) {
                final ratings = ratingsAsync.value ?? [];
                final results =
                    _calculateResults(finishes, ratings);

                if (results.isEmpty) {
                  return const Center(child: Text('No finishes recorded.'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Pos')),
                        DataColumn(label: Text('Sail #')),
                        DataColumn(label: Text('Class')),
                        DataColumn(label: Text('Elapsed')),
                        DataColumn(label: Text('Corrected')),
                        DataColumn(label: Text('Points')),
                      ],
                      rows: results.map((r) {
                        final elapsedStr = r.letterScore == LetterScore.finished
                            ? _formatDuration(r.elapsedSeconds)
                            : r.letterScore.name.toUpperCase();
                        final correctedStr =
                            r.correctedSeconds != null && r.letterScore == LetterScore.finished
                                ? _formatDuration(r.correctedSeconds!)
                                : '—';
                        return DataRow(cells: [
                          DataCell(Text('${r.position}')),
                          DataCell(Text(r.sailNumber)),
                          DataCell(Text(r.boatClass)),
                          DataCell(Text(elapsedStr)),
                          DataCell(Text(correctedStr)),
                          DataCell(Text('${r.points}')),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_ResultRow> _calculateResults(
    List<FinishRecord> finishes,
    List<HandicapRating> ratings,
  ) {
    final ratingMap = {for (final r in ratings) r.sailNumber: r};
    final rows = <_ResultRow>[];

    for (final f in finishes) {
      final rating = ratingMap[f.sailNumber];
      final phrfRating = rating?.phrfRating ?? 0;
      final boatClass = rating?.boatClass ?? '';

      double? corrected;
      if (f.letterScore == LetterScore.finished && f.elapsedSeconds > 0) {
        if (_system == HandicapSystem.timeOnTime && phrfRating > 0) {
          // PHRF Time-on-Time: corrected = elapsed × (650 / (550 + rating))
          corrected = f.elapsedSeconds * (650.0 / (550.0 + phrfRating));
        } else if (_system == HandicapSystem.timeOnDistance &&
            phrfRating > 0) {
          // PHRF Time-on-Distance: corrected = elapsed - (rating × distance)
          corrected = f.elapsedSeconds - (phrfRating * _courseDistance);
        }
      }

      rows.add(_ResultRow(
        sailNumber: f.sailNumber,
        boatClass: boatClass,
        elapsedSeconds: f.elapsedSeconds,
        correctedSeconds: corrected,
        letterScore: f.letterScore,
        position: f.position,
        points: 0,
        finishRecord: f,
      ));
    }

    // Sort by corrected time (finished boats first, then letter scores)
    rows.sort((a, b) {
      if (a.letterScore == LetterScore.finished &&
          b.letterScore != LetterScore.finished) return -1;
      if (a.letterScore != LetterScore.finished &&
          b.letterScore == LetterScore.finished) return 1;
      if (a.letterScore == LetterScore.finished &&
          b.letterScore == LetterScore.finished) {
        final aCorrected = a.correctedSeconds ?? a.elapsedSeconds;
        final bCorrected = b.correctedSeconds ?? b.elapsedSeconds;
        return aCorrected.compareTo(bCorrected);
      }
      return 0;
    });

    // Assign positions and points
    final totalBoats = rows.length;
    for (int i = 0; i < rows.length; i++) {
      if (rows[i].letterScore == LetterScore.finished) {
        rows[i] = rows[i].copyWith(position: i + 1, points: i + 1);
      } else {
        rows[i] = rows[i].copyWith(
          position: 0,
          points: totalBoats + 1,
        );
      }
    }

    return rows;
  }

  String _formatDuration(double seconds) {
    final dur = Duration(seconds: seconds.toInt());
    final h = dur.inHours;
    final m = dur.inMinutes % 60;
    final s = dur.inSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _publishResults() async {
    final finishes =
        ref.read(finishRecordsProvider(widget.raceStartId)).value ?? [];
    final ratings = ref.read(handicapRatingsProvider).value ?? [];
    final results = _calculateResults(finishes, ratings);

    final updatedRecords = results.map((r) {
      return r.finishRecord.copyWith(
        correctedSeconds: r.correctedSeconds,
        position: r.position,
      );
    }).toList();

    await ref
        .read(timingRepositoryProvider)
        .publishResults(widget.raceStartId, updatedRecords);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Results published!')),
      );
    }
  }

  void _exportCsv() {
    final finishes =
        ref.read(finishRecordsProvider(widget.raceStartId)).value ?? [];
    final ratings = ref.read(handicapRatingsProvider).value ?? [];
    final results = _calculateResults(finishes, ratings);

    final buffer = StringBuffer();
    buffer.writeln('Position,Sail #,Class,Elapsed,Corrected,Points');
    for (final r in results) {
      final elapsed = r.letterScore == LetterScore.finished
          ? _formatDuration(r.elapsedSeconds)
          : r.letterScore.name.toUpperCase();
      final corrected = r.correctedSeconds != null
          ? _formatDuration(r.correctedSeconds!)
          : '';
      buffer.writeln(
          '${r.position},${r.sailNumber},${r.boatClass},$elapsed,$corrected,${r.points}');
    }

    final uri =
        Uri.dataFromString(buffer.toString(), mimeType: 'text/csv', encoding: utf8);
    launchUrl(uri);
  }

  void _copyToClipboard() {
    final finishes =
        ref.read(finishRecordsProvider(widget.raceStartId)).value ?? [];
    final ratings = ref.read(handicapRatingsProvider).value ?? [];
    final results = _calculateResults(finishes, ratings);

    final buffer = StringBuffer();
    buffer.writeln('Pos\tSail #\tClass\tElapsed\tCorrected\tPoints');
    for (final r in results) {
      final elapsed = r.letterScore == LetterScore.finished
          ? _formatDuration(r.elapsedSeconds)
          : r.letterScore.name.toUpperCase();
      final corrected = r.correctedSeconds != null
          ? _formatDuration(r.correctedSeconds!)
          : '';
      buffer.writeln(
          '${r.position}\t${r.sailNumber}\t${r.boatClass}\t$elapsed\t$corrected\t${r.points}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Results copied to clipboard')),
    );
  }
}

class _ResultRow {
  const _ResultRow({
    required this.sailNumber,
    required this.boatClass,
    required this.elapsedSeconds,
    this.correctedSeconds,
    required this.letterScore,
    required this.position,
    required this.points,
    required this.finishRecord,
  });

  final String sailNumber;
  final String boatClass;
  final double elapsedSeconds;
  final double? correctedSeconds;
  final LetterScore letterScore;
  final int position;
  final int points;
  final FinishRecord finishRecord;

  _ResultRow copyWith({
    int? position,
    int? points,
    double? correctedSeconds,
  }) {
    return _ResultRow(
      sailNumber: sailNumber,
      boatClass: boatClass,
      elapsedSeconds: elapsedSeconds,
      correctedSeconds: correctedSeconds ?? this.correctedSeconds,
      letterScore: letterScore,
      position: position ?? this.position,
      points: points ?? this.points,
      finishRecord: finishRecord,
    );
  }
}
