// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'season_series.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SeasonSeries {

 String get id; String get name; DateTime get startDate; DateTime get endDate; int get dayOfWeek; String get color; bool get isActive;
/// Create a copy of SeasonSeries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeasonSeriesCopyWith<SeasonSeries> get copyWith => _$SeasonSeriesCopyWithImpl<SeasonSeries>(this as SeasonSeries, _$identity);

  /// Serializes this SeasonSeries to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeasonSeries&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.color, color) || other.color == color)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,startDate,endDate,dayOfWeek,color,isActive);

@override
String toString() {
  return 'SeasonSeries(id: $id, name: $name, startDate: $startDate, endDate: $endDate, dayOfWeek: $dayOfWeek, color: $color, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $SeasonSeriesCopyWith<$Res>  {
  factory $SeasonSeriesCopyWith(SeasonSeries value, $Res Function(SeasonSeries) _then) = _$SeasonSeriesCopyWithImpl;
@useResult
$Res call({
 String id, String name, DateTime startDate, DateTime endDate, int dayOfWeek, String color, bool isActive
});




}
/// @nodoc
class _$SeasonSeriesCopyWithImpl<$Res>
    implements $SeasonSeriesCopyWith<$Res> {
  _$SeasonSeriesCopyWithImpl(this._self, this._then);

  final SeasonSeries _self;
  final $Res Function(SeasonSeries) _then;

/// Create a copy of SeasonSeries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? startDate = null,Object? endDate = null,Object? dayOfWeek = null,Object? color = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SeasonSeries].
extension SeasonSeriesPatterns on SeasonSeries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeasonSeries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeasonSeries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeasonSeries value)  $default,){
final _that = this;
switch (_that) {
case _SeasonSeries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeasonSeries value)?  $default,){
final _that = this;
switch (_that) {
case _SeasonSeries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  DateTime startDate,  DateTime endDate,  int dayOfWeek,  String color,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeasonSeries() when $default != null:
return $default(_that.id,_that.name,_that.startDate,_that.endDate,_that.dayOfWeek,_that.color,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  DateTime startDate,  DateTime endDate,  int dayOfWeek,  String color,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _SeasonSeries():
return $default(_that.id,_that.name,_that.startDate,_that.endDate,_that.dayOfWeek,_that.color,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  DateTime startDate,  DateTime endDate,  int dayOfWeek,  String color,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _SeasonSeries() when $default != null:
return $default(_that.id,_that.name,_that.startDate,_that.endDate,_that.dayOfWeek,_that.color,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeasonSeries implements SeasonSeries {
  const _SeasonSeries({required this.id, required this.name, required this.startDate, required this.endDate, required this.dayOfWeek, required this.color, required this.isActive});
  factory _SeasonSeries.fromJson(Map<String, dynamic> json) => _$SeasonSeriesFromJson(json);

@override final  String id;
@override final  String name;
@override final  DateTime startDate;
@override final  DateTime endDate;
@override final  int dayOfWeek;
@override final  String color;
@override final  bool isActive;

/// Create a copy of SeasonSeries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeasonSeriesCopyWith<_SeasonSeries> get copyWith => __$SeasonSeriesCopyWithImpl<_SeasonSeries>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeasonSeriesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeasonSeries&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.color, color) || other.color == color)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,startDate,endDate,dayOfWeek,color,isActive);

@override
String toString() {
  return 'SeasonSeries(id: $id, name: $name, startDate: $startDate, endDate: $endDate, dayOfWeek: $dayOfWeek, color: $color, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$SeasonSeriesCopyWith<$Res> implements $SeasonSeriesCopyWith<$Res> {
  factory _$SeasonSeriesCopyWith(_SeasonSeries value, $Res Function(_SeasonSeries) _then) = __$SeasonSeriesCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, DateTime startDate, DateTime endDate, int dayOfWeek, String color, bool isActive
});




}
/// @nodoc
class __$SeasonSeriesCopyWithImpl<$Res>
    implements _$SeasonSeriesCopyWith<$Res> {
  __$SeasonSeriesCopyWithImpl(this._self, this._then);

  final _SeasonSeries _self;
  final $Res Function(_SeasonSeries) _then;

/// Create a copy of SeasonSeries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? startDate = null,Object? endDate = null,Object? dayOfWeek = null,Object? color = null,Object? isActive = null,}) {
  return _then(_SeasonSeries(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
