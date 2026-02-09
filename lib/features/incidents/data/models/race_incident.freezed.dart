// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'race_incident.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BoatInvolved {

 String get sailNumber; String get boatName; String get skipperName; BoatInvolvedRole get role;
/// Create a copy of BoatInvolved
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoatInvolvedCopyWith<BoatInvolved> get copyWith => _$BoatInvolvedCopyWithImpl<BoatInvolved>(this as BoatInvolved, _$identity);

  /// Serializes this BoatInvolved to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoatInvolved&&(identical(other.sailNumber, sailNumber) || other.sailNumber == sailNumber)&&(identical(other.boatName, boatName) || other.boatName == boatName)&&(identical(other.skipperName, skipperName) || other.skipperName == skipperName)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sailNumber,boatName,skipperName,role);

@override
String toString() {
  return 'BoatInvolved(sailNumber: $sailNumber, boatName: $boatName, skipperName: $skipperName, role: $role)';
}


}

/// @nodoc
abstract mixin class $BoatInvolvedCopyWith<$Res>  {
  factory $BoatInvolvedCopyWith(BoatInvolved value, $Res Function(BoatInvolved) _then) = _$BoatInvolvedCopyWithImpl;
@useResult
$Res call({
 String sailNumber, String boatName, String skipperName, BoatInvolvedRole role
});




}
/// @nodoc
class _$BoatInvolvedCopyWithImpl<$Res>
    implements $BoatInvolvedCopyWith<$Res> {
  _$BoatInvolvedCopyWithImpl(this._self, this._then);

  final BoatInvolved _self;
  final $Res Function(BoatInvolved) _then;

/// Create a copy of BoatInvolved
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sailNumber = null,Object? boatName = null,Object? skipperName = null,Object? role = null,}) {
  return _then(_self.copyWith(
sailNumber: null == sailNumber ? _self.sailNumber : sailNumber // ignore: cast_nullable_to_non_nullable
as String,boatName: null == boatName ? _self.boatName : boatName // ignore: cast_nullable_to_non_nullable
as String,skipperName: null == skipperName ? _self.skipperName : skipperName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as BoatInvolvedRole,
  ));
}

}


