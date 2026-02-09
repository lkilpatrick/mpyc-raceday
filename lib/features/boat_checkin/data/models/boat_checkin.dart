import 'package:freezed_annotation/freezed_annotation.dart';

part 'boat_checkin.freezed.dart';
part 'boat_checkin.g.dart';

@freezed
abstract class BoatCheckin with _$BoatCheckin {
  const factory BoatCheckin({
    required String id,
    required String eventId,
    required String sailNumber,
    required String boatName,
    required String skipperName,
    required String boatClass,
    required DateTime checkedInAt,
    required String checkedInBy,
    required int crewCount,
    required List<String> crewNames,
    required bool safetyEquipmentVerified,
    int? phrfRating,
  }) = _BoatCheckin;

  factory BoatCheckin.fromJson(Map<String, dynamic> json) =>
      _$BoatCheckinFromJson(json);
}
