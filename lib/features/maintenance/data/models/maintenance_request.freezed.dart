// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maintenance_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MaintenanceComment {

 String get id; String get authorId; String get authorName; String get text; String? get photoUrl; DateTime get createdAt;
/// Create a copy of MaintenanceComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaintenanceCommentCopyWith<MaintenanceComment> get copyWith => _$MaintenanceCommentCopyWithImpl<MaintenanceComment>(this as MaintenanceComment, _$identity);

  /// Serializes this MaintenanceComment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaintenanceComment&&(identical(other.id, id) || other.id == id)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.text, text) || other.text == text)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorId,authorName,text,photoUrl,createdAt);

@override
String toString() {
  return 'MaintenanceComment(id: $id, authorId: $authorId, authorName: $authorName, text: $text, photoUrl: $photoUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MaintenanceCommentCopyWith<$Res>  {
  factory $MaintenanceCommentCopyWith(MaintenanceComment value, $Res Function(MaintenanceComment) _then) = _$MaintenanceCommentCopyWithImpl;
@useResult
$Res call({
 String id, String authorId, String authorName, String text, String? photoUrl, DateTime createdAt
});




}
/// @nodoc
class _$MaintenanceCommentCopyWithImpl<$Res>
    implements $MaintenanceCommentCopyWith<$Res> {
  _$MaintenanceCommentCopyWithImpl(this._self, this._then);

  final MaintenanceComment _self;
  final $Res Function(MaintenanceComment) _then;

/// Create a copy of MaintenanceComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorId = null,Object? authorName = null,Object? text = null,Object? photoUrl = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MaintenanceComment].
extension MaintenanceCommentPatterns on MaintenanceComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MaintenanceComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MaintenanceComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MaintenanceComment value)  $default,){
final _that = this;
switch (_that) {
case _MaintenanceComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MaintenanceComment value)?  $default,){
final _that = this;
switch (_that) {
case _MaintenanceComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String authorId,  String authorName,  String text,  String? photoUrl,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaintenanceComment() when $default != null:
return $default(_that.id,_that.authorId,_that.authorName,_that.text,_that.photoUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String authorId,  String authorName,  String text,  String? photoUrl,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MaintenanceComment():
return $default(_that.id,_that.authorId,_that.authorName,_that.text,_that.photoUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String authorId,  String authorName,  String text,  String? photoUrl,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MaintenanceComment() when $default != null:
return $default(_that.id,_that.authorId,_that.authorName,_that.text,_that.photoUrl,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MaintenanceComment implements MaintenanceComment {
  const _MaintenanceComment({required this.id, required this.authorId, required this.authorName, required this.text, this.photoUrl, required this.createdAt});
  factory _MaintenanceComment.fromJson(Map<String, dynamic> json) => _$MaintenanceCommentFromJson(json);

@override final  String id;
@override final  String authorId;
@override final  String authorName;
@override final  String text;
@override final  String? photoUrl;
@override final  DateTime createdAt;

/// Create a copy of MaintenanceComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaintenanceCommentCopyWith<_MaintenanceComment> get copyWith => __$MaintenanceCommentCopyWithImpl<_MaintenanceComment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MaintenanceCommentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaintenanceComment&&(identical(other.id, id) || other.id == id)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.text, text) || other.text == text)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorId,authorName,text,photoUrl,createdAt);

@override
String toString() {
  return 'MaintenanceComment(id: $id, authorId: $authorId, authorName: $authorName, text: $text, photoUrl: $photoUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MaintenanceCommentCopyWith<$Res> implements $MaintenanceCommentCopyWith<$Res> {
  factory _$MaintenanceCommentCopyWith(_MaintenanceComment value, $Res Function(_MaintenanceComment) _then) = __$MaintenanceCommentCopyWithImpl;
@override @useResult
$Res call({
 String id, String authorId, String authorName, String text, String? photoUrl, DateTime createdAt
});




}
/// @nodoc
class __$MaintenanceCommentCopyWithImpl<$Res>
    implements _$MaintenanceCommentCopyWith<$Res> {
  __$MaintenanceCommentCopyWithImpl(this._self, this._then);

  final _MaintenanceComment _self;
  final $Res Function(_MaintenanceComment) _then;

/// Create a copy of MaintenanceComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? authorId = null,Object? authorName = null,Object? text = null,Object? photoUrl = freezed,Object? createdAt = null,}) {
  return _then(_MaintenanceComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$MaintenanceRequest {

 String get id; String get title; String get description; MaintenancePriority get priority; String get reportedBy; DateTime get reportedAt; String? get assignedTo; MaintenanceStatus get status; List<String> get photos; DateTime? get completedAt; String? get completionNotes; String get boatName; MaintenanceCategory get category; double? get estimatedCost; List<MaintenanceComment> get comments;
/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaintenanceRequestCopyWith<MaintenanceRequest> get copyWith => _$MaintenanceRequestCopyWithImpl<MaintenanceRequest>(this as MaintenanceRequest, _$identity);

  /// Serializes this MaintenanceRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaintenanceRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.reportedBy, reportedBy) || other.reportedBy == reportedBy)&&(identical(other.reportedAt, reportedAt) || other.reportedAt == reportedAt)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.photos, photos)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.completionNotes, completionNotes) || other.completionNotes == completionNotes)&&(identical(other.boatName, boatName) || other.boatName == boatName)&&(identical(other.category, category) || other.category == category)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&const DeepCollectionEquality().equals(other.comments, comments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,priority,reportedBy,reportedAt,assignedTo,status,const DeepCollectionEquality().hash(photos),completedAt,completionNotes,boatName,category,estimatedCost,const DeepCollectionEquality().hash(comments));

@override
String toString() {
  return 'MaintenanceRequest(id: $id, title: $title, description: $description, priority: $priority, reportedBy: $reportedBy, reportedAt: $reportedAt, assignedTo: $assignedTo, status: $status, photos: $photos, completedAt: $completedAt, completionNotes: $completionNotes, boatName: $boatName, category: $category, estimatedCost: $estimatedCost, comments: $comments)';
}


}

/// @nodoc
abstract mixin class $MaintenanceRequestCopyWith<$Res>  {
  factory $MaintenanceRequestCopyWith(MaintenanceRequest value, $Res Function(MaintenanceRequest) _then) = _$MaintenanceRequestCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, MaintenancePriority priority, String reportedBy, DateTime reportedAt, String? assignedTo, MaintenanceStatus status, List<String> photos, DateTime? completedAt, String? completionNotes, String boatName, MaintenanceCategory category, double? estimatedCost, List<MaintenanceComment> comments
});




}
/// @nodoc
class _$MaintenanceRequestCopyWithImpl<$Res>
    implements $MaintenanceRequestCopyWith<$Res> {
  _$MaintenanceRequestCopyWithImpl(this._self, this._then);

  final MaintenanceRequest _self;
  final $Res Function(MaintenanceRequest) _then;

/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? priority = null,Object? reportedBy = null,Object? reportedAt = null,Object? assignedTo = freezed,Object? status = null,Object? photos = null,Object? completedAt = freezed,Object? completionNotes = freezed,Object? boatName = null,Object? category = null,Object? estimatedCost = freezed,Object? comments = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as MaintenancePriority,reportedBy: null == reportedBy ? _self.reportedBy : reportedBy // ignore: cast_nullable_to_non_nullable
as String,reportedAt: null == reportedAt ? _self.reportedAt : reportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MaintenanceStatus,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completionNotes: freezed == completionNotes ? _self.completionNotes : completionNotes // ignore: cast_nullable_to_non_nullable
as String?,boatName: null == boatName ? _self.boatName : boatName // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MaintenanceCategory,estimatedCost: freezed == estimatedCost ? _self.estimatedCost : estimatedCost // ignore: cast_nullable_to_non_nullable
as double?,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as List<MaintenanceComment>,
  ));
}

}


/// Adds pattern-matching-related methods to [MaintenanceRequest].
extension MaintenanceRequestPatterns on MaintenanceRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MaintenanceRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MaintenanceRequest value)  $default,){
final _that = this;
switch (_that) {
case _MaintenanceRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MaintenanceRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  MaintenancePriority priority,  String reportedBy,  DateTime reportedAt,  String? assignedTo,  MaintenanceStatus status,  List<String> photos,  DateTime? completedAt,  String? completionNotes,  String boatName,  MaintenanceCategory category,  double? estimatedCost,  List<MaintenanceComment> comments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.priority,_that.reportedBy,_that.reportedAt,_that.assignedTo,_that.status,_that.photos,_that.completedAt,_that.completionNotes,_that.boatName,_that.category,_that.estimatedCost,_that.comments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  MaintenancePriority priority,  String reportedBy,  DateTime reportedAt,  String? assignedTo,  MaintenanceStatus status,  List<String> photos,  DateTime? completedAt,  String? completionNotes,  String boatName,  MaintenanceCategory category,  double? estimatedCost,  List<MaintenanceComment> comments)  $default,) {final _that = this;
switch (_that) {
case _MaintenanceRequest():
return $default(_that.id,_that.title,_that.description,_that.priority,_that.reportedBy,_that.reportedAt,_that.assignedTo,_that.status,_that.photos,_that.completedAt,_that.completionNotes,_that.boatName,_that.category,_that.estimatedCost,_that.comments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  MaintenancePriority priority,  String reportedBy,  DateTime reportedAt,  String? assignedTo,  MaintenanceStatus status,  List<String> photos,  DateTime? completedAt,  String? completionNotes,  String boatName,  MaintenanceCategory category,  double? estimatedCost,  List<MaintenanceComment> comments)?  $default,) {final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.priority,_that.reportedBy,_that.reportedAt,_that.assignedTo,_that.status,_that.photos,_that.completedAt,_that.completionNotes,_that.boatName,_that.category,_that.estimatedCost,_that.comments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MaintenanceRequest implements MaintenanceRequest {
  const _MaintenanceRequest({required this.id, required this.title, required this.description, required this.priority, required this.reportedBy, required this.reportedAt, this.assignedTo, required this.status, required final  List<String> photos, this.completedAt, this.completionNotes, required this.boatName, required this.category, this.estimatedCost, required final  List<MaintenanceComment> comments}): _photos = photos,_comments = comments;
  factory _MaintenanceRequest.fromJson(Map<String, dynamic> json) => _$MaintenanceRequestFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  MaintenancePriority priority;
@override final  String reportedBy;
@override final  DateTime reportedAt;
@override final  String? assignedTo;
@override final  MaintenanceStatus status;
 final  List<String> _photos;
@override List<String> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override final  DateTime? completedAt;
@override final  String? completionNotes;
@override final  String boatName;
@override final  MaintenanceCategory category;
@override final  double? estimatedCost;
 final  List<MaintenanceComment> _comments;
@override List<MaintenanceComment> get comments {
  if (_comments is EqualUnmodifiableListView) return _comments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comments);
}


/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaintenanceRequestCopyWith<_MaintenanceRequest> get copyWith => __$MaintenanceRequestCopyWithImpl<_MaintenanceRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MaintenanceRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaintenanceRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.reportedBy, reportedBy) || other.reportedBy == reportedBy)&&(identical(other.reportedAt, reportedAt) || other.reportedAt == reportedAt)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._photos, _photos)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.completionNotes, completionNotes) || other.completionNotes == completionNotes)&&(identical(other.boatName, boatName) || other.boatName == boatName)&&(identical(other.category, category) || other.category == category)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&const DeepCollectionEquality().equals(other._comments, _comments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,priority,reportedBy,reportedAt,assignedTo,status,const DeepCollectionEquality().hash(_photos),completedAt,completionNotes,boatName,category,estimatedCost,const DeepCollectionEquality().hash(_comments));

