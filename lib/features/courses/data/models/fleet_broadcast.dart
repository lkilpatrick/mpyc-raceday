enum BroadcastType {
  courseSelection,
  postponement,
  abandonment,
  courseChange,
  generalRecall,
  shortenedCourse,
  cancellation,
  general,
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
  });

  final String id;
  final String eventId;
  final String sentBy;
  final String message;
  final BroadcastType type;
  final DateTime sentAt;
  final int deliveryCount;
}
