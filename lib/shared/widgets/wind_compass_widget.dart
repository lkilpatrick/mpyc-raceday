import 'dart:math' as math;

import 'package:flutter/material.dart';

class WindCompassWidget extends StatelessWidget {
  const WindCompassWidget({
    super.key,
    required this.windSpeedKts,
    this.windGustKts,
    required this.windDirectionDeg,
    this.windDirectionLabel = '',
    this.size = 200,
  });

  final double windSpeedKts;
  final double? windGustKts;
  final double windDirectionDeg;
  final String windDirectionLabel;
  final double size;

  Color get _ringColor {
    if (windSpeedKts >= 34) return Colors.red;
    if (windSpeedKts >= 25) return Colors.orange;
    if (windSpeedKts >= 15) return Colors.yellow.shade700;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _ringColor, width: 6),
              color: Colors.grey.shade900.withValues(alpha: 0.3),
            ),
          ),

          // Compass rose labels
          ..._compassLabels(),

          // Wind direction arrow (animated)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: windDirectionDeg,
              end: windDirectionDeg,
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, angle, child) {
              return Transform.rotate(
                angle: angle * math.pi / 180,
                child: CustomPaint(
                  size: Size(size * 0.7, size * 0.7),
                  painter: _ArrowPainter(color: _ringColor),
                ),
              );
            },
          ),

          // Center: wind speed
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                windSpeedKts.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                'kts',
                style: TextStyle(
                  fontSize: size * 0.07,
                  color: Colors.white70,
                ),
              ),
              if (windGustKts != null && windGustKts! > windSpeedKts)
                Text(
                  'G ${windGustKts!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: size * 0.08,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _compassLabels() {
    const labels = ['N', 'E', 'S', 'W'];
    const angles = [0.0, 90.0, 180.0, 270.0];
    final widgets = <Widget>[];

    for (int i = 0; i < labels.length; i++) {
      final rad = angles[i] * math.pi / 180;
      final r = size / 2 - 16;
      final x = r * math.sin(rad);
      final y = -r * math.cos(rad);

      widgets.add(
        Positioned(
          left: size / 2 + x - 8,
          top: size / 2 + y - 8,
          child: Text(
            labels[i],
            style: TextStyle(
              color: Colors.white54,
              fontSize: size * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final arrowLen = size.height * 0.35;

    // Arrow pointing up (from direction)
    final path = Path()
      ..moveTo(cx, cy - arrowLen)
      ..lineTo(cx - 8, cy - arrowLen + 20)
      ..lineTo(cx + 8, cy - arrowLen + 20)
      ..close();

    // Shaft
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, cy - arrowLen / 2 + 10),
        width: 3,
        height: arrowLen - 10,
      ),
      paint,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      color != oldDelegate.color;
}
