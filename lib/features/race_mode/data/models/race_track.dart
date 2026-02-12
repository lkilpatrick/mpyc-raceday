import 'package:cloud_firestore/cloud_firestore.dart';

class TrackPoint {
  const TrackPoint({
    required this.lat,
    required this.lon,
    required this.timestamp,
    this.speedKnots,
    this.heading,
    this.accuracy,
  });

  final double lat;
  final double lon;
  final DateTime timestamp;
  final double? speedKnots;
  final double? heading;
  final double? accuracy;

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lon': lon,
        'timestamp': Timestamp.fromDate(timestamp),
        if (speedKnots != null) 'speedKnots': speedKnots,
        if (heading != null) 'heading': heading,
        if (accuracy != null) 'accuracy': accuracy,
      };

  factory TrackPoint.fromMap(Map<String, dynamic> m) => TrackPoint(
        lat: (m['lat'] as num).toDouble(),
        lon: (m['lon'] as num).toDouble(),
        timestamp: (m['timestamp'] as Timestamp).toDate(),
        speedKnots: (m['speedKnots'] as num?)?.toDouble(),
        heading: (m['heading'] as num?)?.toDouble(),
        accuracy: (m['accuracy'] as num?)?.toDouble(),
      );
}

class RaceTrack {
  const RaceTrack({
    required this.id,
    required this.memberId,
    required this.eventId,
    required this.eventName,
    required this.courseId,
    required this.date,
    required this.startTime,
    this.finishTime,
    required this.points,
    this.boatName,
    this.sailNumber,
    this.boatClass,
    this.distanceNm,
    this.avgSpeedKnots,
    this.maxSpeedKnots,
  });

  final String id;
  final String memberId;
  final String eventId;
  final String eventName;
  final String courseId;
  final DateTime date;
  final DateTime startTime;
  final DateTime? finishTime;
  final List<TrackPoint> points;
  final String? boatName;
  final String? sailNumber;
  final String? boatClass;
  final double? distanceNm;
  final double? avgSpeedKnots;
  final double? maxSpeedKnots;

  Map<String, dynamic> toMap() => {
        'memberId': memberId,
        'eventId': eventId,
        'eventName': eventName,
        'courseId': courseId,
        'date': Timestamp.fromDate(date),
        'startTime': Timestamp.fromDate(startTime),
        if (finishTime != null) 'finishTime': Timestamp.fromDate(finishTime!),
        'points': points.map((p) => p.toMap()).toList(),
        if (boatName != null) 'boatName': boatName,
        if (sailNumber != null) 'sailNumber': sailNumber,
        if (boatClass != null) 'boatClass': boatClass,
        if (distanceNm != null) 'distanceNm': distanceNm,
        if (avgSpeedKnots != null) 'avgSpeedKnots': avgSpeedKnots,
        if (maxSpeedKnots != null) 'maxSpeedKnots': maxSpeedKnots,
        'pointCount': points.length,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory RaceTrack.fromDoc(String id, Map<String, dynamic> m) {
    final pointsList = (m['points'] as List<dynamic>?) ?? [];
    return RaceTrack(
      id: id,
      memberId: m['memberId'] as String? ?? '',
      eventId: m['eventId'] as String? ?? '',
      eventName: m['eventName'] as String? ?? '',
      courseId: m['courseId'] as String? ?? '',
      date: (m['date'] as Timestamp).toDate(),
      startTime: (m['startTime'] as Timestamp).toDate(),
      finishTime: (m['finishTime'] as Timestamp?)?.toDate(),
      points: pointsList
          .map((p) => TrackPoint.fromMap(p as Map<String, dynamic>))
          .toList(),
      boatName: m['boatName'] as String?,
      sailNumber: m['sailNumber'] as String?,
      boatClass: m['boatClass'] as String?,
      distanceNm: (m['distanceNm'] as num?)?.toDouble(),
      avgSpeedKnots: (m['avgSpeedKnots'] as num?)?.toDouble(),
      maxSpeedKnots: (m['maxSpeedKnots'] as num?)?.toDouble(),
    );
  }
}
