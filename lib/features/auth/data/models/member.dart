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
  @JsonValue('web_admin')
  webAdmin,
  @JsonValue('club_board')
  clubBoard,
  @JsonValue('rc_chair')
  rcChair,
  skipper,
  crew,
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
    required List<MemberRole> roles,
    required DateTime lastSynced,
    String? profilePhotoUrl,
    required EmergencyContact emergencyContact,
    String? signalNumber,
    String? boatName,
    String? sailNumber,
    String? boatClass,
    int? phrfRating,
    String? firebaseUid,
    DateTime? lastLogin,
    @Default(true) bool isActive,
  }) = _Member;

  const Member._();

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

  bool hasRole(MemberRole role) => roles.contains(role);

  bool hasAnyRole(List<MemberRole> checkRoles) =>
      roles.any((r) => checkRoles.contains(r));

  bool get isWebAdmin => hasRole(MemberRole.webAdmin);

  bool get isClubBoard =>
      hasAnyRole([MemberRole.webAdmin, MemberRole.clubBoard]);

  bool get isRCChair =>
      hasAnyRole([MemberRole.webAdmin, MemberRole.rcChair]);

  bool get isSkipperOrAbove => hasAnyRole([
        MemberRole.webAdmin,
        MemberRole.rcChair,
        MemberRole.clubBoard,
        MemberRole.skipper,
      ]);

  bool get canAccessWebDashboard => hasAnyRole([
        MemberRole.webAdmin,
        MemberRole.clubBoard,
        MemberRole.rcChair,
      ]);

  String get displayName => '$firstName $lastName'.trim();
}