@override
String toString() {
  return 'MaintenanceRequest(id: $id, title: $title, description: $description, priority: $priority, reportedBy: $reportedBy, reportedAt: $reportedAt, assignedTo: $assignedTo, status: $status, photos: $photos, completedAt: $completedAt, completionNotes: $completionNotes, boatName: $boatName, category: $category, estimatedCost: $estimatedCost, comments: $comments)';
}


}

/// @nodoc
abstract mixin class _$MaintenanceRequestCopyWith<$Res> implements $MaintenanceRequestCopyWith<$Res> {
  factory _$MaintenanceRequestCopyWith(_MaintenanceRequest value, $Res Function(_MaintenanceRequest) _then) = __$MaintenanceRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, MaintenancePriority priority, String reportedBy, DateTime reportedAt, String? assignedTo, MaintenanceStatus status, List<String> photos, DateTime? completedAt, String? completionNotes, String boatName, MaintenanceCategory category, double? estimatedCost, List<MaintenanceComment> comments
});




}
/// @nodoc
class __$MaintenanceRequestCopyWithImpl<$Res>
    implements _$MaintenanceRequestCopyWith<$Res> {
  __$MaintenanceRequestCopyWithImpl(this._self, this._then);

  final _MaintenanceRequest _self;
  final $Res Function(_MaintenanceRequest) _then;

/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? priority = null,Object? reportedBy = null,Object? reportedAt = null,Object? assignedTo = freezed,Object? status = null,Object? photos = null,Object? completedAt = freezed,Object? completionNotes = freezed,Object? boatName = null,Object? category = null,Object? estimatedCost = freezed,Object? comments = null,}) {
  return _then(_MaintenanceRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as MaintenancePriority,reportedBy: null == reportedBy ? _self.reportedBy : reportedBy // ignore: cast_nullable_to_non_nullable
as String,reportedAt: null == reportedAt ? _self.reportedAt : reportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MaintenanceStatus,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completionNotes: freezed == completionNotes ? _self.completionNotes : completionNotes // ignore: cast_nullable_to_non_nullable
as String?,boatName: null == boatName ? _self.boatName : boatName // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MaintenanceCategory,estimatedCost: freezed == estimatedCost ? _self.estimatedCost : estimatedCost // ignore: cast_nullable_to_non_nullable
as double?,comments: null == comments ? _self._comments : comments // ignore: cast_nullable_to_non_nullable
as List<MaintenanceComment>,
  ));
}


}

// dart format on
