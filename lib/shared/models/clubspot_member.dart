class ClubspotMember {
  const ClubspotMember({
    required this.id,
    required this.clubId,
    required this.membershipNumber,
    required this.membershipId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.dob,
    required this.membershipStatus,
    required this.membershipCategory,
    required this.memberTags,
    required this.created,
    required this.raw,
  });

  final String id;
  final String clubId;
  final String membershipNumber;
  final String membershipId;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String dob;
  final String membershipStatus;
  final String membershipCategory;
  final List<String> memberTags;
  final int? created;
  final Map<String, dynamic> raw;

  String get fullName => '$firstName $lastName'.trim();

  factory ClubspotMember.fromJson(Map<String, dynamic> json) {
    // member_tags is the documented field name from the API
    final tags =
        (json['member_tags'] as List?)
            ?.map((tag) => tag?.toString() ?? '')
            .where((tag) => tag.isNotEmpty)
            .toList() ??
        const <String>[];

    // membership is a nested object: { id, status, category }
    final membership = json['membership'] as Map<String, dynamic>? ?? {};

    return ClubspotMember(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      clubId: (json['club_id'] ?? '').toString(),
      membershipNumber:
          (json['membership_number'] ?? json['member_number'] ?? '').toString(),
      membershipId: (membership['id'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      mobileNumber: (json['mobile_number'] ?? json['mobile'] ?? json['mobile_phone'] ?? '').toString(),
      dob: (json['dob'] ?? '').toString(),
      membershipStatus: (membership['status'] ?? json['membership_status'] ?? '').toString(),
      membershipCategory: (membership['category'] ?? json['membership_category'] ?? '').toString(),
      memberTags: tags,
      created: json['created'] is int ? json['created'] as int : null,
      raw: Map<String, dynamic>.from(json),
    );
  }
}
