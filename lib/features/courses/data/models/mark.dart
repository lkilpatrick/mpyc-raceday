class Mark {
  const Mark({
    required this.id,
    required this.name,
    required this.type,
    this.code,
    this.latitude,
    this.longitude,
    this.description,
  });

  final String id;
  final String name;
  final String type; // "permanent", "temporary", "government", "harbor"
  final String? code;
  final double? latitude;
  final double? longitude;
  final String? description;
}
