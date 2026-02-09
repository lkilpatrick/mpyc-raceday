class MarkDistance {
  const MarkDistance({
    required this.fromMarkId,
    required this.toMarkId,
    required this.distanceNm,
    required this.headingMagnetic,
  });

  final String fromMarkId;
  final String toMarkId;
  final double distanceNm;
  final double headingMagnetic;
}