/// Adds pattern-matching-related methods to [BoatInvolved].
extension BoatInvolvedPatterns on BoatInvolved {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoatInvolved value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoatInvolved() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoatInvolved value)  $default,){
final _that = this;
switch (_that) {
case _BoatInvolved():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoatInvolved value)?  $default,){
final _that = this;
switch (_that) {
case _BoatInvolved() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sailNumber,  String boatName,  String skipperName,  BoatInvolvedRole role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoatInvolved() when $default != null:
return $default(_that.sailNumber,_that.boatName,_that.skipperName,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sailNumber,  String boatName,  String skipperName,  BoatInvolvedRole role)  $default,) {final _that = this;
switch (_that) {
case _BoatInvolved():
return $default(_that.sailNumber,_that.boatName,_that.skipperName,_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sailNumber,  String boatName,  String skipperName,  BoatInvolvedRole role)?  $default,) {final _that = this;
switch (_that) {
case _BoatInvolved() when $default != null:
return $default(_that.sailNumber,_that.boatName,_that.skipperName,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BoatInvolved implements BoatInvolved {
  const _BoatInvolved({required this.sailNumber, required this.boatName, required this.skipperName, required this.role});
  factory _BoatInvolved.fromJson(Map<String, dynamic> json) => _$BoatInvolvedFromJson(json);

@override final  String sailNumber;
@override final  String boatName;
@override final  String skipperName;
@override final  BoatInvolvedRole role;

/// Create a copy of BoatInvolved
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoatInvolvedCopyWith<_BoatInvolved> get copyWith => __$BoatInvolvedCopyWithImpl<_BoatInvolved>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BoatInvolvedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoatInvolved&&(identical(other.sailNumber, sailNumber) || other.sailNumber == sailNumber)&&(identical(other.boatName, boatName) || other.boatName == boatName)&&(identical(other.skipperName, skipperName) || other.skipperName == skipperName)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sailNumber,boatName,skipperName,role);

@override
String toString() {
  return 'BoatInvolved(sailNumber: $sailNumber, boatName: $boatName, skipperName: $skipperName, role: $role)';
}


}

/// @nodoc
abstract mixin class _$BoatInvolvedCopyWith<$Res> implements $BoatInvolvedCopyWith<$Res> {
  factory _$BoatInvolvedCopyWith(_BoatInvolved value, $Res Function(_BoatInvolved) _then) = __$BoatInvolvedCopyWithImpl;
@override @useResult
$Res call({
 String sailNumber, String boatName, String skipperName, BoatInvolvedRole role
});




}
/// @nodoc
class __$BoatInvolvedCopyWithImpl<$Res>
    implements _$BoatInvolvedCopyWith<$Res> {
  __$BoatInvolvedCopyWithImpl(this._self, this._then);

  final _BoatInvolved _self;
  final $Res Function(_BoatInvolved) _then;

/// Create a copy of BoatInvolved
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sailNumber = null,Object? boatName = null,Object? skipperName = null,Object? role = null,}) {
  return _then(_BoatInvolved(
sailNumber: null == sailNumber ? _self.sailNumber : sailNumber // ignore: cast_nullable_to_non_nullable
as String,boatName: null == boatName ? _self.boatName : boatName // ignore: cast_nullable_to_non_nullable
as String,skipperName: null == skipperName ? _self.skipperName : skipperName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as BoatInvolvedRole,
  ));
}


}


/// @nodoc
mixin _$RaceIncident {

 String get id; String get eventId; int get raceNumber; DateTime get reportedAt; String get reportedBy; DateTime get incidentTime; String get description; CourseLocationOnIncident get locationOnCourse; List<BoatInvolved> get involvedBoats; List<String> get rulesAlleged; RaceIncidentStatus get status; DateTime? get hearingDate; String get resolution; String get penaltyApplied; List<String> get witnesses; List<String> get attachments;
/// Create a copy of RaceIncident
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaceIncidentCopyWith<RaceIncident> get copyWith => _$RaceIncidentCopyWithImpl<RaceIncident>(this as RaceIncident, _$identity);

  /// Serializes this RaceIncident to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RaceIncident&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.raceNumber, raceNumber) || other.raceNumber == raceNumber)&&(identical(other.reportedAt, reportedAt) || other.reportedAt == reportedAt)&&(identical(other.reportedBy, reportedBy) || other.reportedBy == reportedBy)&&(identical(other.incidentTime, incidentTime) || other.incidentTime == incidentTime)&&(identical(other.description, description) || other.description == description)&&(identical(other.locationOnCourse, locationOnCourse) || other.locationOnCourse == locationOnCourse)&&const DeepCollectionEquality().equals(other.involvedBoats, involvedBoats)&&const DeepCollectionEquality().equals(other.rulesAlleged, rulesAlleged)&&(identical(other.status, status) || other.status == status)&&(identical(other.hearingDate, hearingDate) || other.hearingDate == hearingDate)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.penaltyApplied, penaltyApplied) || other.penaltyApplied == penaltyApplied)&&const DeepCollectionEquality().equals(other.witnesses, witnesses)&&const DeepCollectionEquality().equals(other.attachments, attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,raceNumber,reportedAt,reportedBy,incidentTime,description,locationOnCourse,const DeepCollectionEquality().hash(involvedBoats),const DeepCollectionEquality().hash(rulesAlleged),status,hearingDate,resolution,penaltyApplied,const DeepCollectionEquality().hash(witnesses),const DeepCollectionEquality().hash(attachments));

@override
String toString() {
  return 'RaceIncident(id: $id, eventId: $eventId, raceNumber: $raceNumber, reportedAt: $reportedAt, reportedBy: $reportedBy, incidentTime: $incidentTime, description: $description, locationOnCourse: $locationOnCourse, involvedBoats: $involvedBoats, rulesAlleged: $rulesAlleged, status: $status, hearingDate: $hearingDate, resolution: $resolution, penaltyApplied: $penaltyApplied, witnesses: $witnesses, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class $RaceIncidentCopyWith<$Res>  {
  factory $RaceIncidentCopyWith(RaceIncident value, $Res Function(RaceIncident) _then) = _$RaceIncidentCopyWithImpl;
@useResult
$Res call({
 String id, String eventId, int raceNumber, DateTime reportedAt, String reportedBy, DateTime incidentTime, String description, CourseLocationOnIncident locationOnCourse, List<BoatInvolved> involvedBoats, List<String> rulesAlleged, RaceIncidentStatus status, DateTime? hearingDate, String resolution, String penaltyApplied, List<String> witnesses, List<String> attachments
});




}
/// @nodoc
class _$RaceIncidentCopyWithImpl<$Res>
    implements $RaceIncidentCopyWith<$Res> {
  _$RaceIncidentCopyWithImpl(this._self, this._then);

  final RaceIncident _self;
  final $Res Function(RaceIncident) _then;

/// Create a copy of RaceIncident
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? raceNumber = null,Object? reportedAt = null,Object? reportedBy = null,Object? incidentTime = null,Object? description = null,Object? locationOnCourse = null,Object? involvedBoats = null,Object? rulesAlleged = null,Object? status = null,Object? hearingDate = freezed,Object? resolution = null,Object? penaltyApplied = null,Object? witnesses = null,Object? attachments = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,raceNumber: null == raceNumber ? _self.raceNumber : raceNumber // ignore: cast_nullable_to_non_nullable
as int,reportedAt: null == reportedAt ? _self.reportedAt : reportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reportedBy: null == reportedBy ? _self.reportedBy : reportedBy // ignore: cast_nullable_to_non_nullable
as String,incidentTime: null == incidentTime ? _self.incidentTime : incidentTime // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,locationOnCourse: null == locationOnCourse ? _self.locationOnCourse : locationOnCourse // ignore: cast_nullable_to_non_nullable
as CourseLocationOnIncident,involvedBoats: null == involvedBoats ? _self.involvedBoats : involvedBoats // ignore: cast_nullable_to_non_nullable
as List<BoatInvolved>,rulesAlleged: null == rulesAlleged ? _self.rulesAlleged : rulesAlleged // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RaceIncidentStatus,hearingDate: freezed == hearingDate ? _self.hearingDate : hearingDate // ignore: cast_nullable_to_non_nullable
as DateTime?,resolution: null == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String,penaltyApplied: null == penaltyApplied ? _self.penaltyApplied : penaltyApplied // ignore: cast_nullable_to_non_nullable
as String,witnesses: null == witnesses ? _self.witnesses : witnesses // ignore: cast_nullable_to_non_nullable
as List<String>,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [RaceIncident].
extension RaceIncidentPatterns on RaceIncident {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RaceIncident value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RaceIncident() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RaceIncident value)  $default,){
final _that = this;
switch (_that) {
case _RaceIncident():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RaceIncident value)?  $default,){
final _that = this;
switch (_that) {
case _RaceIncident() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventId,  int raceNumber,  DateTime reportedAt,  String reportedBy,  DateTime incidentTime,  String description,  CourseLocationOnIncident locationOnCourse,  List<BoatInvolved> involvedBoats,  List<String> rulesAlleged,  RaceIncidentStatus status,  DateTime? hearingDate,  String resolution,  String penaltyApplied,  List<String> witnesses,  List<String> attachments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RaceIncident() when $default != null:
return $default(_that.id,_that.eventId,_that.raceNumber,_that.reportedAt,_that.reportedBy,_that.incidentTime,_that.description,_that.locationOnCourse,_that.involvedBoats,_that.rulesAlleged,_that.status,_that.hearingDate,_that.resolution,_that.penaltyApplied,_that.witnesses,_that.attachments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventId,  int raceNumber,  DateTime reportedAt,  String reportedBy,  DateTime incidentTime,  String description,  CourseLocationOnIncident locationOnCourse,  List<BoatInvolved> involvedBoats,  List<String> rulesAlleged,  RaceIncidentStatus status,  DateTime? hearingDate,  String resolution,  String penaltyApplied,  List<String> witnesses,  List<String> attachments)  $default,) {final _that = this;
switch (_that) {
case _RaceIncident():
return $default(_that.id,_that.eventId,_that.raceNumber,_that.reportedAt,_that.reportedBy,_that.incidentTime,_that.description,_that.locationOnCourse,_that.involvedBoats,_that.rulesAlleged,_that.status,_that.hearingDate,_that.resolution,_that.penaltyApplied,_that.witnesses,_that.attachments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventId,  int raceNumber,  DateTime reportedAt,  String reportedBy,  DateTime incidentTime,  String description,  CourseLocationOnIncident locationOnCourse,  List<BoatInvolved> involvedBoats,  List<String> rulesAlleged,  RaceIncidentStatus status,  DateTime? hearingDate,  String resolution,  String penaltyApplied,  List<String> witnesses,  List<String> attachments)?  $default,) {final _that = this;
switch (_that) {
case _RaceIncident() when $default != null:
return $default(_that.id,_that.eventId,_that.raceNumber,_that.reportedAt,_that.reportedBy,_that.incidentTime,_that.description,_that.locationOnCourse,_that.involvedBoats,_that.rulesAlleged,_that.status,_that.hearingDate,_that.resolution,_that.penaltyApplied,_that.witnesses,_that.attachments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RaceIncident implements RaceIncident {
  const _RaceIncident({required this.id, required this.eventId, required this.raceNumber, required this.reportedAt, required this.reportedBy, required this.incidentTime, required this.description, required this.locationOnCourse, required final  List<BoatInvolved> involvedBoats, required final  List<String> rulesAlleged, required this.status, this.hearingDate, required this.resolution, required this.penaltyApplied, required final  List<String> witnesses, required final  List<String> attachments}): _involvedBoats = involvedBoats,_rulesAlleged = rulesAlleged,_witnesses = witnesses,_attachments = attachments;
  factory _RaceIncident.fromJson(Map<String, dynamic> json) => _$RaceIncidentFromJson(json);

@override final  String id;
@override final  String eventId;
@override final  int raceNumber;
@override final  DateTime reportedAt;
@override final  String reportedBy;
@override final  DateTime incidentTime;
@override final  String description;
@override final  CourseLocationOnIncident locationOnCourse;
 final  List<BoatInvolved> _involvedBoats;
@override List<BoatInvolved> get involvedBoats {
  if (_involvedBoats is EqualUnmodifiableListView) return _involvedBoats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_involvedBoats);
}

 final  List<String> _rulesAlleged;
@override List<String> get rulesAlleged {
  if (_rulesAlleged is EqualUnmodifiableListView) return _rulesAlleged;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rulesAlleged);
}

@override final  RaceIncidentStatus status;
@override final  DateTime? hearingDate;
@override final  String resolution;
@override final  String penaltyApplied;
 final  List<String> _witnesses;
@override List<String> get witnesses {
  if (_witnesses is EqualUnmodifiableListView) return _witnesses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_witnesses);
}

 final  List<String> _attachments;
@override List<String> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}


/// Create a copy of RaceIncident
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaceIncidentCopyWith<_RaceIncident> get copyWith => __$RaceIncidentCopyWithImpl<_RaceIncident>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RaceIncidentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RaceIncident&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.raceNumber, raceNumber) || other.raceNumber == raceNumber)&&(identical(other.reportedAt, reportedAt) || other.reportedAt == reportedAt)&&(identical(other.reportedBy, reportedBy) || other.reportedBy == reportedBy)&&(identical(other.incidentTime, incidentTime) || other.incidentTime == incidentTime)&&(identical(other.description, description) || other.description == description)&&(identical(other.locationOnCourse, locationOnCourse) || other.locationOnCourse == locationOnCourse)&&const DeepCollectionEquality().equals(other._involvedBoats, _involvedBoats)&&const DeepCollectionEquality().equals(other._rulesAlleged, _rulesAlleged)&&(identical(other.status, status) || other.status == status)&&(identical(other.hearingDate, hearingDate) || other.hearingDate == hearingDate)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.penaltyApplied, penaltyApplied) || other.penaltyApplied == penaltyApplied)&&const DeepCollectionEquality().equals(other._witnesses, _witnesses)&&const DeepCollectionEquality().equals(other._attachments, _attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,raceNumber,reportedAt,reportedBy,incidentTime,description,locationOnCourse,const DeepCollectionEquality().hash(_involvedBoats),const DeepCollectionEquality().hash(_rulesAlleged),status,hearingDate,resolution,penaltyApplied,const DeepCollectionEquality().hash(_witnesses),const DeepCollectionEquality().hash(_attachments));

@override
String toString() {
  return 'RaceIncident(id: $id, eventId: $eventId, raceNumber: $raceNumber, reportedAt: $reportedAt, reportedBy: $reportedBy, incidentTime: $incidentTime, description: $description, locationOnCourse: $locationOnCourse, involvedBoats: $involvedBoats, rulesAlleged: $rulesAlleged, status: $status, hearingDate: $hearingDate, resolution: $resolution, penaltyApplied: $penaltyApplied, witnesses: $witnesses, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class _$RaceIncidentCopyWith<$Res> implements $RaceIncidentCopyWith<$Res> {
  factory _$RaceIncidentCopyWith(_RaceIncident value, $Res Function(_RaceIncident) _then) = __$RaceIncidentCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventId, int raceNumber, DateTime reportedAt, String reportedBy, DateTime incidentTime, String description, CourseLocationOnIncident locationOnCourse, List<BoatInvolved> involvedBoats, List<String> rulesAlleged, RaceIncidentStatus status, DateTime? hearingDate, String resolution, String penaltyApplied, List<String> witnesses, List<String> attachments
});




}
/// @nodoc
class __$RaceIncidentCopyWithImpl<$Res>
    implements _$RaceIncidentCopyWith<$Res> {
  __$RaceIncidentCopyWithImpl(this._self, this._then);

  final _RaceIncident _self;
  final $Res Function(_RaceIncident) _then;

/// Create a copy of RaceIncident
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? raceNumber = null,Object? reportedAt = null,Object? reportedBy = null,Object? incidentTime = null,Object? description = null,Object? locationOnCourse = null,Object? involvedBoats = null,Object? rulesAlleged = null,Object? status = null,Object? hearingDate = freezed,Object? resolution = null,Object? penaltyApplied = null,Object? witnesses = null,Object? attachments = null,}) {
  return _then(_RaceIncident(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,raceNumber: null == raceNumber ? _self.raceNumber : raceNumber // ignore: cast_nullable_to_non_nullable
as int,reportedAt: null == reportedAt ? _self.reportedAt : reportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reportedBy: null == reportedBy ? _self.reportedBy : reportedBy // ignore: cast_nullable_to_non_nullable
as String,incidentTime: null == incidentTime ? _self.incidentTime : incidentTime // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,locationOnCourse: null == locationOnCourse ? _self.locationOnCourse : locationOnCourse // ignore: cast_nullable_to_non_nullable
as CourseLocationOnIncident,involvedBoats: null == involvedBoats ? _self._involvedBoats : involvedBoats // ignore: cast_nullable_to_non_nullable
as List<BoatInvolved>,rulesAlleged: null == rulesAlleged ? _self._rulesAlleged : rulesAlleged // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RaceIncidentStatus,hearingDate: freezed == hearingDate ? _self.hearingDate : hearingDate // ignore: cast_nullable_to_non_nullable
as DateTime?,resolution: null == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String,penaltyApplied: null == penaltyApplied ? _self.penaltyApplied : penaltyApplied // ignore: cast_nullable_to_non_nullable
as String,witnesses: null == witnesses ? _self._witnesses : witnesses // ignore: cast_nullable_to_non_nullable
as List<String>,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
