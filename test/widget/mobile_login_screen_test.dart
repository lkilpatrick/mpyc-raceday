import 'dart:convert';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/auth/data/auth_providers.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';
import 'package:mpyc_raceday/features/auth/domain/auth_repository.dart';
import 'package:mpyc_raceday/features/auth/presentation/mobile/login_screen.dart';

final _transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key == 'AssetManifest.bin' || key == 'AssetManifest.smcbin') {
      return Future.value(
        const StandardMessageCodec().encodeMessage(<Object?, Object?>{}),
      );
    }
    if (key == 'assets/images/burgee.png') {
      return Future.value(
        ByteData.sublistView(Uint8List.fromList(_transparentPng)),
      );
    }
    return Future.error(FlutterError('Unable to load asset: $key'));
  }

  @override
  Future<ui.ImmutableBuffer> loadBuffer(String key) {
    if (key == 'assets/images/burgee.png') {
      return ui.ImmutableBuffer.fromUint8List(
        Uint8List.fromList(_transparentPng),
      );
    }
    return Future.error(FlutterError('Unable to load asset: $key'));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      Future.error(FlutterError('Unable to load asset: $key'));
}

class _FakeAuthRepository extends AuthRepository {
  String? lastIdentifier;
  String? lastPassword;
  Object? signInError;

  @override
  Future<Member> signInWithEmail(String email, String password) {
    lastIdentifier = email;
    lastPassword = password;
    return Future.error(signInError ?? Exception('Sign in failed'));
  }

  @override
  Future<({String maskedEmail, String memberId})> sendVerificationCode(
    String memberNumber,
  ) => Future.error(UnimplementedError());

  @override
  Future<Member> verifyCode(String memberId, String code) =>
      Future.error(UnimplementedError());

  @override
  Future<void> sendPasswordReset(String email) =>
      Future.error(UnimplementedError());

  @override
  Future<void> updatePassword(String currentPassword, String newPassword) =>
      Future.error(UnimplementedError());

  @override
  Future<Member?> getCurrentUser() => Future.value(null);

  @override
  Stream<Member?> streamCurrentUser() => const Stream.empty();

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  Future<void> signOut() => Future.error(UnimplementedError());

  @override
  Future<void> updateEmergencyContact(EmergencyContact contact) =>
      Future.error(UnimplementedError());

  @override
  Future<void> updateNotificationPreferences(bool enabled) =>
      Future.error(UnimplementedError());
}

Widget _buildApp(AuthRepository repo) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
    child: DefaultAssetBundle(
      bundle: _FakeAssetBundle(),
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
}

void main() {
  testWidgets('renders email/signal + password sign-in form', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeAuthRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Email or Signal Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    expect(
      find.text('A verification code will be sent to your email on file.'),
      findsNothing,
    );
    expect(find.text('Signal Number or Member Number'), findsNothing);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('invalid credentials calls signInWithEmail and shows error', (
    tester,
  ) async {
    final repo = _FakeAuthRepository()
      ..signInError = FirebaseAuthException(code: 'invalid-credential');
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email or Signal Number'),
      'sailor@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(repo.lastIdentifier, 'sailor@example.com');
    expect(repo.lastPassword, 'secret123');
    expect(
      find.text('Invalid email, signal number, or password.'),
      findsOneWidget,
    );
  });
}
