import 'package:freezed_annotation/freezed_annotation.dart';

part 'member.freezed.dart';
part 'member.g.dart';

@freezed
abstract class EmergencyContact with _$EmergencyContact {
  const factory EmergencyContact({
    required String name,
    required String phone,
  }) = _EmergencyContact;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactFromJson(json);
}

enum MemberRole {
  admin,
  pro,
  @JsonValue('rc_crew')
  rcCrew,
  member,
}

@freezed
abstract class Member with _$Member {
  const factory Member({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String memberNumber,
    required String membershipStatus,
    required String membershipCategory,
    required List<String> memberTags,
    required String clubspotId,
    required MemberRole role,
    required DateTime lastSynced,
    String? profilePhotoUrl,
    required EmergencyContact emergencyContact,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}
