import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/course_config.dart';
import '../../data/models/mark_distance.dart';

class CourseMapDiagram extends StatelessWidget {
  const CourseMapDiagram({
    super.key,
    required this.course,
    required this.distances,
    this.windDirectionDeg,
    this.size = const Size(300, 300),
    this.onMarkTap,
  });

  final CourseConfig course;
  final List<MarkDistance> distances;
  final double? windDirectionDeg;
  final Size size;
  final void Function(CourseMark mark, MarkDistance? toNext, MarkDistance? fromPrev)? onMarkTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        size: size,
        painter: _CoursePainter(
          course: course,
          distances: distances,
          windDirDeg: windDirectionDeg,
        ),
      ),
    );
  }
}

class _CoursePainter extends CustomPainter {
  _CoursePainter({
    required this.course,
    required this.distances,
    this.windDirDeg,
  });

  final CourseConfig course;
  final List<MarkDistance> distances;
  final double? windDirDeg;

  MarkDistance? _findDist(String from, String to) {
    for (final d in distances) {
      if (d.fromMarkId == from && d.toMarkId == to) return d;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final marks = course.marks;
    if (marks.isEmpty) return;

    final padding = 40.0;
    final usable = Size(size.width - padding * 2, size.height - padding * 2);

    // Calculate positions using headings and distances from MY1 (start/finish)
    // Start at bottom-center
    final positions = <String, Offset>{};
    final startPos = Offset(usable.width / 2, usable.height - 20);
    positions['START'] = startPos;

    // Place marks relative using heading/distance
    // First pass: compute raw positions
    final rawPositions = <int, Offset>{};
    rawPositions[0] = startPos;

    for (int i = 0; i < marks.length; i++) {
      if (i == 0) {
        // First mark: use heading from MY1 to this mark
        final dist = _findDist('MY1', marks[i].markId);
        if (dist != null) {
          final rad = (dist.headingMagnetic - 90) * math.pi / 180;
          final scale = usable.width * 0.12;
          rawPositions[i + 1] = Offset(
            startPos.dx + math.cos(rad) * dist.distanceNm * scale,
            startPos.dy - math.sin(rad) * dist.distanceNm * scale,
          );
        } else {
          // Fallback: place above start
          rawPositions[i + 1] = Offset(startPos.dx, startPos.dy - 60);
        }
      } else {
        final prevMarkId = marks[i - 1].markId;
        final curMarkId = marks[i].markId;
        final dist = _findDist(prevMarkId, curMarkId);
        final prevPos = rawPositions[i] ?? startPos;
        if (dist != null) {
          final rad = (dist.headingMagnetic - 90) * math.pi / 180;
          final scale = usable.width * 0.12;
          rawPositions[i + 1] = Offset(
            prevPos.dx + math.cos(rad) * dist.distanceNm * scale,
            prevPos.dy - math.sin(rad) * dist.distanceNm * scale,
          );
        } else {
          rawPositions[i + 1] =
              Offset(prevPos.dx + 30, prevPos.dy - 40);
        }
      }
    }

    // Normalize to fit canvas
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final p in rawPositions.values) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    // Add start position
    minX = math.min(minX, startPos.dx);
    maxX = math.max(maxX, startPos.dx);
    minY = math.min(minY, startPos.dy);
    maxY = math.max(maxY, startPos.dy);

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    final scaleX = rangeX > 0 ? usable.width / rangeX : 1.0;
    final scaleY = rangeY > 0 ? usable.height / rangeY : 1.0;
    final scale = math.min(scaleX, scaleY) * 0.8;

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    Offset normalize(Offset p) => Offset(
          padding + (p.dx - centerX) * scale + usable.width / 2,
          padding + (p.dy - centerY) * scale + usable.height / 2,
        );

    final normalizedStart = normalize(startPos);
    final normalizedMarks = <int, Offset>{};
    for (final entry in rawPositions.entries) {
      normalizedMarks[entry.key] = normalize(entry.value);
    }

    // Draw wind direction arrow (background)
    if (windDirDeg != null) {
      final windPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.15)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      final windRad = (windDirDeg! - 90) * math.pi / 180;
      final center = Offset(size.width / 2, size.height / 2);
      final windEnd = Offset(
        center.dx + math.cos(windRad) * size.width * 0.35,
        center.dy + math.sin(windRad) * size.width * 0.35,
      );
      final windStart = Offset(
        center.dx - math.cos(windRad) * size.width * 0.35,
        center.dy - math.sin(windRad) * size.width * 0.35,
      );
      canvas.drawLine(windStart, windEnd, windPaint);
      // Arrow head
      _drawArrowHead(canvas, windStart, windEnd, windPaint, 12);

      // Wind label
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'WIND',
          style: TextStyle(
            color: Colors.blue.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, windStart - const Offset(0, 14));
    }

