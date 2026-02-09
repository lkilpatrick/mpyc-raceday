import 'dart:math' as math;

class DistanceUtils {
  DistanceUtils._();

  /// Haversine distance between two lat/lon points in meters.
  static double haversineMeters(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const earthRadiusM = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  static double metersToNauticalMiles(double meters) => meters / 1852.0;
  static double metersToMiles(double meters) => meters / 1609.344;
  static double metersToKm(double meters) => meters / 1000.0;

  static double _toRad(double deg) => deg * math.pi / 180.0;
}
