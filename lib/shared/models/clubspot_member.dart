class ClubspotMember {
  const ClubspotMember({
    required this.id,
    required this.clubId,
    required this.membershipNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.membershipStatus,
    required this.membershipCategory,
    required this.tags,
    required this.raw,
  });

  final String id;
  final String clubId;
  final String membershipNumber;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String membershipStatus;
  final String membershipCategory;
  final List<String> tags;
  final Map<String, dynamic> raw;

  String get fullName => '$firstName $lastName'.trim();

  factory ClubspotMember.fromJson(Map<String, dynamic> json) {
    final tags =
        (json['tags'] as List?)
            ?.map((tag) => tag?.toString() ?? '')
            .where((tag) => tag.isNotEmpty)
            .toList() ??
        const <String>[];

    return ClubspotMember(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      clubId: (json['club_id'] ?? '').toString(),
      membershipNumber:
          (json['membership_number'] ?? json['member_number'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      mobile: (json['mobile'] ?? json['mobile_phone'] ?? '').toString(),
      membershipStatus: (json['membership_status'] ?? '').toString(),
      membershipCategory: (json['membership_category'] ?? '').toString(),
      tags: tags,
      raw: Map<String, dynamic>.from(json),
    );
  }
}
