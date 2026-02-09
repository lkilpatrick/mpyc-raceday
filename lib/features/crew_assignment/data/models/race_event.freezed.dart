// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'race_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CrewAssignment {

 String get memberId; String get memberName; CrewRole get role; bool get confirmed; DateTime? get confirmedAt; String? get declineReason;
/// Create a copy of CrewAssignment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CrewAssignmentCopyWith<CrewAssignment> get copyWith => _$CrewAssignmentCopyWithImpl<CrewAssignment>(this as CrewAssignment, _$identity);

  /// Serializes this CrewAssignment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrewAssignment&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.memberName, memberName) || other.memberName == memberName)&&(identical(other.role, role) || other.role == role)&&(identical(other.confirmed, confirmed) || other.confirmed == confirmed)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.declineReason, declineReason) || other.declineReason == declineReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberId,memberName,role,confirmed,confirmedAt,declineReason);

@override
String toString() {
  return 'CrewAssignment(memberId: $memberId, memberName: $memberName, role: $role, confirmed: $confirmed, confirmedAt: $confirmedAt, declineReason: $declineReason)';
}


}

/// @nodoc
abstract mixin class $CrewAssignmentCopyWith<$Res>  {
  factory $CrewAssignmentCopyWith(CrewAssignment value, $Res Function(CrewAssignment) _then) = _$CrewAssignmentCopyWithImpl;
@useResult
$Res call({
 String memberId, String memberName, CrewRole role, bool confirmed, DateTime? confirmedAt, String? declineReason
});




}
/// @nodoc
class _$CrewAssignmentCopyWithImpl<$Res>
    implements $CrewAssignmentCopyWith<$Res> {
  _$CrewAssignmentCopyWithImpl(this._self, this._then);

  final CrewAssignment _self;
  final $Res Function(CrewAssignment) _then;

/// Create a copy of CrewAssignment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memberId = null,Object? memberName = null,Object? role = null,Object? confirmed = null,Object? confirmedAt = freezed,Object? declineReason = freezed,}) {
  return _then(_self.copyWith(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,memberName: null == memberName ? _self.memberName : memberName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as CrewRole,confirmed: null == confirmed ? _self.confirmed : confirmed // ignore: cast_nullable_to_non_nullable
as bool,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,declineReason: freezed == declineReason ? _self.declineReason : declineReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CrewAssignment].
extension CrewAssignmentPatterns on CrewAssignment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CrewAssignment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CrewAssignment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CrewAssignment value)  $default,){
final _that = this;
switch (_that) {
case _CrewAssignment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CrewAssignment value)?  $default,){
final _that = this;
switch (_that) {
case _CrewAssignment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String memberId,  String memberName,  CrewRole role,  bool confirmed,  DateTime? confirmedAt,  String? declineReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CrewAssignment() when $default != null:
return $default(_that.memberId,_that.memberName,_that.role,_that.confirmed,_that.confirmedAt,_that.declineReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String memberId,  String memberName,  CrewRole role,  bool confirmed,  DateTime? confirmedAt,  String? declineReason)  $default,) {final _that = this;
switch (_that) {
case _CrewAssignment():
return $default(_that.memberId,_that.memberName,_that.role,_that.confirmed,_that.confirmedAt,_that.declineReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String memberId,  String memberName,  CrewRole role,  bool confirmed,  DateTime? confirmedAt,  String? declineReason)?  $default,) {final _that = this;
switch (_that) {
case _CrewAssignment() when $default != null:
return $default(_that.memberId,_that.memberName,_that.role,_that.confirmed,_that.confirmedAt,_that.declineReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CrewAssignment implements CrewAssignment {
  const _CrewAssignment({required this.memberId, required this.memberName, required this.role, required this.confirmed, this.confirmedAt, this.declineReason});
  factory _CrewAssignment.fromJson(Map<String, dynamic> json) => _$CrewAssignmentFromJson(json);

@override final  String memberId;
@override final  String memberName;
@override final  CrewRole role;
@override final  bool confirmed;
@override final  DateTime? confirmedAt;
@override final  String? declineReason;

/// Create a copy of CrewAssignment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CrewAssignmentCopyWith<_CrewAssignment> get copyWith => __$CrewAssignmentCopyWithImpl<_CrewAssignment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CrewAssignmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CrewAssignment&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.memberName, memberName) || other.memberName == memberName)&&(identical(other.role, role) || other.role == role)&&(identical(other.confirmed, confirmed) || other.confirmed == confirmed)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.declineReason, declineReason) || other.declineReason == declineReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberId,memberName,role,confirmed,confirmedAt,declineReason);

@override
String toString() {
  return 'CrewAssignment(memberId: $memberId, memberName: $memberName, role: $role, confirmed: $confirmed, confirmedAt: $confirmedAt, declineReason: $declineReason)';
}


}

/// @nodoc
abstract mixin class _$CrewAssignmentCopyWith<$Res> implements $CrewAssignmentCopyWith<$Res> {
  factory _$CrewAssignmentCopyWith(_CrewAssignment value, $Res Function(_CrewAssignment) _then) = __$CrewAssignmentCopyWithImpl;
@override @useResult
$Res call({
 String memberId, String memberName, CrewRole role, bool confirmed, DateTime? confirmedAt, String? declineReason
});




}
/// @nodoc
class __$CrewAssignmentCopyWithImpl<$Res>
    implements _$CrewAssignmentCopyWith<$Res> {
  __$CrewAssignmentCopyWithImpl(this._self, this._then);

  final _CrewAssignment _self;
  final $Res Function(_CrewAssignment) _then;

/// Create a copy of CrewAssignment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memberId = null,Object? memberName = null,Object? role = null,Object? confirmed = null,Object? confirmedAt = freezed,Object? declineReason = freezed,}) {
  return _then(_CrewAssignment(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,memberName: null == memberName ? _self.memberName : memberName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as CrewRole,confirmed: null == confirmed ? _self.confirmed : confirmed // ignore: cast_nullable_to_non_nullable
as bool,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,declineReason: freezed == declineReason ? _self.declineReason : declineReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RaceEvent {

 String get id; String get eventName; DateTime get eventDate; String get seriesName; List<CrewAssignment> get assignedCrew; RaceEventStatus get status; String? get courseId; String? get weatherLogId; String get notes; DateTime get sunsetTime;
/// Create a copy of RaceEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaceEventCopyWith<RaceEvent> get copyWith => _$RaceEventCopyWithImpl<RaceEvent>(this as RaceEvent, _$identity);

  /// Serializes this RaceEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RaceEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&(identical(other.eventDate, eventDate) || other.eventDate == eventDate)&&(identical(other.seriesName, seriesName) || other.seriesName == seriesName)&&const DeepCollectionEquality().equals(other.assignedCrew, assignedCrew)&&(identical(other.status, status) || other.status == status)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.weatherLogId, weatherLogId) || other.weatherLogId == weatherLogId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.sunsetTime, sunsetTime) || other.sunsetTime == sunsetTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventName,eventDate,seriesName,const DeepCollectionEquality().hash(assignedCrew),status,courseId,weatherLogId,notes,sunsetTime);

@override
String toString() {
  return 'RaceEvent(id: $id, eventName: $eventName, eventDate: $eventDate, seriesName: $seriesName, assignedCrew: $assignedCrew, status: $status, courseId: $courseId, weatherLogId: $weatherLogId, notes: $notes, sunsetTime: $sunsetTime)';
}


}

/// @nodoc
abstract mixin class $RaceEventCopyWith<$Res>  {
  factory $RaceEventCopyWith(RaceEvent value, $Res Function(RaceEvent) _then) = _$RaceEventCopyWithImpl;
@useResult
$Res call({
 String id, String eventName, DateTime eventDate, String seriesName, List<CrewAssignment> assignedCrew, RaceEventStatus status, String? courseId, String? weatherLogId, String notes, DateTime sunsetTime
});




}
/// @nodoc
class _$RaceEventCopyWithImpl<$Res>
    implements $RaceEventCopyWith<$Res> {
  _$RaceEventCopyWithImpl(this._self, this._then);

  final RaceEvent _self;
  final $Res Function(RaceEvent) _then;

/// Create a copy of RaceEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventName = null,Object? eventDate = null,Object? seriesName = null,Object? assignedCrew = null,Object? status = null,Object? courseId = freezed,Object? weatherLogId = freezed,Object? notes = null,Object? sunsetTime = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,eventDate: null == eventDate ? _self.eventDate : eventDate // ignore: cast_nullable_to_non_nullable
as DateTime,seriesName: null == seriesName ? _self.seriesName : seriesName // ignore: cast_nullable_to_non_nullable
as String,assignedCrew: null == assignedCrew ? _self.assignedCrew : assignedCrew // ignore: cast_nullable_to_non_nullable
as List<CrewAssignment>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RaceEventStatus,courseId: freezed == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String?,weatherLogId: freezed == weatherLogId ? _self.weatherLogId : weatherLogId // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,sunsetTime: null == sunsetTime ? _self.sunsetTime : sunsetTime // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RaceEvent].
extension RaceEventPatterns on RaceEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RaceEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RaceEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RaceEvent value)  $default,){
final _that = this;
switch (_that) {
case _RaceEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RaceEvent value)?  $default,){
final _that = this;
switch (_that) {
case _RaceEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventName,  DateTime eventDate,  String seriesName,  List<CrewAssignment> assignedCrew,  RaceEventStatus status,  String? courseId,  String? weatherLogId,  String notes,  DateTime sunsetTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RaceEvent() when $default != null:
return $default(_that.id,_that.eventName,_that.eventDate,_that.seriesName,_that.assignedCrew,_that.status,_that.courseId,_that.weatherLogId,_that.notes,_that.sunsetTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventName,  DateTime eventDate,  String seriesName,  List<CrewAssignment> assignedCrew,  RaceEventStatus status,  String? courseId,  String? weatherLogId,  String notes,  DateTime sunsetTime)  $default,) {final _that = this;
switch (_that) {
case _RaceEvent():
return $default(_that.id,_that.eventName,_that.eventDate,_that.seriesName,_that.assignedCrew,_that.status,_that.courseId,_that.weatherLogId,_that.notes,_that.sunsetTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventName,  DateTime eventDate,  String seriesName,  List<CrewAssignment> assignedCrew,  RaceEventStatus status,  String? courseId,  String? weatherLogId,  String notes,  DateTime sunsetTime)?  $default,) {final _that = this;
switch (_that) {
case _RaceEvent() when $default != null:
return $default(_that.id,_that.eventName,_that.eventDate,_that.seriesName,_that.assignedCrew,_that.status,_that.courseId,_that.weatherLogId,_that.notes,_that.sunsetTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RaceEvent implements RaceEvent {
  const _RaceEvent({required this.id, required this.eventName, required this.eventDate, required this.seriesName, required final  List<CrewAssignment> assignedCrew, required this.status, this.courseId, this.weatherLogId, required this.notes, required this.sunsetTime}): _assignedCrew = assignedCrew;
  factory _RaceEvent.fromJson(Map<String, dynamic> json) => _$RaceEventFromJson(json);

@override final  String id;
@override final  String eventName;
@override final  DateTime eventDate;
@override final  String seriesName;
 final  List<CrewAssignment> _assignedCrew;
@override List<CrewAssignment> get assignedCrew {
  if (_assignedCrew is EqualUnmodifiableListView) return _assignedCrew;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assignedCrew);
}

@override final  RaceEventStatus status;
@override final  String? courseId;
@override final  String? weatherLogId;
@override final  String notes;
@override final  DateTime sunsetTime;

/// Create a copy of RaceEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaceEventCopyWith<_RaceEvent> get copyWith => __$RaceEventCopyWithImpl<_RaceEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RaceEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RaceEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&(identical(other.eventDate, eventDate) || other.eventDate == eventDate)&&(identical(other.seriesName, seriesName) || other.seriesName == seriesName)&&const DeepCollectionEquality().equals(other._assignedCrew, _assignedCrew)&&(identical(other.status, status) || other.status == status)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.weatherLogId, weatherLogId) || other.weatherLogId == weatherLogId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.sunsetTime, sunsetTime) || other.sunsetTime == sunsetTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventName,eventDate,seriesName,const DeepCollectionEquality().hash(_assignedCrew),status,courseId,weatherLogId,notes,sunsetTime);

@override
String toString() {
  return 'RaceEvent(id: $id, eventName: $eventName, eventDate: $eventDate, seriesName: $seriesName, assignedCrew: $assignedCrew, status: $status, courseId: $courseId, weatherLogId: $weatherLogId, notes: $notes, sunsetTime: $sunsetTime)';
}


}

/// @nodoc
abstract mixin class _$RaceEventCopyWith<$Res> implements $RaceEventCopyWith<$Res> {
  factory _$RaceEventCopyWith(_RaceEvent value, $Res Function(_RaceEvent) _then) = __$RaceEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventName, DateTime eventDate, String seriesName, List<CrewAssignment> assignedCrew, RaceEventStatus status, String? courseId, String? weatherLogId, String notes, DateTime sunsetTime
});




}
/// @nodoc
class __$RaceEventCopyWithImpl<$Res>
    implements _$RaceEventCopyWith<$Res> {
  __$RaceEventCopyWithImpl(this._self, this._then);

  final _RaceEvent _self;
  final $Res Function(_RaceEvent) _then;

/// Create a copy of RaceEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventName = null,Object? eventDate = null,Object? seriesName = null,Object? assignedCrew = null,Object? status = null,Object? courseId = freezed,Object? weatherLogId = freezed,Object? notes = null,Object? sunsetTime = null,}) {
  return _then(_RaceEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,eventDate: null == eventDate ? _self.eventDate : eventDate // ignore: cast_nullable_to_non_nullable
as DateTime,seriesName: null == seriesName ? _self.seriesName : seriesName // ignore: cast_nullable_to_non_nullable
as String,assignedCrew: null == assignedCrew ? _self._assignedCrew : assignedCrew // ignore: cast_nullable_to_non_nullable
as List<CrewAssignment>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RaceEventStatus,courseId: freezed == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String?,weatherLogId: freezed == weatherLogId ? _self.weatherLogId : weatherLogId // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,sunsetTime: null == sunsetTime ? _self.sunsetTime : sunsetTime // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
