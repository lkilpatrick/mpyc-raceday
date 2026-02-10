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

  bool get _isCalm => speed < 0.5;

  @override
  Widget build(BuildContext context) {
    final unitLabel = unit == WindSpeedUnit.kts ? 'kts' : 'mph';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Hero: Wind Speed ──
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _isCalm ? 'Calm' : speed.toStringAsFixed(1),
              style: TextStyle(
                fontSize: size * 0.22,
                fontWeight: FontWeight.w800,
                color: _speedColor(speed, unit),
                height: 1,
              ),
            ),
            if (!_isCalm) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unitLabel,
                  style: TextStyle(
                    fontSize: size * 0.09,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (gust != null && gust! > speed) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.air, size: 14, color: Colors.orange.shade700),
              const SizedBox(width: 4),
              Text(
                'Gusts to ${gust!.toStringAsFixed(1)} $unitLabel',
                style: TextStyle(
                  fontSize: size * 0.065,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),

        // ── Compass ──
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CompassPainter(
              dirDeg: dirDeg,
              size: size,
              isCalm: _isCalm,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isCalm ? '---' : _compassLabel(dirDeg),
                    style: TextStyle(
                      fontSize: size * 0.14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  if (!_isCalm)
                    Text(
                      '$dirDeg°',
                      style: TextStyle(
                        fontSize: size * 0.08,
                        color: Colors.white70,
                      ),
                    ),
                  if (_isCalm)
                    Text(
                      'No wind',
                      style: TextStyle(
                        fontSize: size * 0.07,
                        color: Colors.white54,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Direction label below compass ──
        if (!_isCalm)
          Text(
            'Wind from ${_compassLabel(dirDeg)} ($dirDeg°)',
            style: TextStyle(
              fontSize: size * 0.065,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
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
    if (kts < 1) return Colors.grey;
    if (kts < 5) return Colors.green;
    if (kts < 12) return Colors.blue.shade700;
    if (kts < 20) return Colors.orange.shade800;
    if (kts < 30) return Colors.deepOrange;
    return Colors.red;
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.dirDeg,
    required this.size,
    required this.isCalm,
  });

  final int dirDeg;
  final double size;
  final bool isCalm;

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
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, ringPaint);

    // Inner ring
    canvas.drawCircle(
      center,
      radius * 0.42,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Tick marks
    final tickPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1;
    final majorTickPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2;
    final midTickPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.5;

    for (int i = 0; i < 360; i += 5) {
      final isMajor = i % 90 == 0;
      final isMid = i % 45 == 0;
      final isMinor = i % 15 == 0;
      if (!isMajor && !isMid && !isMinor && i % 5 != 0) continue;
      final tickLen = isMajor
          ? radius * 0.15
          : (isMid ? radius * 0.12 : (isMinor ? radius * 0.08 : radius * 0.04));
      final rad = i * math.pi / 180;
      final outer = Offset(
        center.dx + math.sin(rad) * radius,
        center.dy - math.cos(rad) * radius,
      );
      final inner = Offset(
        center.dx + math.sin(rad) * (radius - tickLen),
        center.dy - math.cos(rad) * (radius - tickLen),
      );
      canvas.drawLine(
        outer,
        inner,
        isMajor ? majorTickPaint : (isMid ? midTickPaint : tickPaint),
      );
    }

    // Cardinal labels
    const cardinals = {
      'N': 0.0,
      'NE': 45.0,
      'E': 90.0,
      'SE': 135.0,
      'S': 180.0,
      'SW': 225.0,
      'W': 270.0,
      'NW': 315.0,
    };
    for (final entry in cardinals.entries) {
      final isCardinal = entry.value % 90 == 0;
      final rad = entry.value * math.pi / 180;
      final labelRadius = radius * (isCardinal ? 0.72 : 0.74);
      final pos = Offset(
        center.dx + math.sin(rad) * labelRadius,
        center.dy - math.cos(rad) * labelRadius,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(
            color: entry.key == 'N'
                ? Colors.red.shade300
                : (isCardinal ? Colors.white : Colors.white54),
            fontSize: isCardinal ? size * 0.08 : size * 0.055,
            fontWeight: isCardinal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    // Wind direction arrow (only if not calm)
    if (!isCalm) {
      final arrowRad = dirDeg * math.pi / 180;
      final arrowLen = radius * 0.52;
      final arrowTip = Offset(
        center.dx + math.sin(arrowRad) * arrowLen,
        center.dy - math.cos(arrowRad) * arrowLen,
      );
      final arrowTail = Offset(
        center.dx - math.sin(arrowRad) * arrowLen * 0.35,
        center.dy + math.cos(arrowRad) * arrowLen * 0.35,
      );

      // Arrow shadow
      final shadowPaint = Paint()
        ..color = Colors.black26
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        arrowTail.translate(1, 1),
        arrowTip.translate(1, 1),
        shadowPaint,
      );

      // Arrow body
      final arrowPaint = Paint()
        ..color = Colors.red.shade400
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(arrowTail, arrowTip, arrowPaint);

      // Arrow head (filled triangle)
      final headSize = radius * 0.14;
      const headAngle = 0.45;
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
          ..color = Colors.red.shade400
          ..style = PaintingStyle.fill,
      );

      // Tail circle
      canvas.drawCircle(
        arrowTail,
        3,
        Paint()..color = Colors.red.shade300,
      );
    }

    // Center dot
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      3,
      Paint()..color = const Color(0xFF1B3A5C),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.dirDeg != dirDeg || oldDelegate.isCalm != isCalm;
  }
}
