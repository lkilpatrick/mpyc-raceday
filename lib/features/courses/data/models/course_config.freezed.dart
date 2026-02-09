// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CourseMark {

 String get name; int get order; MarkRounding get rounding;
/// Create a copy of CourseMark
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseMarkCopyWith<CourseMark> get copyWith => _$CourseMarkCopyWithImpl<CourseMark>(this as CourseMark, _$identity);

  /// Serializes this CourseMark to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseMark&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&(identical(other.rounding, rounding) || other.rounding == rounding));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,order,rounding);

@override
String toString() {
  return 'CourseMark(name: $name, order: $order, rounding: $rounding)';
}


}

/// @nodoc
abstract mixin class $CourseMarkCopyWith<$Res>  {
  factory $CourseMarkCopyWith(CourseMark value, $Res Function(CourseMark) _then) = _$CourseMarkCopyWithImpl;
@useResult
$Res call({
 String name, int order, MarkRounding rounding
});




}
/// @nodoc
class _$CourseMarkCopyWithImpl<$Res>
    implements $CourseMarkCopyWith<$Res> {
  _$CourseMarkCopyWithImpl(this._self, this._then);

  final CourseMark _self;
  final $Res Function(CourseMark) _then;

/// Create a copy of CourseMark
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? order = null,Object? rounding = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,rounding: null == rounding ? _self.rounding : rounding // ignore: cast_nullable_to_non_nullable
as MarkRounding,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseMark].
extension CourseMarkPatterns on CourseMark {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseMark value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseMark() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseMark value)  $default,){
final _that = this;
switch (_that) {
case _CourseMark():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseMark value)?  $default,){
final _that = this;
switch (_that) {
case _CourseMark() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int order,  MarkRounding rounding)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseMark() when $default != null:
return $default(_that.name,_that.order,_that.rounding);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int order,  MarkRounding rounding)  $default,) {final _that = this;
switch (_that) {
case _CourseMark():
return $default(_that.name,_that.order,_that.rounding);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int order,  MarkRounding rounding)?  $default,) {final _that = this;
switch (_that) {
case _CourseMark() when $default != null:
return $default(_that.name,_that.order,_that.rounding);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseMark implements CourseMark {
  const _CourseMark({required this.name, required this.order, required this.rounding});
  factory _CourseMark.fromJson(Map<String, dynamic> json) => _$CourseMarkFromJson(json);

@override final  String name;
@override final  int order;
@override final  MarkRounding rounding;

/// Create a copy of CourseMark
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseMarkCopyWith<_CourseMark> get copyWith => __$CourseMarkCopyWithImpl<_CourseMark>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseMarkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseMark&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&(identical(other.rounding, rounding) || other.rounding == rounding));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,order,rounding);

@override
String toString() {
  return 'CourseMark(name: $name, order: $order, rounding: $rounding)';
}


}

/// @nodoc
abstract mixin class _$CourseMarkCopyWith<$Res> implements $CourseMarkCopyWith<$Res> {
  factory _$CourseMarkCopyWith(_CourseMark value, $Res Function(_CourseMark) _then) = __$CourseMarkCopyWithImpl;
@override @useResult
$Res call({
 String name, int order, MarkRounding rounding
});




}
/// @nodoc
class __$CourseMarkCopyWithImpl<$Res>
    implements _$CourseMarkCopyWith<$Res> {
  __$CourseMarkCopyWithImpl(this._self, this._then);

  final _CourseMark _self;
  final $Res Function(_CourseMark) _then;

/// Create a copy of CourseMark
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? order = null,Object? rounding = null,}) {
  return _then(_CourseMark(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,rounding: null == rounding ? _self.rounding : rounding // ignore: cast_nullable_to_non_nullable
as MarkRounding,
  ));
}


}


