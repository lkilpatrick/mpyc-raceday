// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmergencyContact _$EmergencyContactFromJson(Map<String, dynamic> json) =>
    _EmergencyContact(
      name: json['name'] as String,
      phone: json['phone'] as String,
    );

Map<String, dynamic> _$EmergencyContactToJson(_EmergencyContact instance) =>
    <String, dynamic>{'name': instance.name, 'phone': instance.phone};

_Member _$MemberFromJson(Map<String, dynamic> json) => _Member(
  id: json['id'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String,
  mobileNumber: json['mobileNumber'] as String,
  memberNumber: json['memberNumber'] as String,
  membershipStatus: json['membershipStatus'] as String,
  membershipCategory: json['membershipCategory'] as String,
  memberTags: (json['memberTags'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  clubspotId: json['clubspotId'] as String,
  roles: (json['roles'] as List<dynamic>)
      .map((e) => $enumDecode(_$MemberRoleEnumMap, e))
      .toList(),
  lastSynced: DateTime.parse(json['lastSynced'] as String),
  profilePhotoUrl: json['profilePhotoUrl'] as String?,
  emergencyContact: EmergencyContact.fromJson(
    json['emergencyContact'] as Map<String, dynamic>,
  ),
  signalNumber: json['signalNumber'] as String?,
  boatName: json['boatName'] as String?,
  sailNumber: json['sailNumber'] as String?,
  boatClass: json['boatClass'] as String?,
  phrfRating: (json['phrfRating'] as num?)?.toInt(),
  firebaseUid: json['firebaseUid'] as String?,
  lastLogin: json['lastLogin'] == null
      ? null
      : DateTime.parse(json['lastLogin'] as String),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$MemberToJson(_Member instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'mobileNumber': instance.mobileNumber,
  'memberNumber': instance.memberNumber,
  'membershipStatus': instance.membershipStatus,
  'membershipCategory': instance.membershipCategory,
  'memberTags': instance.memberTags,
  'clubspotId': instance.clubspotId,
  'roles': instance.roles.map((e) => _$MemberRoleEnumMap[e]!).toList(),
  'lastSynced': instance.lastSynced.toIso8601String(),
  'profilePhotoUrl': instance.profilePhotoUrl,
  'emergencyContact': instance.emergencyContact,
  'signalNumber': instance.signalNumber,
  'boatName': instance.boatName,
  'sailNumber': instance.sailNumber,
  'boatClass': instance.boatClass,
  'phrfRating': instance.phrfRating,
  'firebaseUid': instance.firebaseUid,
  'lastLogin': instance.lastLogin?.toIso8601String(),
  'isActive': instance.isActive,
};

const _$MemberRoleEnumMap = {
  MemberRole.webAdmin: 'web_admin',
  MemberRole.clubBoard: 'club_board',
  MemberRole.rcChair: 'rc_chair',
  MemberRole.skipper: 'skipper',
  MemberRole.crew: 'crew',
};
