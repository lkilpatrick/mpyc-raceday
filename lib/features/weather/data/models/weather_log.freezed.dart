// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeatherEntry {

 DateTime get timestamp; WeatherSource get source; double get windSpeedKnots; double get windGustKnots; int get windDirectionDegrees; double get temperature; double get humidity; double get pressure; SeaState get seaState; Visibility get visibility; Precipitation get precipitation; String get notes; String get loggedBy;
/// Create a copy of WeatherEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherEntryCopyWith<WeatherEntry> get copyWith => _$WeatherEntryCopyWithImpl<WeatherEntry>(this as WeatherEntry, _$identity);

  /// Serializes this WeatherEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherEntry&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.source, source) || other.source == source)&&(identical(other.windSpeedKnots, windSpeedKnots) || other.windSpeedKnots == windSpeedKnots)&&(identical(other.windGustKnots, windGustKnots) || other.windGustKnots == windGustKnots)&&(identical(other.windDirectionDegrees, windDirectionDegrees) || other.windDirectionDegrees == windDirectionDegrees)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.seaState, seaState) || other.seaState == seaState)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.precipitation, precipitation) || other.precipitation == precipitation)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.loggedBy, loggedBy) || other.loggedBy == loggedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,source,windSpeedKnots,windGustKnots,windDirectionDegrees,temperature,humidity,pressure,seaState,visibility,precipitation,notes,loggedBy);

@override
String toString() {
  return 'WeatherEntry(timestamp: $timestamp, source: $source, windSpeedKnots: $windSpeedKnots, windGustKnots: $windGustKnots, windDirectionDegrees: $windDirectionDegrees, temperature: $temperature, humidity: $humidity, pressure: $pressure, seaState: $seaState, visibility: $visibility, precipitation: $precipitation, notes: $notes, loggedBy: $loggedBy)';
}


}