/// @nodoc
mixin _$CourseConfig {

 String get id; String get courseName; String get courseNumber; String get description; String? get diagramUrl; List<CourseMark> get marks; double? get distanceNm; int get windRangeMin; int get windRangeMax; double get windSpeedMin; double get windSpeedMax; bool get isActive; String get notes;
/// Create a copy of CourseConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseConfigCopyWith<CourseConfig> get copyWith => _$CourseConfigCopyWithImpl<CourseConfig>(this as CourseConfig, _$identity);

  /// Serializes this CourseConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.courseName, courseName) || other.courseName == courseName)&&(identical(other.courseNumber, courseNumber) || other.courseNumber == courseNumber)&&(identical(other.description, description) || other.description == description)&&(identical(other.diagramUrl, diagramUrl) || other.diagramUrl == diagramUrl)&&const DeepCollectionEquality().equals(other.marks, marks)&&(identical(other.distanceNm, distanceNm) || other.distanceNm == distanceNm)&&(identical(other.windRangeMin, windRangeMin) || other.windRangeMin == windRangeMin)&&(identical(other.windRangeMax, windRangeMax) || other.windRangeMax == windRangeMax)&&(identical(other.windSpeedMin, windSpeedMin) || other.windSpeedMin == windSpeedMin)&&(identical(other.windSpeedMax, windSpeedMax) || other.windSpeedMax == windSpeedMax)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courseName,courseNumber,description,diagramUrl,const DeepCollectionEquality().hash(marks),distanceNm,windRangeMin,windRangeMax,windSpeedMin,windSpeedMax,isActive,notes);

@override
String toString() {
  return 'CourseConfig(id: $id, courseName: $courseName, courseNumber: $courseNumber, description: $description, diagramUrl: $diagramUrl, marks: $marks, distanceNm: $distanceNm, windRangeMin: $windRangeMin, windRangeMax: $windRangeMax, windSpeedMin: $windSpeedMin, windSpeedMax: $windSpeedMax, isActive: $isActive, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $CourseConfigCopyWith<$Res>  {
  factory $CourseConfigCopyWith(CourseConfig value, $Res Function(CourseConfig) _then) = _$CourseConfigCopyWithImpl;
@useResult
$Res call({
 String id, String courseName, String courseNumber, String description, String? diagramUrl, List<CourseMark> marks, double? distanceNm, int windRangeMin, int windRangeMax, double windSpeedMin, double windSpeedMax, bool isActive, String notes
});




}
/// @nodoc
class _$CourseConfigCopyWithImpl<$Res>
    implements $CourseConfigCopyWith<$Res> {
  _$CourseConfigCopyWithImpl(this._self, this._then);

  final CourseConfig _self;
  final $Res Function(CourseConfig) _then;

/// Create a copy of CourseConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? courseName = null,Object? courseNumber = null,Object? description = null,Object? diagramUrl = freezed,Object? marks = null,Object? distanceNm = freezed,Object? windRangeMin = null,Object? windRangeMax = null,Object? windSpeedMin = null,Object? windSpeedMax = null,Object? isActive = null,Object? notes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseName: null == courseName ? _self.courseName : courseName // ignore: cast_nullable_to_non_nullable
as String,courseNumber: null == courseNumber ? _self.courseNumber : courseNumber // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,diagramUrl: freezed == diagramUrl ? _self.diagramUrl : diagramUrl // ignore: cast_nullable_to_non_nullable
as String?,marks: null == marks ? _self.marks : marks // ignore: cast_nullable_to_non_nullable
as List<CourseMark>,distanceNm: freezed == distanceNm ? _self.distanceNm : distanceNm // ignore: cast_nullable_to_non_nullable
as double?,windRangeMin: null == windRangeMin ? _self.windRangeMin : windRangeMin // ignore: cast_nullable_to_non_nullable
as int,windRangeMax: null == windRangeMax ? _self.windRangeMax : windRangeMax // ignore: cast_nullable_to_non_nullable
as int,windSpeedMin: null == windSpeedMin ? _self.windSpeedMin : windSpeedMin // ignore: cast_nullable_to_non_nullable
as double,windSpeedMax: null == windSpeedMax ? _self.windSpeedMax : windSpeedMax // ignore: cast_nullable_to_non_nullable
as double,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseConfig].
extension CourseConfigPatterns on CourseConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseConfig value)  $default,){
final _that = this;
switch (_that) {
case _CourseConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseConfig value)?  $default,){
final _that = this;
switch (_that) {
case _CourseConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String courseName,  String courseNumber,  String description,  String? diagramUrl,  List<CourseMark> marks,  double? distanceNm,  int windRangeMin,  int windRangeMax,  double windSpeedMin,  double windSpeedMax,  bool isActive,  String notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseConfig() when $default != null:
return $default(_that.id,_that.courseName,_that.courseNumber,_that.description,_that.diagramUrl,_that.marks,_that.distanceNm,_that.windRangeMin,_that.windRangeMax,_that.windSpeedMin,_that.windSpeedMax,_that.isActive,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String courseName,  String courseNumber,  String description,  String? diagramUrl,  List<CourseMark> marks,  double? distanceNm,  int windRangeMin,  int windRangeMax,  double windSpeedMin,  double windSpeedMax,  bool isActive,  String notes)  $default,) {final _that = this;
switch (_that) {
case _CourseConfig():
return $default(_that.id,_that.courseName,_that.courseNumber,_that.description,_that.diagramUrl,_that.marks,_that.distanceNm,_that.windRangeMin,_that.windRangeMax,_that.windSpeedMin,_that.windSpeedMax,_that.isActive,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String courseName,  String courseNumber,  String description,  String? diagramUrl,  List<CourseMark> marks,  double? distanceNm,  int windRangeMin,  int windRangeMax,  double windSpeedMin,  double windSpeedMax,  bool isActive,  String notes)?  $default,) {final _that = this;
switch (_that) {
case _CourseConfig() when $default != null:
return $default(_that.id,_that.courseName,_that.courseNumber,_that.description,_that.diagramUrl,_that.marks,_that.distanceNm,_that.windRangeMin,_that.windRangeMax,_that.windSpeedMin,_that.windSpeedMax,_that.isActive,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseConfig implements CourseConfig {
  const _CourseConfig({required this.id, required this.courseName, required this.courseNumber, required this.description, this.diagramUrl, required final  List<CourseMark> marks, this.distanceNm, required this.windRangeMin, required this.windRangeMax, required this.windSpeedMin, required this.windSpeedMax, required this.isActive, required this.notes}): _marks = marks;
  factory _CourseConfig.fromJson(Map<String, dynamic> json) => _$CourseConfigFromJson(json);

@override final  String id;
@override final  String courseName;
@override final  String courseNumber;
@override final  String description;
@override final  String? diagramUrl;
 final  List<CourseMark> _marks;
@override List<CourseMark> get marks {
  if (_marks is EqualUnmodifiableListView) return _marks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_marks);
}

@override final  double? distanceNm;
@override final  int windRangeMin;
@override final  int windRangeMax;
@override final  double windSpeedMin;
@override final  double windSpeedMax;
@override final  bool isActive;
@override final  String notes;

/// Create a copy of CourseConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseConfigCopyWith<_CourseConfig> get copyWith => __$CourseConfigCopyWithImpl<_CourseConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.courseName, courseName) || other.courseName == courseName)&&(identical(other.courseNumber, courseNumber) || other.courseNumber == courseNumber)&&(identical(other.description, description) || other.description == description)&&(identical(other.diagramUrl, diagramUrl) || other.diagramUrl == diagramUrl)&&const DeepCollectionEquality().equals(other._marks, _marks)&&(identical(other.distanceNm, distanceNm) || other.distanceNm == distanceNm)&&(identical(other.windRangeMin, windRangeMin) || other.windRangeMin == windRangeMin)&&(identical(other.windRangeMax, windRangeMax) || other.windRangeMax == windRangeMax)&&(identical(other.windSpeedMin, windSpeedMin) || other.windSpeedMin == windSpeedMin)&&(identical(other.windSpeedMax, windSpeedMax) || other.windSpeedMax == windSpeedMax)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courseName,courseNumber,description,diagramUrl,const DeepCollectionEquality().hash(_marks),distanceNm,windRangeMin,windRangeMax,windSpeedMin,windSpeedMax,isActive,notes);

@override
String toString() {
  return 'CourseConfig(id: $id, courseName: $courseName, courseNumber: $courseNumber, description: $description, diagramUrl: $diagramUrl, marks: $marks, distanceNm: $distanceNm, windRangeMin: $windRangeMin, windRangeMax: $windRangeMax, windSpeedMin: $windSpeedMin, windSpeedMax: $windSpeedMax, isActive: $isActive, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$CourseConfigCopyWith<$Res> implements $CourseConfigCopyWith<$Res> {
  factory _$CourseConfigCopyWith(_CourseConfig value, $Res Function(_CourseConfig) _then) = __$CourseConfigCopyWithImpl;
@override @useResult
$Res call({
 String id, String courseName, String courseNumber, String description, String? diagramUrl, List<CourseMark> marks, double? distanceNm, int windRangeMin, int windRangeMax, double windSpeedMin, double windSpeedMax, bool isActive, String notes
});




}
/// @nodoc
class __$CourseConfigCopyWithImpl<$Res>
    implements _$CourseConfigCopyWith<$Res> {
  __$CourseConfigCopyWithImpl(this._self, this._then);

  final _CourseConfig _self;
  final $Res Function(_CourseConfig) _then;

/// Create a copy of CourseConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? courseName = null,Object? courseNumber = null,Object? description = null,Object? diagramUrl = freezed,Object? marks = null,Object? distanceNm = freezed,Object? windRangeMin = null,Object? windRangeMax = null,Object? windSpeedMin = null,Object? windSpeedMax = null,Object? isActive = null,Object? notes = null,}) {
  return _then(_CourseConfig(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseName: null == courseName ? _self.courseName : courseName // ignore: cast_nullable_to_non_nullable
as String,courseNumber: null == courseNumber ? _self.courseNumber : courseNumber // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,diagramUrl: freezed == diagramUrl ? _self.diagramUrl : diagramUrl // ignore: cast_nullable_to_non_nullable
as String?,marks: null == marks ? _self._marks : marks // ignore: cast_nullable_to_non_nullable
as List<CourseMark>,distanceNm: freezed == distanceNm ? _self.distanceNm : distanceNm // ignore: cast_nullable_to_non_nullable
as double?,windRangeMin: null == windRangeMin ? _self.windRangeMin : windRangeMin // ignore: cast_nullable_to_non_nullable
as int,windRangeMax: null == windRangeMax ? _self.windRangeMax : windRangeMax // ignore: cast_nullable_to_non_nullable
as int,windSpeedMin: null == windSpeedMin ? _self.windSpeedMin : windSpeedMin // ignore: cast_nullable_to_non_nullable
as double,windSpeedMax: null == windSpeedMax ? _self.windSpeedMax : windSpeedMax // ignore: cast_nullable_to_non_nullable
as double,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
