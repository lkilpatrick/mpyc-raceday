// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'boat_checkin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BoatCheckin {

 String get id; String get eventId; String get sailNumber; String get boatName; String get skipperName; String get boatClass; DateTime get checkedInAt; String get checkedInBy; int get crewCount; List<String> get crewNames; bool get safetyEquipmentVerified; int? get phrfRating;
/// Create a copy of BoatCheckin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoatCheckinCopyWith<BoatCheckin> get copyWith => _$BoatCheckinCopyWithImpl<BoatCheckin>(this as BoatCheckin, _$identity);

  /// Serializes this BoatCheckin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoatCheckin&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.sailNumber, sailNumber) || other.sailNumber == sailNumber)&&(identical(other.boatName, boatName) || other.boatName == boatName)&&(identical(other.skipperName, skipperName) || other.skipperName == skipperName)&&(identical(other.boatClass, boatClass) || other.boatClass == boatClass)&&(identical(other.checkedInAt, checkedInAt) || other.checkedInAt == checkedInAt)&&(identical(other.checkedInBy, checkedInBy) || other.checkedInBy == checkedInBy)&&(identical(other.crewCount, crewCount) || other.crewCount == crewCount)&&const DeepCollectionEquality().equals(other.crewNames, crewNames)&&(identical(other.safetyEquipmentVerified, safetyEquipmentVerified) || other.safetyEquipmentVerified == safetyEquipmentVerified)&&(identical(other.phrfRating, phrfRating) || other.phrfRating == phrfRating));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,sailNumber,boatName,skipperName,boatClass,checkedInAt,checkedInBy,crewCount,const DeepCollectionEquality().hash(crewNames),safetyEquipmentVerified,phrfRating);

@override
String toString() {
  return 'BoatCheckin(id: $id, eventId: $eventId, sailNumber: $sailNumber, boatName: $boatName, skipperName: $skipperName, boatClass: $boatClass, checkedInAt: $checkedInAt, checkedInBy: $checkedInBy, crewCount: $crewCount, crewNames: $crewNames, safetyEquipmentVerified: $safetyEquipmentVerified, phrfRating: $phrfRating)';
}


}

