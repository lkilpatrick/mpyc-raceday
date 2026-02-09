enum LetterScore { dns, dnf, dsq, ocs, raf, ret, finished }

class RaceStart {
  const RaceStart({
    required this.id,
    required this.eventId,
    required this.raceNumber,
    required this.className,
    this.warningSignalTime,
    this.prepSignalTime,
    this.startTime,
    this.isGeneralRecall = false,
    this.isPostponed = false,
    this.notes = '',
  });

  final String id;
  final String eventId;
  final int raceNumber;
  final String className;
  final DateTime? warningSignalTime;
  final DateTime? prepSignalTime;
  final DateTime? startTime;
  final bool isGeneralRecall;
  final bool isPostponed;
  final String notes;

  RaceStart copyWith({
    String? id,
    String? eventId,
    int? raceNumber,
    String? className,
    DateTime? warningSignalTime,
    DateTime? prepSignalTime,
    DateTime? startTime,
    bool? isGeneralRecall,
    bool? isPostponed,
    String? notes,
  }) {
    return RaceStart(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      raceNumber: raceNumber ?? this.raceNumber,
      className: className ?? this.className,
      warningSignalTime: warningSignalTime ?? this.warningSignalTime,
      prepSignalTime: prepSignalTime ?? this.prepSignalTime,
      startTime: startTime ?? this.startTime,
      isGeneralRecall: isGeneralRecall ?? this.isGeneralRecall,
      isPostponed: isPostponed ?? this.isPostponed,
      notes: notes ?? this.notes,
    );
  }
}

class FinishRecord {
  const FinishRecord({
    required this.id,
    required this.raceStartId,
    this.boatCheckinId,
    required this.sailNumber,
    this.boatName = '',
    required this.finishTimestamp,
    required this.elapsedSeconds,
    this.correctedSeconds,
    this.letterScore = LetterScore.finished,
    this.position = 0,
    this.adjustmentNote,
  });

  final String id;
  final String raceStartId;
  final String? boatCheckinId;
  final String sailNumber;
  final String boatName;
  final DateTime finishTimestamp;
  final double elapsedSeconds;
  final double? correctedSeconds;
  final LetterScore letterScore;
  final int position;
  final String? adjustmentNote;

  FinishRecord copyWith({
    String? id,
    String? raceStartId,
    String? boatCheckinId,
    String? sailNumber,
    String? boatName,
    DateTime? finishTimestamp,
    double? elapsedSeconds,
    double? correctedSeconds,
    LetterScore? letterScore,
    int? position,
    String? adjustmentNote,
  }) {
    return FinishRecord(
      id: id ?? this.id,
      raceStartId: raceStartId ?? this.raceStartId,
      boatCheckinId: boatCheckinId ?? this.boatCheckinId,
      sailNumber: sailNumber ?? this.sailNumber,
      boatName: boatName ?? this.boatName,
      finishTimestamp: finishTimestamp ?? this.finishTimestamp,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      correctedSeconds: correctedSeconds ?? this.correctedSeconds,
      letterScore: letterScore ?? this.letterScore,
      position: position ?? this.position,
      adjustmentNote: adjustmentNote ?? this.adjustmentNote,
    );
  }
}

class HandicapRating {
  const HandicapRating({
    required this.sailNumber,
    required this.phrfRating,
    this.boatClass = '',
  });

  final String sailNumber;
  final int phrfRating;
  final String boatClass;
}
