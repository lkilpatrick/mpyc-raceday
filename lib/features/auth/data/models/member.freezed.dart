// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmergencyContact {

 String get name; String get phone;
/// Create a copy of EmergencyContact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmergencyContactCopyWith<EmergencyContact> get copyWith => _$EmergencyContactCopyWithImpl<EmergencyContact>(this as EmergencyContact, _$identity);

  /// Serializes this EmergencyContact to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmergencyContact&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phone);

@override
String toString() {
  return 'EmergencyContact(name: $name, phone: $phone)';
}


}

/// @nodoc
abstract mixin class $EmergencyContactCopyWith<$Res>  {
  factory $EmergencyContactCopyWith(EmergencyContact value, $Res Function(EmergencyContact) _then) = _$EmergencyContactCopyWithImpl;
@useResult
$Res call({
 String name, String phone
});




}
/// @nodoc
class _$EmergencyContactCopyWithImpl<$Res>
    implements $EmergencyContactCopyWith<$Res> {
  _$EmergencyContactCopyWithImpl(this._self, this._then);

  final EmergencyContact _self;
  final $Res Function(EmergencyContact) _then;

/// Create a copy of EmergencyContact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? phone = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EmergencyContact].
extension EmergencyContactPatterns on EmergencyContact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmergencyContact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmergencyContact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmergencyContact value)  $default,){
final _that = this;
switch (_that) {
case _EmergencyContact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmergencyContact value)?  $default,){
final _that = this;
switch (_that) {
case _EmergencyContact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String phone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmergencyContact() when $default != null:
return $default(_that.name,_that.phone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String phone)  $default,) {final _that = this;
switch (_that) {
case _EmergencyContact():
return $default(_that.name,_that.phone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String phone)?  $default,) {final _that = this;
switch (_that) {
case _EmergencyContact() when $default != null:
return $default(_that.name,_that.phone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmergencyContact implements EmergencyContact {
  const _EmergencyContact({required this.name, required this.phone});
  factory _EmergencyContact.fromJson(Map<String, dynamic> json) => _$EmergencyContactFromJson(json);

@override final  String name;
@override final  String phone;

/// Create a copy of EmergencyContact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmergencyContactCopyWith<_EmergencyContact> get copyWith => __$EmergencyContactCopyWithImpl<_EmergencyContact>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmergencyContactToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmergencyContact&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phone);

@override
String toString() {
  return 'EmergencyContact(name: $name, phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$EmergencyContactCopyWith<$Res> implements $EmergencyContactCopyWith<$Res> {
  factory _$EmergencyContactCopyWith(_EmergencyContact value, $Res Function(_EmergencyContact) _then) = __$EmergencyContactCopyWithImpl;
@override @useResult
$Res call({
 String name, String phone
});




}
/// @nodoc
class __$EmergencyContactCopyWithImpl<$Res>
    implements _$EmergencyContactCopyWith<$Res> {
  __$EmergencyContactCopyWithImpl(this._self, this._then);

  final _EmergencyContact _self;
  final $Res Function(_EmergencyContact) _then;

/// Create a copy of EmergencyContact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? phone = null,}) {
  return _then(_EmergencyContact(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Member {

 String get id; String get firstName; String get lastName; String get email; String get mobileNumber; String get memberNumber; String get membershipStatus; String get membershipCategory; List<String> get memberTags; String get clubspotId; List<MemberRole> get roles; DateTime get lastSynced; String? get profilePhotoUrl; EmergencyContact get emergencyContact; String? get signalNumber; String? get boatName; String? get sailNumber; String? get boatClass; int? get phrfRating; String? get firebaseUid; DateTime? get lastLogin; bool get isActive;
/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberCopyWith<Member> get copyWith => _$MemberCopyWithImpl<Member>(this as Member, _$identity);

  /// Serializes this Member to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Member&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.mobileNumber, mobileNumber) || other.mobileNumber == mobileNumber)&&(identical(other.memberNumber, memberNumber) || other.memberNumber == memberNumber)&&(identical(other.membershipStatus, membershipStatus) || other.membershipStatus == membershipStatus)&&(identical(other.membershipCategory, membershipCategory) || other.membershipCategory == membershipCategory)&&const DeepCollectionEquality().equals(other.memberTags, memberTags)&&(identical(other.clubspotId, clubspotId) || other.clubspotId == clubspotId)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.lastSynced, lastSynced) || other.lastSynced == lastSynced)&&(identical(other.profilePhotoUrl, profilePhotoUrl) || other.profilePhotoUrl == profilePhotoUrl)&&(identical(other.emergencyContact, emergencyContact) || other.emergencyContact == emergencyContact)&&(identical(other.signalNumber, signalNumber) || other.signalNumber == signalNumber)&&(identical(other.boatName, boatName) || other.boatName == boatName)&&(identical(other.sailNumber, sailNumber) || other.sailNumber == sailNumber)&&(identical(other.boatClass, boatClass) || other.boatClass == boatClass)&&(identical(other.phrfRating, phrfRating) || other.phrfRating == phrfRating)&&(identical(other.firebaseUid, firebaseUid) || other.firebaseUid == firebaseUid)&&(identical(other.lastLogin, lastLogin) || other.lastLogin == lastLogin)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,firstName,lastName,email,mobileNumber,memberNumber,membershipStatus,membershipCategory,const DeepCollectionEquality().hash(memberTags),clubspotId,const DeepCollectionEquality().hash(roles),lastSynced,profilePhotoUrl,emergencyContact,signalNumber,boatName,sailNumber,boatClass,phrfRating,firebaseUid,lastLogin,isActive]);

@override
String toString() {
  return 'Member(id: $id, firstName: $firstName, lastName: $lastName, email: $email, mobileNumber: $mobileNumber, memberNumber: $memberNumber, membershipStatus: $membershipStatus, membershipCategory: $membershipCategory, memberTags: $memberTags, clubspotId: $clubspotId, roles: $roles, lastSynced: $lastSynced, profilePhotoUrl: $profilePhotoUrl, emergencyContact: $emergencyContact, signalNumber: $signalNumber, boatName: $boatName, sailNumber: $sailNumber, boatClass: $boatClass, phrfRating: $phrfRating, firebaseUid: $firebaseUid, lastLogin: $lastLogin, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $MemberCopyWith<$Res>  {
  factory $MemberCopyWith(Member value, $Res Function(Member) _then) = _$MemberCopyWithImpl;
@useResult
$Res call({
 String id, String firstName, String lastName, String email, String mobileNumber, String memberNumber, String membershipStatus, String membershipCategory, List<String> memberTags, String clubspotId, List<MemberRole> roles, DateTime lastSynced, String? profilePhotoUrl, EmergencyContact emergencyContact, String? signalNumber, String? boatName, String? sailNumber, String? boatClass, int? phrfRating, String? firebaseUid, DateTime? lastLogin, bool isActive
});


$EmergencyContactCopyWith<$Res> get emergencyContact;

}
/// @nodoc
class _$MemberCopyWithImpl<$Res>
    implements $MemberCopyWith<$Res> {
  _$MemberCopyWithImpl(this._self, this._then);

  final Member _self;
  final $Res Function(Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? mobileNumber = null,Object? memberNumber = null,Object? membershipStatus = null,Object? membershipCategory = null,Object? memberTags = null,Object? clubspotId = null,Object? roles = null,Object? lastSynced = null,Object? profilePhotoUrl = freezed,Object? emergencyContact = null,Object? signalNumber = freezed,Object? boatName = freezed,Object? sailNumber = freezed,Object? boatClass = freezed,Object? phrfRating = freezed,Object? firebaseUid = freezed,Object? lastLogin = freezed,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,mobileNumber: null == mobileNumber ? _self.mobileNumber : mobileNumber // ignore: cast_nullable_to_non_nullable
as String,memberNumber: null == memberNumber ? _self.memberNumber : memberNumber // ignore: cast_nullable_to_non_nullable
as String,membershipStatus: null == membershipStatus ? _self.membershipStatus : membershipStatus // ignore: cast_nullable_to_non_nullable
as String,membershipCategory: null == membershipCategory ? _self.membershipCategory : membershipCategory // ignore: cast_nullable_to_non_nullable
as String,memberTags: null == memberTags ? _self.memberTags : memberTags // ignore: cast_nullable_to_non_nullable
as List<String>,clubspotId: null == clubspotId ? _self.clubspotId : clubspotId // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<MemberRole>,lastSynced: null == lastSynced ? _self.lastSynced : lastSynced // ignore: cast_nullable_to_non_nullable
as DateTime,profilePhotoUrl: freezed == profilePhotoUrl ? _self.profilePhotoUrl : profilePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,emergencyContact: null == emergencyContact ? _self.emergencyContact : emergencyContact // ignore: cast_nullable_to_non_nullable
as EmergencyContact,signalNumber: freezed == signalNumber ? _self.signalNumber : signalNumber // ignore: cast_nullable_to_non_nullable
as String?,boatName: freezed == boatName ? _self.boatName : boatName // ignore: cast_nullable_to_non_nullable
as String?,sailNumber: freezed == sailNumber ? _self.sailNumber : sailNumber // ignore: cast_nullable_to_non_nullable
as String?,boatClass: freezed == boatClass ? _self.boatClass : boatClass // ignore: cast_nullable_to_non_nullable
as String?,phrfRating: freezed == phrfRating ? _self.phrfRating : phrfRating // ignore: cast_nullable_to_non_nullable
as int?,firebaseUid: freezed == firebaseUid ? _self.firebaseUid : firebaseUid // ignore: cast_nullable_to_non_nullable
as String?,lastLogin: freezed == lastLogin ? _self.lastLogin : lastLogin // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EmergencyContactCopyWith<$Res> get emergencyContact {
  
  return $EmergencyContactCopyWith<$Res>(_self.emergencyContact, (value) {
    return _then(_self.copyWith(emergencyContact: value));
  });
}
}


/// Adds pattern-matching-related methods to [Member].
extension MemberPatterns on Member {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Member value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Member value)  $default,){
final _that = this;
switch (_that) {
case _Member():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Member value)?  $default,){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String firstName,  String lastName,  String email,  String mobileNumber,  String memberNumber,  String membershipStatus,  String membershipCategory,  List<String> memberTags,  String clubspotId,  List<MemberRole> roles,  DateTime lastSynced,  String? profilePhotoUrl,  EmergencyContact emergencyContact,  String? signalNumber,  String? boatName,  String? sailNumber,  String? boatClass,  int? phrfRating,  String? firebaseUid,  DateTime? lastLogin,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.email,_that.mobileNumber,_that.memberNumber,_that.membershipStatus,_that.membershipCategory,_that.memberTags,_that.clubspotId,_that.roles,_that.lastSynced,_that.profilePhotoUrl,_that.emergencyContact,_that.signalNumber,_that.boatName,_that.sailNumber,_that.boatClass,_that.phrfRating,_that.firebaseUid,_that.lastLogin,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String firstName,  String lastName,  String email,  String mobileNumber,  String memberNumber,  String membershipStatus,  String membershipCategory,  List<String> memberTags,  String clubspotId,  List<MemberRole> roles,  DateTime lastSynced,  String? profilePhotoUrl,  EmergencyContact emergencyContact,  String? signalNumber,  String? boatName,  String? sailNumber,  String? boatClass,  int? phrfRating,  String? firebaseUid,  DateTime? lastLogin,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _Member():
return $default(_that.id,_that.firstName,_that.lastName,_that.email,_that.mobileNumber,_that.memberNumber,_that.membershipStatus,_that.membershipCategory,_that.memberTags,_that.clubspotId,_that.roles,_that.lastSynced,_that.profilePhotoUrl,_that.emergencyContact,_that.signalNumber,_that.boatName,_that.sailNumber,_that.boatClass,_that.phrfRating,_that.firebaseUid,_that.lastLogin,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String firstName,  String lastName,  String email,  String mobileNumber,  String memberNumber,  String membershipStatus,  String membershipCategory,  List<String> memberTags,  String clubspotId,  List<MemberRole> roles,  DateTime lastSynced,  String? profilePhotoUrl,  EmergencyContact emergencyContact,  String? signalNumber,  String? boatName,  String? sailNumber,  String? boatClass,  int? phrfRating,  String? firebaseUid,  DateTime? lastLogin,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.email,_that.mobileNumber,_that.memberNumber,_that.membershipStatus,_that.membershipCategory,_that.memberTags,_that.clubspotId,_that.roles,_that.lastSynced,_that.profilePhotoUrl,_that.emergencyContact,_that.signalNumber,_that.boatName,_that.sailNumber,_that.boatClass,_that.phrfRating,_that.firebaseUid,_that.lastLogin,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Member extends Member {
  const _Member({required this.id, required this.firstName, required this.lastName, required this.email, required this.mobileNumber, required this.memberNumber, required this.membershipStatus, required this.membershipCategory, required final  List<String> memberTags, required this.clubspotId, required final  List<MemberRole> roles, required this.lastSynced, this.profilePhotoUrl, required this.emergencyContact, this.signalNumber, this.boatName, this.sailNumber, this.boatClass, this.phrfRating, this.firebaseUid, this.lastLogin, this.isActive = true}): _memberTags = memberTags,_roles = roles,super._();
  factory _Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

@override final  String id;
@override final  String firstName;
@override final  String lastName;
@override final  String email;
@override final  String mobileNumber;
@override final  String memberNumber;
@override final  String membershipStatus;
@override final  String membershipCategory;
 final  List<String> _memberTags;
@override List<String> get memberTags {
  if (_memberTags is EqualUnmodifiableListView) return _memberTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberTags);
}

@override final  String clubspotId;
 final  List<MemberRole> _roles;
@override List<MemberRole> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

@override final  DateTime lastSynced;
@override final  String? profilePhotoUrl;
@override final  EmergencyContact emergencyContact;
@override final  String? signalNumber;
@override final  String? boatName;
@override final  String? sailNumber;
@override final  String? boatClass;
@override final  int? phrfRating;
@override final  String? firebaseUid;
@override final  DateTime? lastLogin;
@override@JsonKey() final  bool isActive;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberCopyWith<_Member> get copyWith => __$MemberCopyWithImpl<_Member>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Member&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.mobileNumber, mobileNumber) || other.mobileNumber == mobileNumber)&&(identical(other.memberNumber, memberNumber) || other.memberNumber == memberNumber)&&(identical(other.membershipStatus, membershipStatus) || other.membershipStatus == membershipStatus)&&(identical(other.membershipCategory, membershipCategory) || other.membershipCategory == membershipCategory)&&const DeepCollectionEquality().equals(other._memberTags, _memberTags)&&(identical(other.clubspotId, clubspotId) || other.clubspotId == clubspotId)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.lastSynced, lastSynced) || other.lastSynced == lastSynced)&&(identical(other.profilePhotoUrl, profilePhotoUrl) || other.profilePhotoUrl == profilePhotoUrl)&&(identical(other.emergencyContact, emergencyContact) || other.emergencyContact == emergencyContact)&&(identical(other.signalNumber, signalNumber) || other.signalNumber == signalNumber)&&(identical(other.boatName, boatName) || other.boatName == boatName)&&(identical(other.sailNumber, sailNumber) || other.sailNumber == sailNumber)&&(identical(other.boatClass, boatClass) || other.boatClass == boatClass)&&(identical(other.phrfRating, phrfRating) || other.phrfRating == phrfRating)&&(identical(other.firebaseUid, firebaseUid) || other.firebaseUid == firebaseUid)&&(identical(other.lastLogin, lastLogin) || other.lastLogin == lastLogin)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,firstName,lastName,email,mobileNumber,memberNumber,membershipStatus,membershipCategory,const DeepCollectionEquality().hash(_memberTags),clubspotId,const DeepCollectionEquality().hash(_roles),lastSynced,profilePhotoUrl,emergencyContact,signalNumber,boatName,sailNumber,boatClass,phrfRating,firebaseUid,lastLogin,isActive]);

@override
String toString() {
  return 'Member(id: $id, firstName: $firstName, lastName: $lastName, email: $email, mobileNumber: $mobileNumber, memberNumber: $memberNumber, membershipStatus: $membershipStatus, membershipCategory: $membershipCategory, memberTags: $memberTags, clubspotId: $clubspotId, roles: $roles, lastSynced: $lastSynced, profilePhotoUrl: $profilePhotoUrl, emergencyContact: $emergencyContact, signalNumber: $signalNumber, boatName: $boatName, sailNumber: $sailNumber, boatClass: $boatClass, phrfRating: $phrfRating, firebaseUid: $firebaseUid, lastLogin: $lastLogin, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$MemberCopyWith<$Res> implements $MemberCopyWith<$Res> {
  factory _$MemberCopyWith(_Member value, $Res Function(_Member) _then) = __$MemberCopyWithImpl;
@override @useResult
$Res call({
 String id, String firstName, String lastName, String email, String mobileNumber, String memberNumber, String membershipStatus, String membershipCategory, List<String> memberTags, String clubspotId, List<MemberRole> roles, DateTime lastSynced, String? profilePhotoUrl, EmergencyContact emergencyContact, String? signalNumber, String? boatName, String? sailNumber, String? boatClass, int? phrfRating, String? firebaseUid, DateTime? lastLogin, bool isActive
});


@override $EmergencyContactCopyWith<$Res> get emergencyContact;

}
/// @nodoc
class __$MemberCopyWithImpl<$Res>
    implements _$MemberCopyWith<$Res> {
  __$MemberCopyWithImpl(this._self, this._then);

  final _Member _self;
  final $Res Function(_Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? mobileNumber = null,Object? memberNumber = null,Object? membershipStatus = null,Object? membershipCategory = null,Object? memberTags = null,Object? clubspotId = null,Object? roles = null,Object? lastSynced = null,Object? profilePhotoUrl = freezed,Object? emergencyContact = null,Object? signalNumber = freezed,Object? boatName = freezed,Object? sailNumber = freezed,Object? boatClass = freezed,Object? phrfRating = freezed,Object? firebaseUid = freezed,Object? lastLogin = freezed,Object? isActive = null,}) {
  return _then(_Member(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,mobileNumber: null == mobileNumber ? _self.mobileNumber : mobileNumber // ignore: cast_nullable_to_non_nullable
as String,memberNumber: null == memberNumber ? _self.memberNumber : memberNumber // ignore: cast_nullable_to_non_nullable
as String,membershipStatus: null == membershipStatus ? _self.membershipStatus : membershipStatus // ignore: cast_nullable_to_non_nullable
as String,membershipCategory: null == membershipCategory ? _self.membershipCategory : membershipCategory // ignore: cast_nullable_to_non_nullable
as String,memberTags: null == memberTags ? _self._memberTags : memberTags // ignore: cast_nullable_to_non_nullable
as List<String>,clubspotId: null == clubspotId ? _self.clubspotId : clubspotId // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<MemberRole>,lastSynced: null == lastSynced ? _self.lastSynced : lastSynced // ignore: cast_nullable_to_non_nullable
as DateTime,profilePhotoUrl: freezed == profilePhotoUrl ? _self.profilePhotoUrl : profilePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,emergencyContact: null == emergencyContact ? _self.emergencyContact : emergencyContact // ignore: cast_nullable_to_non_nullable
as EmergencyContact,signalNumber: freezed == signalNumber ? _self.signalNumber : signalNumber // ignore: cast_nullable_to_non_nullable
as String?,boatName: freezed == boatName ? _self.boatName : boatName // ignore: cast_nullable_to_non_nullable
as String?,sailNumber: freezed == sailNumber ? _self.sailNumber : sailNumber // ignore: cast_nullable_to_non_nullable
as String?,boatClass: freezed == boatClass ? _self.boatClass : boatClass // ignore: cast_nullable_to_non_nullable
as String?,phrfRating: freezed == phrfRating ? _self.phrfRating : phrfRating // ignore: cast_nullable_to_non_nullable
as int?,firebaseUid: freezed == firebaseUid ? _self.firebaseUid : firebaseUid // ignore: cast_nullable_to_non_nullable
as String?,lastLogin: freezed == lastLogin ? _self.lastLogin : lastLogin // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EmergencyContactCopyWith<$Res> get emergencyContact {
  
  return $EmergencyContactCopyWith<$Res>(_self.emergencyContact, (value) {
    return _then(_self.copyWith(emergencyContact: value));
  });
}
}

// dart format on
