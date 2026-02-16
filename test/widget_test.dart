// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/main.dart';

class MockFirebasePlatform extends FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return FirebaseAppPlatform(
      name ?? '[DEFAULT]',
      options ?? const FirebaseOptions(
        apiKey: 'mock_api_key',
        appId: 'mock_app_id',
        messagingSenderId: 'mock_sender_id',
        projectId: 'mock_project_id',
      ),
    );
  }

  @override
  List<FirebaseAppPlatform> get apps => [
    FirebaseAppPlatform(
      '[DEFAULT]',
      const FirebaseOptions(
        apiKey: 'mock_api_key',
        appId: 'mock_app_id',
        messagingSenderId: 'mock_sender_id',
        projectId: 'mock_project_id',
      ),
    ),
  ];

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) {
    return FirebaseAppPlatform(
      name,
      const FirebaseOptions(
        apiKey: 'mock_api_key',
        appId: 'mock_app_id',
        messagingSenderId: 'mock_sender_id',
        projectId: 'mock_project_id',
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Install the mock platform
    FirebasePlatform.instance = MockFirebasePlatform();

    // Mock Firestore and Auth method channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_firestore'),
      (call) async {
        if (call.method == 'Firestore#addSnapshotsInSyncListener') {
          return <String, dynamic>{};
        }
        return null;
      },
    );
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_auth'),
      (call) async {
        return null;
      },
    );

    await Firebase.initializeApp();
  });

  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const MpycRacedayApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
