// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fleet_broadcast.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FleetBroadcast {

 String get id; String get eventId; String get sentBy; String get message; BroadcastType get type; DateTime get sentAt; int get deliveryCount;
/// Create a copy of FleetBroadcast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FleetBroadcastCopyWith<FleetBroadcast> get copyWith => _$FleetBroadcastCopyWithImpl<FleetBroadcast>(this as FleetBroadcast, _$identity);

  /// Serializes this FleetBroadcast to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FleetBroadcast&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.sentBy, sentBy) || other.sentBy == sentBy)&&(identical(other.message, message) || other.message == message)&&(identical(other.type, type) || other.type == type)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.deliveryCount, deliveryCount) || other.deliveryCount == deliveryCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,sentBy,message,type,sentAt,deliveryCount);

@override
String toString() {
  return 'FleetBroadcast(id: $id, eventId: $eventId, sentBy: $sentBy, message: $message, type: $type, sentAt: $sentAt, deliveryCount: $deliveryCount)';
}


}

/// @nodoc
abstract mixin class $FleetBroadcastCopyWith<$Res>  {
  factory $FleetBroadcastCopyWith(FleetBroadcast value, $Res Function(FleetBroadcast) _then) = _$FleetBroadcastCopyWithImpl;
@useResult
$Res call({
 String id, String eventId, String sentBy, String message, BroadcastType type, DateTime sentAt, int deliveryCount
});




}
/// @nodoc
class _$FleetBroadcastCopyWithImpl<$Res>
    implements $FleetBroadcastCopyWith<$Res> {
  _$FleetBroadcastCopyWithImpl(this._self, this._then);

  final FleetBroadcast _self;
  final $Res Function(FleetBroadcast) _then;

/// Create a copy of FleetBroadcast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? sentBy = null,Object? message = null,Object? type = null,Object? sentAt = null,Object? deliveryCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,sentBy: null == sentBy ? _self.sentBy : sentBy // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BroadcastType,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,deliveryCount: null == deliveryCount ? _self.deliveryCount : deliveryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FleetBroadcast].
extension FleetBroadcastPatterns on FleetBroadcast {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FleetBroadcast value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FleetBroadcast() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FleetBroadcast value)  $default,){
final _that = this;
switch (_that) {
case _FleetBroadcast():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FleetBroadcast value)?  $default,){
final _that = this;
switch (_that) {
case _FleetBroadcast() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventId,  String sentBy,  String message,  BroadcastType type,  DateTime sentAt,  int deliveryCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FleetBroadcast() when $default != null:
return $default(_that.id,_that.eventId,_that.sentBy,_that.message,_that.type,_that.sentAt,_that.deliveryCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventId,  String sentBy,  String message,  BroadcastType type,  DateTime sentAt,  int deliveryCount)  $default,) {final _that = this;
switch (_that) {
case _FleetBroadcast():
return $default(_that.id,_that.eventId,_that.sentBy,_that.message,_that.type,_that.sentAt,_that.deliveryCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventId,  String sentBy,  String message,  BroadcastType type,  DateTime sentAt,  int deliveryCount)?  $default,) {final _that = this;
switch (_that) {
case _FleetBroadcast() when $default != null:
return $default(_that.id,_that.eventId,_that.sentBy,_that.message,_that.type,_that.sentAt,_that.deliveryCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FleetBroadcast implements FleetBroadcast {
  const _FleetBroadcast({required this.id, required this.eventId, required this.sentBy, required this.message, required this.type, required this.sentAt, required this.deliveryCount});
  factory _FleetBroadcast.fromJson(Map<String, dynamic> json) => _$FleetBroadcastFromJson(json);

@override final  String id;
@override final  String eventId;
@override final  String sentBy;
@override final  String message;
@override final  BroadcastType type;
@override final  DateTime sentAt;
@override final  int deliveryCount;

/// Create a copy of FleetBroadcast
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FleetBroadcastCopyWith<_FleetBroadcast> get copyWith => __$FleetBroadcastCopyWithImpl<_FleetBroadcast>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FleetBroadcastToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FleetBroadcast&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.sentBy, sentBy) || other.sentBy == sentBy)&&(identical(other.message, message) || other.message == message)&&(identical(other.type, type) || other.type == type)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.deliveryCount, deliveryCount) || other.deliveryCount == deliveryCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,sentBy,message,type,sentAt,deliveryCount);

@override
String toString() {
  return 'FleetBroadcast(id: $id, eventId: $eventId, sentBy: $sentBy, message: $message, type: $type, sentAt: $sentAt, deliveryCount: $deliveryCount)';
}


}

/// @nodoc
abstract mixin class _$FleetBroadcastCopyWith<$Res> implements $FleetBroadcastCopyWith<$Res> {
  factory _$FleetBroadcastCopyWith(_FleetBroadcast value, $Res Function(_FleetBroadcast) _then) = __$FleetBroadcastCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventId, String sentBy, String message, BroadcastType type, DateTime sentAt, int deliveryCount
});




}
/// @nodoc
class __$FleetBroadcastCopyWithImpl<$Res>
    implements _$FleetBroadcastCopyWith<$Res> {
  __$FleetBroadcastCopyWithImpl(this._self, this._then);

  final _FleetBroadcast _self;
  final $Res Function(_FleetBroadcast) _then;

/// Create a copy of FleetBroadcast
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? sentBy = null,Object? message = null,Object? type = null,Object? sentAt = null,Object? deliveryCount = null,}) {
  return _then(_FleetBroadcast(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,sentBy: null == sentBy ? _self.sentBy : sentBy // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BroadcastType,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,deliveryCount: null == deliveryCount ? _self.deliveryCount : deliveryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
