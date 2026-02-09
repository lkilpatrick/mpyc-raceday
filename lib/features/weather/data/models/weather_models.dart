enum WeatherSource { noaa, openWeather, manual, merged }

enum SeaState { calm, smooth, slight, moderate, rough, veryRough, high }

enum WeatherEntryTag { routine, preRace, raceStart, raceFinish, postRace, alert }

class WeatherEntry {
  const WeatherEntry({
    required this.id,
    required this.eventId,
    required this.timestamp,
    required this.source,
    this.tag = WeatherEntryTag.routine,
    this.windSpeedKts = 0,
    this.windGustKts,
    this.windDirectionDeg = 0,
    this.windDirectionLabel = '',
    this.temperatureF,
    this.humidity,
    this.pressureMb,
    this.visibility,
    this.seaState,
    this.forecastSummary,
    this.notes = '',
    this.loggedBy,
  });

  final String id;
  final String eventId;
  final DateTime timestamp;
  final WeatherSource source;
  final WeatherEntryTag tag;
  final double windSpeedKts;
  final double? windGustKts;
  final double windDirectionDeg;
  final String windDirectionLabel;
  final double? temperatureF;
  final double? humidity;
  final double? pressureMb;
  final String? visibility;
  final SeaState? seaState;
  final String? forecastSummary;
  final String notes;
  final String? loggedBy;

  WeatherEntry copyWith({
    String? id,
    String? eventId,
    DateTime? timestamp,
    WeatherSource? source,
    WeatherEntryTag? tag,
    double? windSpeedKts,
    double? windGustKts,
    double? windDirectionDeg,
    String? windDirectionLabel,
    double? temperatureF,
    double? humidity,
    double? pressureMb,
    String? visibility,
    SeaState? seaState,
    String? forecastSummary,
    String? notes,
    String? loggedBy,
  }) {
    return WeatherEntry(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      tag: tag ?? this.tag,
      windSpeedKts: windSpeedKts ?? this.windSpeedKts,
      windGustKts: windGustKts ?? this.windGustKts,
      windDirectionDeg: windDirectionDeg ?? this.windDirectionDeg,
      windDirectionLabel: windDirectionLabel ?? this.windDirectionLabel,
      temperatureF: temperatureF ?? this.temperatureF,
      humidity: humidity ?? this.humidity,
      pressureMb: pressureMb ?? this.pressureMb,
      visibility: visibility ?? this.visibility,
      seaState: seaState ?? this.seaState,
      forecastSummary: forecastSummary ?? this.forecastSummary,
      notes: notes ?? this.notes,
      loggedBy: loggedBy ?? this.loggedBy,
    );
  }
}

class MarineForecast {
  const MarineForecast({
    required this.periods,
    this.hazards = const [],
  });

  final List<ForecastPeriod> periods;
  final List<String> hazards;
}

class ForecastPeriod {
  const ForecastPeriod({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.windSpeed,
    required this.windDirection,
    required this.shortForecast,
    this.detailedForecast = '',
    this.seaState,
  });

  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final String windSpeed;
  final String windDirection;
  final String shortForecast;
  final String detailedForecast;
  final String? seaState;
}

class WeatherAlertConfig {
  const WeatherAlertConfig({
    this.highWindKts = 30,
    this.gustAlertKts = 35,
    this.lightningRadiusMiles = 10,
    this.rapidWindShiftDeg = 30,
    this.rapidWindShiftMinutes = 15,
  });

  final double highWindKts;
  final double gustAlertKts;
  final double lightningRadiusMiles;
  final double rapidWindShiftDeg;
  final int rapidWindShiftMinutes;
}
