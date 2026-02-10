import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mpyc_raceday/core/theme.dart';

import '../../data/models/course_config.dart';
import '../../data/models/mark.dart';

/// Displays the NOAA nautical chart of Monterey Bay with race marks overlaid.
///
/// The chart image bounding box (EPSG:4326):
///   lat: 36.585 – 36.655
///   lon: -121.945 – -121.835
class NauticalChartWidget extends StatefulWidget {
  const NauticalChartWidget({
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
  State<NauticalChartWidget> createState() => _NauticalChartWidgetState();
}

class _NauticalChartWidgetState extends State<NauticalChartWidget> {
  // Chart bounding box in lat/lon (must match the exported image)
  static const _latMin = 36.585;
  static const _latMax = 36.655;
  static const _lonMin = -121.945;
  static const _lonMax = -121.835;

  final TransformationController _transformCtrl = TransformationController();

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  /// Convert lat/lon to fractional position (0..1) within the chart image.
  Offset _geoToFraction(double lat, double lon) {
    final x = (lon - _lonMin) / (_lonMax - _lonMin);
    final y = 1.0 - (lat - _latMin) / (_latMax - _latMin); // flip Y
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InteractiveViewer(
          transformationController: _transformCtrl,
          minScale: 0.5,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(100),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Chart image
                  Image.asset(
                    'assets/images/monterey_bay_chart.png',
                    width: constraints.maxWidth,
                    height: widget.height,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.blue.shade50,
                      child: const Center(
                        child: Text('Chart image not available'),
                      ),
                    ),
                  ),

                  // Course legs (if a course is provided)
                  if (widget.course != null)
                    CustomPaint(
                      size: Size(constraints.maxWidth, widget.height),
                      painter: _CourseLegPainter(
                        course: widget.course!,
                        marks: widget.marks,
                        geoToPixel: (lat, lon) {
                          final frac = _geoToFraction(lat, lon);
                          return Offset(
                            frac.dx * constraints.maxWidth,
                            frac.dy * widget.height,
                          );
                        },
                      ),
                    ),

                  // Mark pins
                  ...widget.marks
                      .where((m) => m.latitude != null && m.longitude != null)
                      .map((m) {
                    final frac = _geoToFraction(m.latitude!, m.longitude!);
                    final isInflatable = m.type == 'inflatable';
                    final isSelected = widget.selectedMarkId == m.id;
                    final isCourseActive = widget.course != null &&
                        widget.course!.marks.any((cm) => cm.markId == m.id);

                    return Positioned(
                      left: frac.dx * constraints.maxWidth - 14,
                      top: frac.dy * widget.height - 14,
                      child: GestureDetector(
                        onTap: widget.onMarkTap != null
                            ? () => widget.onMarkTap!(m)
                            : null,
                        child: _MarkPin(
                          mark: m,
                          isInflatable: isInflatable,
                          isSelected: isSelected,
                          isOnCourse: isCourseActive,
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MarkPin extends StatelessWidget {
  const _MarkPin({
    required this.mark,
    required this.isInflatable,
    required this.isSelected,
    required this.isOnCourse,
  });

  final Mark mark;
  final bool isInflatable;
  final bool isSelected;
  final bool isOnCourse;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.accent
        : isOnCourse
            ? AppColors.primary
            : isInflatable
                ? Colors.orange
                : AppColors.primary.withAlpha(180);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white70,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              mark.id,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 2,
              ),
            ],
          ),
          child: Text(
            mark.name,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _CourseLegPainter extends CustomPainter {
  _CourseLegPainter({
    required this.course,
    required this.marks,
    required this.geoToPixel,
  });

  final CourseConfig course;
  final List<Mark> marks;
  final Offset Function(double lat, double lon) geoToPixel;

  Mark? _findMark(String id) {
    for (final m in marks) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final courseMarks = course.marks;
    if (courseMarks.isEmpty) return;

    final legPaint = Paint()
      ..color = AppColors.secondary.withAlpha(180)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw from mark 1 (start/finish) to first mark, then mark to mark
    final startMark = _findMark('1');
    if (startMark == null || startMark.latitude == null) return;

    Offset prevPos = geoToPixel(startMark.latitude!, startMark.longitude!);

    for (final cm in courseMarks) {
      final m = _findMark(cm.markId);
      if (m == null || m.latitude == null) continue;

      final curPos = geoToPixel(m.latitude!, m.longitude!);
      canvas.drawLine(prevPos, curPos, legPaint);

      // Draw small arrow at midpoint
      _drawArrow(canvas, prevPos, curPos, legPaint);

      prevPos = curPos;
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = (dx * dx + dy * dy);
    if (len < 100) return; // too short

    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final angle = math.atan2(dy, dx);
    const arrowSize = 8.0;

    final p1 = Offset(
      mid.dx - arrowSize * math.cos(angle - 0.4),
      mid.dy - arrowSize * math.sin(angle - 0.4),
    );
    final p2 = Offset(
      mid.dx - arrowSize * math.cos(angle + 0.4),
      mid.dy - arrowSize * math.sin(angle + 0.4),
    );

    final arrowPaint = Paint()
      ..color = paint.color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(mid, p1, arrowPaint);
    canvas.drawLine(mid, p2, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _CourseLegPainter oldDelegate) => true;
}
