// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checklist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChecklistItem {

 String get id; String get title; String get description; String get category; bool get requiresPhoto; bool get requiresNote; bool get isCritical; int get order;
/// Create a copy of ChecklistItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChecklistItemCopyWith<ChecklistItem> get copyWith => _$ChecklistItemCopyWithImpl<ChecklistItem>(this as ChecklistItem, _$identity);

  /// Serializes this ChecklistItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChecklistItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.requiresPhoto, requiresPhoto) || other.requiresPhoto == requiresPhoto)&&(identical(other.requiresNote, requiresNote) || other.requiresNote == requiresNote)&&(identical(other.isCritical, isCritical) || other.isCritical == isCritical)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,category,requiresPhoto,requiresNote,isCritical,order);

@override
String toString() {
  return 'ChecklistItem(id: $id, title: $title, description: $description, category: $category, requiresPhoto: $requiresPhoto, requiresNote: $requiresNote, isCritical: $isCritical, order: $order)';
}


}

/// @nodoc
abstract mixin class $ChecklistItemCopyWith<$Res>  {
  factory $ChecklistItemCopyWith(ChecklistItem value, $Res Function(ChecklistItem) _then) = _$ChecklistItemCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String category, bool requiresPhoto, bool requiresNote, bool isCritical, int order
});




}
/// @nodoc
class _$ChecklistItemCopyWithImpl<$Res>
    implements $ChecklistItemCopyWith<$Res> {
  _$ChecklistItemCopyWithImpl(this._self, this._then);

  final ChecklistItem _self;
  final $Res Function(ChecklistItem) _then;

/// Create a copy of ChecklistItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = null,Object? requiresPhoto = null,Object? requiresNote = null,Object? isCritical = null,Object? order = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,requiresPhoto: null == requiresPhoto ? _self.requiresPhoto : requiresPhoto // ignore: cast_nullable_to_non_nullable
as bool,requiresNote: null == requiresNote ? _self.requiresNote : requiresNote // ignore: cast_nullable_to_non_nullable
as bool,isCritical: null == isCritical ? _self.isCritical : isCritical // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChecklistItem].
extension ChecklistItemPatterns on ChecklistItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChecklistItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChecklistItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChecklistItem value)  $default,){
final _that = this;
switch (_that) {
case _ChecklistItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChecklistItem value)?  $default,){
final _that = this;
switch (_that) {
case _ChecklistItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String category,  bool requiresPhoto,  bool requiresNote,  bool isCritical,  int order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChecklistItem() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.requiresPhoto,_that.requiresNote,_that.isCritical,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String category,  bool requiresPhoto,  bool requiresNote,  bool isCritical,  int order)  $default,) {final _that = this;
switch (_that) {
case _ChecklistItem():
return $default(_that.id,_that.title,_that.description,_that.category,_that.requiresPhoto,_that.requiresNote,_that.isCritical,_that.order);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String category,  bool requiresPhoto,  bool requiresNote,  bool isCritical,  int order)?  $default,) {final _that = this;
switch (_that) {
case _ChecklistItem() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.requiresPhoto,_that.requiresNote,_that.isCritical,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChecklistItem implements ChecklistItem {
  const _ChecklistItem({required this.id, required this.title, required this.description, required this.category, required this.requiresPhoto, required this.requiresNote, required this.isCritical, required this.order});
  factory _ChecklistItem.fromJson(Map<String, dynamic> json) => _$ChecklistItemFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  String category;
@override final  bool requiresPhoto;
@override final  bool requiresNote;
@override final  bool isCritical;
@override final  int order;

/// Create a copy of ChecklistItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChecklistItemCopyWith<_ChecklistItem> get copyWith => __$ChecklistItemCopyWithImpl<_ChecklistItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChecklistItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChecklistItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.requiresPhoto, requiresPhoto) || other.requiresPhoto == requiresPhoto)&&(identical(other.requiresNote, requiresNote) || other.requiresNote == requiresNote)&&(identical(other.isCritical, isCritical) || other.isCritical == isCritical)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,category,requiresPhoto,requiresNote,isCritical,order);

@override
String toString() {
  return 'ChecklistItem(id: $id, title: $title, description: $description, category: $category, requiresPhoto: $requiresPhoto, requiresNote: $requiresNote, isCritical: $isCritical, order: $order)';
}


}

/// @nodoc
abstract mixin class _$ChecklistItemCopyWith<$Res> implements $ChecklistItemCopyWith<$Res> {
  factory _$ChecklistItemCopyWith(_ChecklistItem value, $Res Function(_ChecklistItem) _then) = __$ChecklistItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String category, bool requiresPhoto, bool requiresNote, bool isCritical, int order
});




}
/// @nodoc
class __$ChecklistItemCopyWithImpl<$Res>
    implements _$ChecklistItemCopyWith<$Res> {
  __$ChecklistItemCopyWithImpl(this._self, this._then);

  final _ChecklistItem _self;
  final $Res Function(_ChecklistItem) _then;

/// Create a copy of ChecklistItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = null,Object? requiresPhoto = null,Object? requiresNote = null,Object? isCritical = null,Object? order = null,}) {
  return _then(_ChecklistItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,requiresPhoto: null == requiresPhoto ? _self.requiresPhoto : requiresPhoto // ignore: cast_nullable_to_non_nullable
as bool,requiresNote: null == requiresNote ? _self.requiresNote : requiresNote // ignore: cast_nullable_to_non_nullable
as bool,isCritical: null == isCritical ? _self.isCritical : isCritical // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Checklist {

 String get id; String get name; ChecklistType get type; List<ChecklistItem> get items; int get version; String get lastModifiedBy; DateTime get lastModifiedAt; bool get isActive;
/// Create a copy of Checklist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChecklistCopyWith<Checklist> get copyWith => _$ChecklistCopyWithImpl<Checklist>(this as Checklist, _$identity);

  /// Serializes this Checklist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Checklist&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.version, version) || other.version == version)&&(identical(other.lastModifiedBy, lastModifiedBy) || other.lastModifiedBy == lastModifiedBy)&&(identical(other.lastModifiedAt, lastModifiedAt) || other.lastModifiedAt == lastModifiedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,const DeepCollectionEquality().hash(items),version,lastModifiedBy,lastModifiedAt,isActive);

@override
String toString() {
  return 'Checklist(id: $id, name: $name, type: $type, items: $items, version: $version, lastModifiedBy: $lastModifiedBy, lastModifiedAt: $lastModifiedAt, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $ChecklistCopyWith<$Res>  {
  factory $ChecklistCopyWith(Checklist value, $Res Function(Checklist) _then) = _$ChecklistCopyWithImpl;
@useResult
$Res call({
 String id, String name, ChecklistType type, List<ChecklistItem> items, int version, String lastModifiedBy, DateTime lastModifiedAt, bool isActive
});




}
/// @nodoc
class _$ChecklistCopyWithImpl<$Res>
    implements $ChecklistCopyWith<$Res> {
  _$ChecklistCopyWithImpl(this._self, this._then);

  final Checklist _self;
  final $Res Function(Checklist) _then;

/// Create a copy of Checklist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? items = null,Object? version = null,Object? lastModifiedBy = null,Object? lastModifiedAt = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ChecklistType,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ChecklistItem>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,lastModifiedBy: null == lastModifiedBy ? _self.lastModifiedBy : lastModifiedBy // ignore: cast_nullable_to_non_nullable
as String,lastModifiedAt: null == lastModifiedAt ? _self.lastModifiedAt : lastModifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Checklist].
extension ChecklistPatterns on Checklist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Checklist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Checklist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Checklist value)  $default,){
final _that = this;
switch (_that) {
case _Checklist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Checklist value)?  $default,){
final _that = this;
switch (_that) {
case _Checklist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  ChecklistType type,  List<ChecklistItem> items,  int version,  String lastModifiedBy,  DateTime lastModifiedAt,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Checklist() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.items,_that.version,_that.lastModifiedBy,_that.lastModifiedAt,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  ChecklistType type,  List<ChecklistItem> items,  int version,  String lastModifiedBy,  DateTime lastModifiedAt,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _Checklist():
return $default(_that.id,_that.name,_that.type,_that.items,_that.version,_that.lastModifiedBy,_that.lastModifiedAt,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  ChecklistType type,  List<ChecklistItem> items,  int version,  String lastModifiedBy,  DateTime lastModifiedAt,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _Checklist() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.items,_that.version,_that.lastModifiedBy,_that.lastModifiedAt,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Checklist implements Checklist {
  const _Checklist({required this.id, required this.name, required this.type, required final  List<ChecklistItem> items, required this.version, required this.lastModifiedBy, required this.lastModifiedAt, required this.isActive}): _items = items;
  factory _Checklist.fromJson(Map<String, dynamic> json) => _$ChecklistFromJson(json);

@override final  String id;
@override final  String name;
@override final  ChecklistType type;
 final  List<ChecklistItem> _items;
@override List<ChecklistItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int version;
@override final  String lastModifiedBy;
@override final  DateTime lastModifiedAt;
@override final  bool isActive;

/// Create a copy of Checklist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChecklistCopyWith<_Checklist> get copyWith => __$ChecklistCopyWithImpl<_Checklist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChecklistToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Checklist&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.version, version) || other.version == version)&&(identical(other.lastModifiedBy, lastModifiedBy) || other.lastModifiedBy == lastModifiedBy)&&(identical(other.lastModifiedAt, lastModifiedAt) || other.lastModifiedAt == lastModifiedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,const DeepCollectionEquality().hash(_items),version,lastModifiedBy,lastModifiedAt,isActive);

@override
String toString() {
  return 'Checklist(id: $id, name: $name, type: $type, items: $items, version: $version, lastModifiedBy: $lastModifiedBy, lastModifiedAt: $lastModifiedAt, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$ChecklistCopyWith<$Res> implements $ChecklistCopyWith<$Res> {
  factory _$ChecklistCopyWith(_Checklist value, $Res Function(_Checklist) _then) = __$ChecklistCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, ChecklistType type, List<ChecklistItem> items, int version, String lastModifiedBy, DateTime lastModifiedAt, bool isActive
});




}
/// @nodoc
class __$ChecklistCopyWithImpl<$Res>
    implements _$ChecklistCopyWith<$Res> {
  __$ChecklistCopyWithImpl(this._self, this._then);

  final _Checklist _self;
  final $Res Function(_Checklist) _then;

/// Create a copy of Checklist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? items = null,Object? version = null,Object? lastModifiedBy = null,Object? lastModifiedAt = null,Object? isActive = null,}) {
  return _then(_Checklist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ChecklistType,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ChecklistItem>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,lastModifiedBy: null == lastModifiedBy ? _self.lastModifiedBy : lastModifiedBy // ignore: cast_nullable_to_non_nullable
as String,lastModifiedAt: null == lastModifiedAt ? _self.lastModifiedAt : lastModifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$CompletedItem {

 String get itemId; bool get checked; String? get note; String? get photoUrl; DateTime get timestamp;
/// Create a copy of CompletedItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompletedItemCopyWith<CompletedItem> get copyWith => _$CompletedItemCopyWithImpl<CompletedItem>(this as CompletedItem, _$identity);

  /// Serializes this CompletedItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletedItem&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.checked, checked) || other.checked == checked)&&(identical(other.note, note) || other.note == note)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,checked,note,photoUrl,timestamp);

@override
String toString() {
  return 'CompletedItem(itemId: $itemId, checked: $checked, note: $note, photoUrl: $photoUrl, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $CompletedItemCopyWith<$Res>  {
  factory $CompletedItemCopyWith(CompletedItem value, $Res Function(CompletedItem) _then) = _$CompletedItemCopyWithImpl;
@useResult
$Res call({
 String itemId, bool checked, String? note, String? photoUrl, DateTime timestamp
});




}
/// @nodoc
class _$CompletedItemCopyWithImpl<$Res>
    implements $CompletedItemCopyWith<$Res> {
  _$CompletedItemCopyWithImpl(this._self, this._then);

  final CompletedItem _self;
  final $Res Function(CompletedItem) _then;

/// Create a copy of CompletedItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? checked = null,Object? note = freezed,Object? photoUrl = freezed,Object? timestamp = null,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,checked: null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CompletedItem].
extension CompletedItemPatterns on CompletedItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompletedItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompletedItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompletedItem value)  $default,){
final _that = this;
switch (_that) {
case _CompletedItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompletedItem value)?  $default,){
final _that = this;
switch (_that) {
case _CompletedItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  bool checked,  String? note,  String? photoUrl,  DateTime timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompletedItem() when $default != null:
return $default(_that.itemId,_that.checked,_that.note,_that.photoUrl,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  bool checked,  String? note,  String? photoUrl,  DateTime timestamp)  $default,) {final _that = this;
switch (_that) {
case _CompletedItem():
return $default(_that.itemId,_that.checked,_that.note,_that.photoUrl,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  bool checked,  String? note,  String? photoUrl,  DateTime timestamp)?  $default,) {final _that = this;
switch (_that) {
case _CompletedItem() when $default != null:
return $default(_that.itemId,_that.checked,_that.note,_that.photoUrl,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompletedItem implements CompletedItem {
  const _CompletedItem({required this.itemId, required this.checked, this.note, this.photoUrl, required this.timestamp});
  factory _CompletedItem.fromJson(Map<String, dynamic> json) => _$CompletedItemFromJson(json);

@override final  String itemId;
@override final  bool checked;
@override final  String? note;
@override final  String? photoUrl;
@override final  DateTime timestamp;

/// Create a copy of CompletedItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompletedItemCopyWith<_CompletedItem> get copyWith => __$CompletedItemCopyWithImpl<_CompletedItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompletedItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompletedItem&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.checked, checked) || other.checked == checked)&&(identical(other.note, note) || other.note == note)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,checked,note,photoUrl,timestamp);

@override
String toString() {
  return 'CompletedItem(itemId: $itemId, checked: $checked, note: $note, photoUrl: $photoUrl, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$CompletedItemCopyWith<$Res> implements $CompletedItemCopyWith<$Res> {
  factory _$CompletedItemCopyWith(_CompletedItem value, $Res Function(_CompletedItem) _then) = __$CompletedItemCopyWithImpl;
@override @useResult
$Res call({
 String itemId, bool checked, String? note, String? photoUrl, DateTime timestamp
});




}
/// @nodoc
class __$CompletedItemCopyWithImpl<$Res>
    implements _$CompletedItemCopyWith<$Res> {
  __$CompletedItemCopyWithImpl(this._self, this._then);

  final _CompletedItem _self;
  final $Res Function(_CompletedItem) _then;

/// Create a copy of CompletedItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? checked = null,Object? note = freezed,Object? photoUrl = freezed,Object? timestamp = null,}) {
  return _then(_CompletedItem(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,checked: null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$ChecklistCompletion {

 String get id; String get checklistId; String get eventId; String get completedBy; DateTime get startedAt; DateTime? get completedAt; List<CompletedItem> get items; String? get signOffBy; DateTime? get signOffAt; ChecklistCompletionStatus get status;
/// Create a copy of ChecklistCompletion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChecklistCompletionCopyWith<ChecklistCompletion> get copyWith => _$ChecklistCompletionCopyWithImpl<ChecklistCompletion>(this as ChecklistCompletion, _$identity);

  /// Serializes this ChecklistCompletion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChecklistCompletion&&(identical(other.id, id) || other.id == id)&&(identical(other.checklistId, checklistId) || other.checklistId == checklistId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.completedBy, completedBy) || other.completedBy == completedBy)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.signOffBy, signOffBy) || other.signOffBy == signOffBy)&&(identical(other.signOffAt, signOffAt) || other.signOffAt == signOffAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,checklistId,eventId,completedBy,startedAt,completedAt,const DeepCollectionEquality().hash(items),signOffBy,signOffAt,status);

@override
String toString() {
  return 'ChecklistCompletion(id: $id, checklistId: $checklistId, eventId: $eventId, completedBy: $completedBy, startedAt: $startedAt, completedAt: $completedAt, items: $items, signOffBy: $signOffBy, signOffAt: $signOffAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $ChecklistCompletionCopyWith<$Res>  {
  factory $ChecklistCompletionCopyWith(ChecklistCompletion value, $Res Function(ChecklistCompletion) _then) = _$ChecklistCompletionCopyWithImpl;
@useResult
$Res call({
 String id, String checklistId, String eventId, String completedBy, DateTime startedAt, DateTime? completedAt, List<CompletedItem> items, String? signOffBy, DateTime? signOffAt, ChecklistCompletionStatus status
});




}
/// @nodoc
class _$ChecklistCompletionCopyWithImpl<$Res>
    implements $ChecklistCompletionCopyWith<$Res> {
  _$ChecklistCompletionCopyWithImpl(this._self, this._then);

  final ChecklistCompletion _self;
  final $Res Function(ChecklistCompletion) _then;

/// Create a copy of ChecklistCompletion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? checklistId = null,Object? eventId = null,Object? completedBy = null,Object? startedAt = null,Object? completedAt = freezed,Object? items = null,Object? signOffBy = freezed,Object? signOffAt = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,checklistId: null == checklistId ? _self.checklistId : checklistId // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,completedBy: null == completedBy ? _self.completedBy : completedBy // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CompletedItem>,signOffBy: freezed == signOffBy ? _self.signOffBy : signOffBy // ignore: cast_nullable_to_non_nullable
as String?,signOffAt: freezed == signOffAt ? _self.signOffAt : signOffAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ChecklistCompletionStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [ChecklistCompletion].
extension ChecklistCompletionPatterns on ChecklistCompletion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChecklistCompletion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChecklistCompletion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChecklistCompletion value)  $default,){
final _that = this;
switch (_that) {
case _ChecklistCompletion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChecklistCompletion value)?  $default,){
final _that = this;
switch (_that) {
case _ChecklistCompletion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String checklistId,  String eventId,  String completedBy,  DateTime startedAt,  DateTime? completedAt,  List<CompletedItem> items,  String? signOffBy,  DateTime? signOffAt,  ChecklistCompletionStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChecklistCompletion() when $default != null:
return $default(_that.id,_that.checklistId,_that.eventId,_that.completedBy,_that.startedAt,_that.completedAt,_that.items,_that.signOffBy,_that.signOffAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String checklistId,  String eventId,  String completedBy,  DateTime startedAt,  DateTime? completedAt,  List<CompletedItem> items,  String? signOffBy,  DateTime? signOffAt,  ChecklistCompletionStatus status)  $default,) {final _that = this;
switch (_that) {
case _ChecklistCompletion():
return $default(_that.id,_that.checklistId,_that.eventId,_that.completedBy,_that.startedAt,_that.completedAt,_that.items,_that.signOffBy,_that.signOffAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String checklistId,  String eventId,  String completedBy,  DateTime startedAt,  DateTime? completedAt,  List<CompletedItem> items,  String? signOffBy,  DateTime? signOffAt,  ChecklistCompletionStatus status)?  $default,) {final _that = this;
switch (_that) {
case _ChecklistCompletion() when $default != null:
return $default(_that.id,_that.checklistId,_that.eventId,_that.completedBy,_that.startedAt,_that.completedAt,_that.items,_that.signOffBy,_that.signOffAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChecklistCompletion implements ChecklistCompletion {
  const _ChecklistCompletion({required this.id, required this.checklistId, required this.eventId, required this.completedBy, required this.startedAt, this.completedAt, required final  List<CompletedItem> items, this.signOffBy, this.signOffAt, required this.status}): _items = items;
  factory _ChecklistCompletion.fromJson(Map<String, dynamic> json) => _$ChecklistCompletionFromJson(json);

@override final  String id;
@override final  String checklistId;
@override final  String eventId;
@override final  String completedBy;
@override final  DateTime startedAt;
@override final  DateTime? completedAt;
 final  List<CompletedItem> _items;
@override List<CompletedItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? signOffBy;
@override final  DateTime? signOffAt;
@override final  ChecklistCompletionStatus status;

/// Create a copy of ChecklistCompletion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChecklistCompletionCopyWith<_ChecklistCompletion> get copyWith => __$ChecklistCompletionCopyWithImpl<_ChecklistCompletion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChecklistCompletionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChecklistCompletion&&(identical(other.id, id) || other.id == id)&&(identical(other.checklistId, checklistId) || other.checklistId == checklistId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.completedBy, completedBy) || other.completedBy == completedBy)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.signOffBy, signOffBy) || other.signOffBy == signOffBy)&&(identical(other.signOffAt, signOffAt) || other.signOffAt == signOffAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,checklistId,eventId,completedBy,startedAt,completedAt,const DeepCollectionEquality().hash(_items),signOffBy,signOffAt,status);

@override
String toString() {
  return 'ChecklistCompletion(id: $id, checklistId: $checklistId, eventId: $eventId, completedBy: $completedBy, startedAt: $startedAt, completedAt: $completedAt, items: $items, signOffBy: $signOffBy, signOffAt: $signOffAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ChecklistCompletionCopyWith<$Res> implements $ChecklistCompletionCopyWith<$Res> {
  factory _$ChecklistCompletionCopyWith(_ChecklistCompletion value, $Res Function(_ChecklistCompletion) _then) = __$ChecklistCompletionCopyWithImpl;
@override @useResult
$Res call({
 String id, String checklistId, String eventId, String completedBy, DateTime startedAt, DateTime? completedAt, List<CompletedItem> items, String? signOffBy, DateTime? signOffAt, ChecklistCompletionStatus status
});




}
/// @nodoc
class __$ChecklistCompletionCopyWithImpl<$Res>
    implements _$ChecklistCompletionCopyWith<$Res> {
  __$ChecklistCompletionCopyWithImpl(this._self, this._then);

  final _ChecklistCompletion _self;
  final $Res Function(_ChecklistCompletion) _then;

/// Create a copy of ChecklistCompletion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? checklistId = null,Object? eventId = null,Object? completedBy = null,Object? startedAt = null,Object? completedAt = freezed,Object? items = null,Object? signOffBy = freezed,Object? signOffAt = freezed,Object? status = null,}) {
  return _then(_ChecklistCompletion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,checklistId: null == checklistId ? _self.checklistId : checklistId // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,completedBy: null == completedBy ? _self.completedBy : completedBy // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CompletedItem>,signOffBy: freezed == signOffBy ? _self.signOffBy : signOffBy // ignore: cast_nullable_to_non_nullable
as String?,signOffAt: freezed == signOffAt ? _self.signOffAt : signOffAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ChecklistCompletionStatus,
  ));
}


}

// dart format on
