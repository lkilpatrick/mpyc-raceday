import 'package:freezed_annotation/freezed_annotation.dart';

part 'season_series.freezed.dart';
part 'season_series.g.dart';

@freezed
abstract class SeasonSeries with _$SeasonSeries {
  const factory SeasonSeries({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required int dayOfWeek,
    required String color,
    required bool isActive,
  }) = _SeasonSeries;

  factory SeasonSeries.fromJson(Map<String, dynamic> json) =>
      _$SeasonSeriesFromJson(json);
}