/// @nodoc
abstract mixin class $BoatCheckinCopyWith<$Res>  {
  factory $BoatCheckinCopyWith(BoatCheckin value, $Res Function(BoatCheckin) _then) = _$BoatCheckinCopyWithImpl;
@useResult
$Res call({
 String id, String eventId, String sailNumber, String boatName, String skipperName, String boatClass, DateTime checkedInAt, String checkedInBy, int crewCount, List<String> crewNames, bool safetyEquipmentVerified, int? phrfRating
});




}
/// @nodoc
class _$BoatCheckinCopyWithImpl<$Res>
    implements $BoatCheckinCopyWith<$Res> {
  _$BoatCheckinCopyWithImpl(this._self, this._then);

  final BoatCheckin _self;
  final $Res Function(BoatCheckin) _then;

/// Create a copy of BoatCheckin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? sailNumber = null,Object? boatName = null,Object? skipperName = null,Object? boatClass = null,Object? checkedInAt = null,Object? checkedInBy = null,Object? crewCount = null,Object? crewNames = null,Object? safetyEquipmentVerified = null,Object? phrfRating = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,sailNumber: null == sailNumber ? _self.sailNumber : sailNumber // ignore: cast_nullable_to_non_nullable
as String,boatName: null == boatName ? _self.boatName : boatName // ignore: cast_nullable_to_non_nullable
as String,skipperName: null == skipperName ? _self.skipperName : skipperName // ignore: cast_nullable_to_non_nullable
as String,boatClass: null == boatClass ? _self.boatClass : boatClass // ignore: cast_nullable_to_non_nullable
as String,checkedInAt: null == checkedInAt ? _self.checkedInAt : checkedInAt // ignore: cast_nullable_to_non_nullable
as DateTime,checkedInBy: null == checkedInBy ? _self.checkedInBy : checkedInBy // ignore: cast_nullable_to_non_nullable
as String,crewCount: null == crewCount ? _self.crewCount : crewCount // ignore: cast_nullable_to_non_nullable
as int,crewNames: null == crewNames ? _self.crewNames : crewNames // ignore: cast_nullable_to_non_nullable
as List<String>,safetyEquipmentVerified: null == safetyEquipmentVerified ? _self.safetyEquipmentVerified : safetyEquipmentVerified // ignore: cast_nullable_to_non_nullable
as bool,phrfRating: freezed == phrfRating ? _self.phrfRating : phrfRating // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [BoatCheckin].
extension BoatCheckinPatterns on BoatCheckin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoatCheckin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoatCheckin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoatCheckin value)  $default,){
final _that = this;
switch (_that) {
case _BoatCheckin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoatCheckin value)?  $default,){
final _that = this;
switch (_that) {
case _BoatCheckin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventId,  String sailNumber,  String boatName,  String skipperName,  String boatClass,  DateTime checkedInAt,  String checkedInBy,  int crewCount,  List<String> crewNames,  bool safetyEquipmentVerified,  int? phrfRating)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoatCheckin() when $default != null:
return $default(_that.id,_that.eventId,_that.sailNumber,_that.boatName,_that.skipperName,_that.boatClass,_that.checkedInAt,_that.checkedInBy,_that.crewCount,_that.crewNames,_that.safetyEquipmentVerified,_that.phrfRating);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventId,  String sailNumber,  String boatName,  String skipperName,  String boatClass,  DateTime checkedInAt,  String checkedInBy,  int crewCount,  List<String> crewNames,  bool safetyEquipmentVerified,  int? phrfRating)  $default,) {final _that = this;
switch (_that) {
case _BoatCheckin():
return $default(_that.id,_that.eventId,_that.sailNumber,_that.boatName,_that.skipperName,_that.boatClass,_that.checkedInAt,_that.checkedInBy,_that.crewCount,_that.crewNames,_that.safetyEquipmentVerified,_that.phrfRating);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventId,  String sailNumber,  String boatName,  String skipperName,  String boatClass,  DateTime checkedInAt,  String checkedInBy,  int crewCount,  List<String> crewNames,  bool safetyEquipmentVerified,  int? phrfRating)?  $default,) {final _that = this;
switch (_that) {
case _BoatCheckin() when $default != null:
return $default(_that.id,_that.eventId,_that.sailNumber,_that.boatName,_that.skipperName,_that.boatClass,_that.checkedInAt,_that.checkedInBy,_that.crewCount,_that.crewNames,_that.safetyEquipmentVerified,_that.phrfRating);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BoatCheckin implements BoatCheckin {
  const _BoatCheckin({required this.id, required this.eventId, required this.sailNumber, required this.boatName, required this.skipperName, required this.boatClass, required this.checkedInAt, required this.checkedInBy, required this.crewCount, required final  List<String> crewNames, required this.safetyEquipmentVerified, this.phrfRating}): _crewNames = crewNames;
  factory _BoatCheckin.fromJson(Map<String, dynamic> json) => _$BoatCheckinFromJson(json);

@override final  String id;
@override final  String eventId;
@override final  String sailNumber;
@override final  String boatName;
@override final  String skipperName;
@override final  String boatClass;
@override final  DateTime checkedInAt;
@override final  String checkedInBy;
@override final  int crewCount;
 final  List<String> _crewNames;
@override List<String> get crewNames {
  if (_crewNames is EqualUnmodifiableListView) return _crewNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_crewNames);
}

@override final  bool safetyEquipmentVerified;
@override final  int? phrfRating;

/// Create a copy of BoatCheckin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoatCheckinCopyWith<_BoatCheckin> get copyWith => __$BoatCheckinCopyWithImpl<_BoatCheckin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BoatCheckinToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoatCheckin&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.sailNumber, sailNumber) || other.sailNumber == sailNumber)&&(identical(other.boatName, boatName) || other.boatName == boatName)&&(identical(other.skipperName, skipperName) || other.skipperName == skipperName)&&(identical(other.boatClass, boatClass) || other.boatClass == boatClass)&&(identical(other.checkedInAt, checkedInAt) || other.checkedInAt == checkedInAt)&&(identical(other.checkedInBy, checkedInBy) || other.checkedInBy == checkedInBy)&&(identical(other.crewCount, crewCount) || other.crewCount == crewCount)&&const DeepCollectionEquality().equals(other._crewNames, _crewNames)&&(identical(other.safetyEquipmentVerified, safetyEquipmentVerified) || other.safetyEquipmentVerified == safetyEquipmentVerified)&&(identical(other.phrfRating, phrfRating) || other.phrfRating == phrfRating));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,sailNumber,boatName,skipperName,boatClass,checkedInAt,checkedInBy,crewCount,const DeepCollectionEquality().hash(_crewNames),safetyEquipmentVerified,phrfRating);

@override
String toString() {
  return 'BoatCheckin(id: $id, eventId: $eventId, sailNumber: $sailNumber, boatName: $boatName, skipperName: $skipperName, boatClass: $boatClass, checkedInAt: $checkedInAt, checkedInBy: $checkedInBy, crewCount: $crewCount, crewNames: $crewNames, safetyEquipmentVerified: $safetyEquipmentVerified, phrfRating: $phrfRating)';
}


}

/// @nodoc
abstract mixin class _$BoatCheckinCopyWith<$Res> implements $BoatCheckinCopyWith<$Res> {
  factory _$BoatCheckinCopyWith(_BoatCheckin value, $Res Function(_BoatCheckin) _then) = __$BoatCheckinCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventId, String sailNumber, String boatName, String skipperName, String boatClass, DateTime checkedInAt, String checkedInBy, int crewCount, List<String> crewNames, bool safetyEquipmentVerified, int? phrfRating
});




}
/// @nodoc
class __$BoatCheckinCopyWithImpl<$Res>
    implements _$BoatCheckinCopyWith<$Res> {
  __$BoatCheckinCopyWithImpl(this._self, this._then);

  final _BoatCheckin _self;
  final $Res Function(_BoatCheckin) _then;

/// Create a copy of BoatCheckin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? sailNumber = null,Object? boatName = null,Object? skipperName = null,Object? boatClass = null,Object? checkedInAt = null,Object? checkedInBy = null,Object? crewCount = null,Object? crewNames = null,Object? safetyEquipmentVerified = null,Object? phrfRating = freezed,}) {
  return _then(_BoatCheckin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,sailNumber: null == sailNumber ? _self.sailNumber : sailNumber // ignore: cast_nullable_to_non_nullable
as String,boatName: null == boatName ? _self.boatName : boatName // ignore: cast_nullable_to_non_nullable
as String,skipperName: null == skipperName ? _self.skipperName : skipperName // ignore: cast_nullable_to_non_nullable
as String,boatClass: null == boatClass ? _self.boatClass : boatClass // ignore: cast_nullable_to_non_nullable
as String,checkedInAt: null == checkedInAt ? _self.checkedInAt : checkedInAt // ignore: cast_nullable_to_non_nullable
as DateTime,checkedInBy: null == checkedInBy ? _self.checkedInBy : checkedInBy // ignore: cast_nullable_to_non_nullable
as String,crewCount: null == crewCount ? _self.crewCount : crewCount // ignore: cast_nullable_to_non_nullable
as int,crewNames: null == crewNames ? _self._crewNames : crewNames // ignore: cast_nullable_to_non_nullable
as List<String>,safetyEquipmentVerified: null == safetyEquipmentVerified ? _self.safetyEquipmentVerified : safetyEquipmentVerified // ignore: cast_nullable_to_non_nullable
as bool,phrfRating: freezed == phrfRating ? _self.phrfRating : phrfRating // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