/// @nodoc
abstract mixin class $WeatherEntryCopyWith<$Res>  {
  factory $WeatherEntryCopyWith(WeatherEntry value, $Res Function(WeatherEntry) _then) = _$WeatherEntryCopyWithImpl;
@useResult
$Res call({
 DateTime timestamp, WeatherSource source, double windSpeedKnots, double windGustKnots, int windDirectionDegrees, double temperature, double humidity, double pressure, SeaState seaState, Visibility visibility, Precipitation precipitation, String notes, String loggedBy
});




}
/// @nodoc
class _$WeatherEntryCopyWithImpl<$Res>
    implements $WeatherEntryCopyWith<$Res> {
  _$WeatherEntryCopyWithImpl(this._self, this._then);

  final WeatherEntry _self;
  final $Res Function(WeatherEntry) _then;

/// Create a copy of WeatherEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? source = null,Object? windSpeedKnots = null,Object? windGustKnots = null,Object? windDirectionDegrees = null,Object? temperature = null,Object? humidity = null,Object? pressure = null,Object? seaState = null,Object? visibility = null,Object? precipitation = null,Object? notes = null,Object? loggedBy = null,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as WeatherSource,windSpeedKnots: null == windSpeedKnots ? _self.windSpeedKnots : windSpeedKnots // ignore: cast_nullable_to_non_nullable
as double,windGustKnots: null == windGustKnots ? _self.windGustKnots : windGustKnots // ignore: cast_nullable_to_non_nullable
as double,windDirectionDegrees: null == windDirectionDegrees ? _self.windDirectionDegrees : windDirectionDegrees // ignore: cast_nullable_to_non_nullable
as int,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,humidity: null == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as double,pressure: null == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double,seaState: null == seaState ? _self.seaState : seaState // ignore: cast_nullable_to_non_nullable
as SeaState,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as Visibility,precipitation: null == precipitation ? _self.precipitation : precipitation // ignore: cast_nullable_to_non_nullable
as Precipitation,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,loggedBy: null == loggedBy ? _self.loggedBy : loggedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WeatherEntry].
extension WeatherEntryPatterns on WeatherEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherEntry value)  $default,){
final _that = this;
switch (_that) {
case _WeatherEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherEntry value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime timestamp,  WeatherSource source,  double windSpeedKnots,  double windGustKnots,  int windDirectionDegrees,  double temperature,  double humidity,  double pressure,  SeaState seaState,  Visibility visibility,  Precipitation precipitation,  String notes,  String loggedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherEntry() when $default != null:
return $default(_that.timestamp,_that.source,_that.windSpeedKnots,_that.windGustKnots,_that.windDirectionDegrees,_that.temperature,_that.humidity,_that.pressure,_that.seaState,_that.visibility,_that.precipitation,_that.notes,_that.loggedBy);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime timestamp,  WeatherSource source,  double windSpeedKnots,  double windGustKnots,  int windDirectionDegrees,  double temperature,  double humidity,  double pressure,  SeaState seaState,  Visibility visibility,  Precipitation precipitation,  String notes,  String loggedBy)  $default,) {final _that = this;
switch (_that) {
case _WeatherEntry():
return $default(_that.timestamp,_that.source,_that.windSpeedKnots,_that.windGustKnots,_that.windDirectionDegrees,_that.temperature,_that.humidity,_that.pressure,_that.seaState,_that.visibility,_that.precipitation,_that.notes,_that.loggedBy);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime timestamp,  WeatherSource source,  double windSpeedKnots,  double windGustKnots,  int windDirectionDegrees,  double temperature,  double humidity,  double pressure,  SeaState seaState,  Visibility visibility,  Precipitation precipitation,  String notes,  String loggedBy)?  $default,) {final _that = this;
switch (_that) {
case _WeatherEntry() when $default != null:
return $default(_that.timestamp,_that.source,_that.windSpeedKnots,_that.windGustKnots,_that.windDirectionDegrees,_that.temperature,_that.humidity,_that.pressure,_that.seaState,_that.visibility,_that.precipitation,_that.notes,_that.loggedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeatherEntry implements WeatherEntry {
  const _WeatherEntry({required this.timestamp, required this.source, required this.windSpeedKnots, required this.windGustKnots, required this.windDirectionDegrees, required this.temperature, required this.humidity, required this.pressure, required this.seaState, required this.visibility, required this.precipitation, required this.notes, required this.loggedBy});
  factory _WeatherEntry.fromJson(Map<String, dynamic> json) => _$WeatherEntryFromJson(json);

@override final  DateTime timestamp;
@override final  WeatherSource source;
@override final  double windSpeedKnots;
@override final  double windGustKnots;
@override final  int windDirectionDegrees;
@override final  double temperature;
@override final  double humidity;
@override final  double pressure;
@override final  SeaState seaState;
@override final  Visibility visibility;
@override final  Precipitation precipitation;
@override final  String notes;
@override final  String loggedBy;

/// Create a copy of WeatherEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherEntryCopyWith<_WeatherEntry> get copyWith => __$WeatherEntryCopyWithImpl<_WeatherEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeatherEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherEntry&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.source, source) || other.source == source)&&(identical(other.windSpeedKnots, windSpeedKnots) || other.windSpeedKnots == windSpeedKnots)&&(identical(other.windGustKnots, windGustKnots) || other.windGustKnots == windGustKnots)&&(identical(other.windDirectionDegrees, windDirectionDegrees) || other.windDirectionDegrees == windDirectionDegrees)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.seaState, seaState) || other.seaState == seaState)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.precipitation, precipitation) || other.precipitation == precipitation)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.loggedBy, loggedBy) || other.loggedBy == loggedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,source,windSpeedKnots,windGustKnots,windDirectionDegrees,temperature,humidity,pressure,seaState,visibility,precipitation,notes,loggedBy);

@override
String toString() {
  return 'WeatherEntry(timestamp: $timestamp, source: $source, windSpeedKnots: $windSpeedKnots, windGustKnots: $windGustKnots, windDirectionDegrees: $windDirectionDegrees, temperature: $temperature, humidity: $humidity, pressure: $pressure, seaState: $seaState, visibility: $visibility, precipitation: $precipitation, notes: $notes, loggedBy: $loggedBy)';
}


}

/// @nodoc
abstract mixin class _$WeatherEntryCopyWith<$Res> implements $WeatherEntryCopyWith<$Res> {
  factory _$WeatherEntryCopyWith(_WeatherEntry value, $Res Function(_WeatherEntry) _then) = __$WeatherEntryCopyWithImpl;
@override @useResult
$Res call({
 DateTime timestamp, WeatherSource source, double windSpeedKnots, double windGustKnots, int windDirectionDegrees, double temperature, double humidity, double pressure, SeaState seaState, Visibility visibility, Precipitation precipitation, String notes, String loggedBy
});




}
/// @nodoc
class __$WeatherEntryCopyWithImpl<$Res>
    implements _$WeatherEntryCopyWith<$Res> {
  __$WeatherEntryCopyWithImpl(this._self, this._then);

  final _WeatherEntry _self;
  final $Res Function(_WeatherEntry) _then;

/// Create a copy of WeatherEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? source = null,Object? windSpeedKnots = null,Object? windGustKnots = null,Object? windDirectionDegrees = null,Object? temperature = null,Object? humidity = null,Object? pressure = null,Object? seaState = null,Object? visibility = null,Object? precipitation = null,Object? notes = null,Object? loggedBy = null,}) {
  return _then(_WeatherEntry(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as WeatherSource,windSpeedKnots: null == windSpeedKnots ? _self.windSpeedKnots : windSpeedKnots // ignore: cast_nullable_to_non_nullable
as double,windGustKnots: null == windGustKnots ? _self.windGustKnots : windGustKnots // ignore: cast_nullable_to_non_nullable
as double,windDirectionDegrees: null == windDirectionDegrees ? _self.windDirectionDegrees : windDirectionDegrees // ignore: cast_nullable_to_non_nullable
as int,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,humidity: null == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as double,pressure: null == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double,seaState: null == seaState ? _self.seaState : seaState // ignore: cast_nullable_to_non_nullable
as SeaState,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as Visibility,precipitation: null == precipitation ? _self.precipitation : precipitation // ignore: cast_nullable_to_non_nullable
as Precipitation,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,loggedBy: null == loggedBy ? _self.loggedBy : loggedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WeatherLog {

 String get id; String get eventId; List<WeatherEntry> get entries;
/// Create a copy of WeatherLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherLogCopyWith<WeatherLog> get copyWith => _$WeatherLogCopyWithImpl<WeatherLog>(this as WeatherLog, _$identity);

  /// Serializes this WeatherLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherLog&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&const DeepCollectionEquality().equals(other.entries, entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,const DeepCollectionEquality().hash(entries));

@override
String toString() {
  return 'WeatherLog(id: $id, eventId: $eventId, entries: $entries)';
}


}

/// @nodoc
abstract mixin class $WeatherLogCopyWith<$Res>  {
  factory $WeatherLogCopyWith(WeatherLog value, $Res Function(WeatherLog) _then) = _$WeatherLogCopyWithImpl;
@useResult
$Res call({
 String id, String eventId, List<WeatherEntry> entries
});




}
/// @nodoc
class _$WeatherLogCopyWithImpl<$Res>
    implements $WeatherLogCopyWith<$Res> {
  _$WeatherLogCopyWithImpl(this._self, this._then);

  final WeatherLog _self;
  final $Res Function(WeatherLog) _then;

/// Create a copy of WeatherLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? entries = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<WeatherEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [WeatherLog].
extension WeatherLogPatterns on WeatherLog {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherLog() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherLog value)  $default,){
final _that = this;
switch (_that) {
case _WeatherLog():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherLog value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherLog() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventId,  List<WeatherEntry> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherLog() when $default != null:
return $default(_that.id,_that.eventId,_that.entries);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventId,  List<WeatherEntry> entries)  $default,) {final _that = this;
switch (_that) {
case _WeatherLog():
return $default(_that.id,_that.eventId,_that.entries);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventId,  List<WeatherEntry> entries)?  $default,) {final _that = this;
switch (_that) {
case _WeatherLog() when $default != null:
return $default(_that.id,_that.eventId,_that.entries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeatherLog implements WeatherLog {
  const _WeatherLog({required this.id, required this.eventId, required final  List<WeatherEntry> entries}): _entries = entries;
  factory _WeatherLog.fromJson(Map<String, dynamic> json) => _$WeatherLogFromJson(json);

@override final  String id;
@override final  String eventId;
 final  List<WeatherEntry> _entries;
@override List<WeatherEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of WeatherLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherLogCopyWith<_WeatherLog> get copyWith => __$WeatherLogCopyWithImpl<_WeatherLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeatherLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherLog&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&const DeepCollectionEquality().equals(other._entries, _entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'WeatherLog(id: $id, eventId: $eventId, entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$WeatherLogCopyWith<$Res> implements $WeatherLogCopyWith<$Res> {
  factory _$WeatherLogCopyWith(_WeatherLog value, $Res Function(_WeatherLog) _then) = __$WeatherLogCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventId, List<WeatherEntry> entries
});




}
/// @nodoc
class __$WeatherLogCopyWithImpl<$Res>
    implements _$WeatherLogCopyWith<$Res> {
  __$WeatherLogCopyWithImpl(this._self, this._then);

  final _WeatherLog _self;
  final $Res Function(_WeatherLog) _then;

/// Create a copy of WeatherLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? entries = null,}) {
  return _then(_WeatherLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<WeatherEntry>,
  ));
}


}

// dart format on
