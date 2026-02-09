import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/live_weather.dart';

class WindCompassWidget extends StatelessWidget {
  const WindCompassWidget({
    super.key,
    required this.dirDeg,
    required this.speed,
    required this.unit,
    this.gust,
    this.size = 200,
    this.showLabels = true,
  });

  final int dirDeg;
  final double speed;
  final WindSpeedUnit unit;
  final double? gust;
  final double size;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CompassPainter(
              dirDeg: dirDeg,
              size: size,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$dirDeg°',
                    style: TextStyle(
                      fontSize: size * 0.12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _compassLabel(dirDeg),
                    style: TextStyle(
                      fontSize: size * 0.07,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Speed display
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              speed.toStringAsFixed(1),
              style: TextStyle(
                fontSize: size * 0.18,
                fontWeight: FontWeight.bold,
                color: _speedColor(speed, unit),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit == WindSpeedUnit.kts ? 'kts' : 'mph',
              style: TextStyle(
                fontSize: size * 0.08,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        if (gust != null) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.air, size: size * 0.06, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                'Gust ${gust!.toStringAsFixed(1)} ${unit == WindSpeedUnit.kts ? 'kts' : 'mph'}',
                style: TextStyle(
                  fontSize: size * 0.065,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _compassLabel(int deg) {
    const labels = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                    'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((deg + 11.25) % 360 / 22.5).floor();
    return labels[index % 16];
  }

  static Color _speedColor(double speed, WindSpeedUnit unit) {
    final kts = unit == WindSpeedUnit.kts ? speed : speed * 0.868976;
    if (kts < 5) return Colors.green;
    if (kts < 12) return Colors.blue;
    if (kts < 20) return Colors.orange;
    if (kts < 30) return Colors.deepOrange;
    return Colors.red;
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.dirDeg, required this.size});

  final int dirDeg;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = canvasSize.width / 2 - 4;

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFF1B3A5C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Outer ring
    final ringPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ringPaint);

    // Tick marks
    final tickPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1;
    final majorTickPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2;

    for (int i = 0; i < 360; i += 10) {
      final isMajor = i % 90 == 0;
      final isMinor = i % 30 == 0;
      final tickLen = isMajor ? radius * 0.15 : (isMinor ? radius * 0.1 : radius * 0.05);
      final rad = i * math.pi / 180;
      final outer = Offset(
        center.dx + math.sin(rad) * radius,
        center.dy - math.cos(rad) * radius,
      );
      final inner = Offset(
        center.dx + math.sin(rad) * (radius - tickLen),
        center.dy - math.cos(rad) * (radius - tickLen),
      );
      canvas.drawLine(outer, inner, isMajor ? majorTickPaint : tickPaint);
    }

    // Cardinal labels
    const cardinals = {'N': 0, 'E': 90, 'S': 180, 'W': 270};
    for (final entry in cardinals.entries) {
      final rad = entry.value * math.pi / 180;
      final labelRadius = radius * 0.72;
      final pos = Offset(
        center.dx + math.sin(rad) * labelRadius,
        center.dy - math.cos(rad) * labelRadius,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(
            color: entry.key == 'N' ? Colors.red : Colors.white70,
            fontSize: size * 0.08,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    // Wind direction arrow
    final arrowRad = dirDeg * math.pi / 180;
    final arrowLen = radius * 0.55;
    final arrowTip = Offset(
      center.dx + math.sin(arrowRad) * arrowLen,
      center.dy - math.cos(arrowRad) * arrowLen,
    );
    final arrowTail = Offset(
      center.dx - math.sin(arrowRad) * arrowLen * 0.3,
      center.dy + math.cos(arrowRad) * arrowLen * 0.3,
    );

    // Arrow body
    final arrowPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(arrowTail, arrowTip, arrowPaint);

    // Arrow head
    final headSize = radius * 0.12;
    final headAngle = 0.4;
    final leftHead = Offset(
      arrowTip.dx - math.sin(arrowRad + headAngle) * headSize,
      arrowTip.dy + math.cos(arrowRad + headAngle) * headSize,
    );
    final rightHead = Offset(
      arrowTip.dx - math.sin(arrowRad - headAngle) * headSize,
      arrowTip.dy + math.cos(arrowRad - headAngle) * headSize,
    );
    final headPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(leftHead.dx, leftHead.dy)
      ..lineTo(rightHead.dx, rightHead.dy)
      ..close();
    canvas.drawPath(
      headPath,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );

    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.dirDeg != dirDeg;
  }
}