    // Draw course legs
    final legPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Start line
    final startLinePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3;
    canvas.drawLine(
      normalizedStart + const Offset(-15, 0),
      normalizedStart + const Offset(15, 0),
      startLinePaint,
    );

    // Draw legs from start to first mark, then mark to mark
    Offset prevPos = normalizedStart;
    for (int i = 0; i < marks.length; i++) {
      final curPos = normalizedMarks[i + 1] ?? prevPos;
      canvas.drawLine(prevPos, curPos, legPaint);
      _drawArrowHead(canvas, prevPos, curPos, legPaint, 8);

      // Leg distance label
      final prevMarkId = i == 0 ? 'MY1' : marks[i - 1].markId;
      final curMarkId = marks[i].markId;
      final dist = _findDist(prevMarkId, curMarkId);
      if (dist != null) {
        final mid = Offset(
          (prevPos.dx + curPos.dx) / 2,
          (prevPos.dy + curPos.dy) / 2,
        );
        final tp = TextPainter(
          text: TextSpan(
            text: '${dist.distanceNm.toStringAsFixed(1)}nm',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 9,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, mid + const Offset(4, -12));
      }

      prevPos = curPos;
    }

    // Draw marks
    for (int i = 0; i < marks.length; i++) {
      final pos = normalizedMarks[i + 1] ?? normalizedStart;
      final mark = marks[i];
      final isInflatable = ['W', 'R', 'L', 'LV'].contains(mark.markId);

      // Mark circle
      final markPaint = Paint()
        ..color = isInflatable ? Colors.orange : Colors.blue
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 10, markPaint);

      // Rounding indicator
      final roundColor =
          mark.rounding == MarkRounding.port ? Colors.red : Colors.green;
      final roundPaint = Paint()
        ..color = roundColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final roundRect = Rect.fromCircle(center: pos, radius: 14);
      final startAngle =
          mark.rounding == MarkRounding.port ? -math.pi / 2 : 0.0;
      canvas.drawArc(roundRect, startAngle, math.pi, false, roundPaint);

      // Mark label
      final tp = TextPainter(
        text: TextSpan(
          text: mark.markName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));

      // Finish indicator
      if (mark.isFinish) {
        final finishPaint = Paint()
          ..color = Colors.green
          ..strokeWidth = 3;
        canvas.drawLine(
          pos + const Offset(-12, 14),
          pos + const Offset(12, 14),
          finishPaint,
        );
        final finishTp = TextPainter(
          text: const TextSpan(
            text: 'FINISH',
            style: TextStyle(
              color: Colors.green,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        finishTp.paint(canvas, pos + Offset(-finishTp.width / 2, 16));
      }
    }

    // Draw start marker
    final startPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(center: normalizedStart, width: 16, height: 12),
      startPaint,
    );
    final startTp = TextPainter(
      text: const TextSpan(
        text: 'RC',
        style: TextStyle(
          color: Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    startTp.paint(
        canvas, normalizedStart - Offset(startTp.width / 2, startTp.height / 2));
  }

  void _drawArrowHead(
      Canvas canvas, Offset from, Offset to, Paint paint, double size) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final mid = Offset(
      (from.dx + to.dx) / 2,
      (from.dy + to.dy) / 2,
    );
    final p1 = Offset(
      mid.dx - size * math.cos(angle - 0.4),
      mid.dy - size * math.sin(angle - 0.4),
    );
    final p2 = Offset(
      mid.dx - size * math.cos(angle + 0.4),
      mid.dy - size * math.sin(angle + 0.4),
    );
    final path = Path()
      ..moveTo(mid.dx, mid.dy)
      ..lineTo(p1.dx, p1.dy)
      ..moveTo(mid.dx, mid.dy)
      ..lineTo(p2.dx, p2.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CoursePainter oldDelegate) => true;
}
