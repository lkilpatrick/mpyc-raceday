enum BroadcastType {
  courseSelection,
  postponement,
  abandonment,
  courseChange,
  generalRecall,
  shortenedCourse,
  cancellation,
  general,
  vhfChannelChange,
  shortenCourse,
  abandonTooMuchWind,
  abandonTooLittleWind,
}

/// Who should receive the broadcast.
enum BroadcastTarget {
  everyone,
  skippersOnly,
  onshore,
}

class FleetBroadcast {
  const FleetBroadcast({
    required this.id,
    required this.eventId,
    required this.sentBy,
    required this.message,
    required this.type,
    required this.sentAt,
    required this.deliveryCount,
    this.target = BroadcastTarget.everyone,
    this.requiresAck = false,
    this.ackCount = 0,
  });

  final String id;
  final String eventId;
  final String sentBy;
  final String message;
  final BroadcastType type;
  final DateTime sentAt;
  final int deliveryCount;
  final BroadcastTarget target;
  final bool requiresAck;
  final int ackCount;
}
