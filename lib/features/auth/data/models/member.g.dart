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
  role: $enumDecode(_$MemberRoleEnumMap, json['role']),
  lastSynced: DateTime.parse(json['lastSynced'] as String),
  profilePhotoUrl: json['profilePhotoUrl'] as String?,
  emergencyContact: EmergencyContact.fromJson(
    json['emergencyContact'] as Map<String, dynamic>,
  ),
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
  'role': _$MemberRoleEnumMap[instance.role]!,
  'lastSynced': instance.lastSynced.toIso8601String(),
  'profilePhotoUrl': instance.profilePhotoUrl,
  'emergencyContact': instance.emergencyContact,
};

const _$MemberRoleEnumMap = {
  MemberRole.admin: 'admin',
  MemberRole.pro: 'pro',
  MemberRole.rcCrew: 'rc_crew',
  MemberRole.member: 'member',
};
