import 'package:freezed_annotation/freezed_annotation.dart';

part 'fleet_broadcast.freezed.dart';
part 'fleet_broadcast.g.dart';

enum BroadcastType {
  courseSelection,
  postponement,
  abandonment,
  courseChange,
  general,
}

@freezed
class FleetBroadcast with _$FleetBroadcast {
  const factory FleetBroadcast({
    required String id,
    required String eventId,
    required String sentBy,
    required String message,
    required BroadcastType type,
    required DateTime sentAt,
    required int deliveryCount,
  }) = _FleetBroadcast;

  factory FleetBroadcast.fromJson(Map<String, dynamic> json) =>
      _$FleetBroadcastFromJson(json);
}
