import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mpyc_raceday/core/theme.dart';

import '../../data/models/course_config.dart';
import '../../data/models/mark.dart';

/// Interactive map of Monterey Bay with race marks and course legs
/// using flutter_map + OpenStreetMap tiles.
class CourseMapWidget extends StatefulWidget {
  const CourseMapWidget({
    super.key,
    required this.marks,
    this.course,
    this.selectedMarkId,
    this.onMarkTap,
    this.height = 500,
  });

  final List<Mark> marks;
  final CourseConfig? course;
  final String? selectedMarkId;
  final ValueChanged<Mark>? onMarkTap;
  final double height;

  @override
  State<CourseMapWidget> createState() => _CourseMapWidgetState();
}

class _CourseMapWidgetState extends State<CourseMapWidget> {
  final MapController _mapController = MapController();

  // Center on Monterey Bay race area
  static const _center = LatLng(36.625, -121.89);
  static const _defaultZoom = 13.0;

  Mark? _findMark(String id) {
    for (final m in widget.marks) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: widget.height,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: _defaultZoom,
            minZoom: 11,
            maxZoom: 18,
          ),
          children: [
            // OpenStreetMap tiles
            TileLayer(
              urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
              maxZoom: 19,
            ),

            // Course legs polyline
            if (widget.course != null) _buildCourseLegs(),

            // Mark markers
            MarkerLayer(
              markers: _buildMarkMarkers(),
            ),
          ],
        ),
      ),
    );
  }

  PolylineLayer _buildCourseLegs() {
    final course = widget.course!;
    final courseMarks = course.marks;
    if (courseMarks.isEmpty) return const PolylineLayer(polylines: []);

    // Start from mark 1 (the implicit start/finish)
    final startMark = _findMark('1');
    if (startMark == null || startMark.latitude == null) {
      return const PolylineLayer(polylines: []);
    }

    final points = <LatLng>[
      LatLng(startMark.latitude!, startMark.longitude!),
    ];

    for (final cm in courseMarks) {
      final m = _findMark(cm.markId);
      if (m == null || m.latitude == null) continue;
      points.add(LatLng(m.latitude!, m.longitude!));
    }

    // If course finishes at committee boat (Finish), return to mark 1
    if (course.finishLocation == 'committee_boat') {
      points.add(LatLng(startMark.latitude!, startMark.longitude!));
    }

    return PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          color: AppColors.secondary.withAlpha(200),
          strokeWidth: 3,
        ),
      ],
    );
  }

  List<Marker> _buildMarkMarkers() {
    final markers = <Marker>[];

    for (final m in widget.marks) {
      if (m.latitude == null || m.longitude == null) continue;

      final isSelected = widget.selectedMarkId == m.id;
      final isInflatable = m.type == 'inflatable' || m.type == 'temporary';
      final isCourseActive = widget.course != null &&
          widget.course!.marks.any((cm) => cm.markId == m.id);
      // Mark 1 is always on the course (implicit start/finish)
      final isStart = m.id == '1';

      final color = isSelected
          ? AppColors.accent
          : isStart
              ? Colors.green
              : isCourseActive
                  ? AppColors.primary
                  : isInflatable
                      ? Colors.orange
                      : AppColors.primary.withAlpha(180);

      markers.add(
        Marker(
          point: LatLng(m.latitude!, m.longitude!),
          width: 60,
          height: 50,
          child: GestureDetector(
            onTap: widget.onMarkTap != null ? () => widget.onMarkTap!(m) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isSelected ? 32 : 28,
                  height: isSelected ? 32 : 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(100),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      m.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (isStart)
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(220),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'START/FINISH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }
}
