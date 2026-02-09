class SyncResult {
  const SyncResult({
    required this.newCount,
    required this.updatedCount,
    required this.unchangedCount,
    required this.errors,
    required this.startedAt,
    required this.finishedAt,
  });

  final int newCount;
  final int updatedCount;
  final int unchangedCount;
  final List<String> errors;
  final DateTime startedAt;
  final DateTime finishedAt;

  int get totalProcessed => newCount + updatedCount + unchangedCount;
  bool get hasErrors => errors.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'newCount': newCount,
    'updatedCount': updatedCount,
    'unchangedCount': unchangedCount,
    'errors': errors,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'totalProcessed': totalProcessed,
  };
}
