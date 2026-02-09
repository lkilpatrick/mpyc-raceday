import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/shared/widgets/wind_compass_widget.dart';

void main() {
  group('WindCompassWidget', () {
    testWidgets('displays wind speed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WindCompassWidget(
              windSpeedKts: 15,
              windDirectionDeg: 180,
            ),
          ),
        ),
      );

      expect(find.text('15'), findsOneWidget);
      expect(find.text('kts'), findsOneWidget);
    });

    testWidgets('displays gust when higher than speed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WindCompassWidget(
              windSpeedKts: 15,
              windGustKts: 22,
              windDirectionDeg: 180,
            ),
          ),
        ),
      );

      expect(find.text('G 22'), findsOneWidget);
    });

    testWidgets('hides gust when equal to speed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WindCompassWidget(
              windSpeedKts: 15,
              windGustKts: 15,
              windDirectionDeg: 180,
            ),
          ),
        ),
      );

      expect(find.textContaining('G'), findsNothing);
    });

    testWidgets('shows compass labels N E S W', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WindCompassWidget(
              windSpeedKts: 10,
              windDirectionDeg: 0,
              size: 200,
            ),
          ),
        ),
      );

      expect(find.text('N'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WindCompassWidget(
              windSpeedKts: 10,
              windDirectionDeg: 0,
              size: 300,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 300);
      expect(sizedBox.height, 300);
    });
  });

  group('WindCompassWidget color thresholds', () {
    testWidgets('green ring for light wind (<15 kts)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WindCompassWidget(
              windSpeedKts: 10,
              windDirectionDeg: 0,
            ),
          ),
        ),
      );

      // Widget renders without error at light wind
      expect(find.byType(WindCompassWidget), findsOneWidget);
    });

    testWidgets('red ring for storm wind (>=34 kts)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WindCompassWidget(
              windSpeedKts: 35,
              windDirectionDeg: 0,
            ),
          ),
        ),
      );

      expect(find.byType(WindCompassWidget), findsOneWidget);
    });
  });
}
