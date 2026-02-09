import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';

abstract class AuthRepository {
  const AuthRepository();

  /// Mobile flow: send verification code to member's email on file.
  /// Returns masked email and memberId.
  Future<({String maskedEmail, String memberId})> sendVerificationCode(
      String memberNumber);

  /// Mobile flow: verify the 6-digit code and sign in.
  /// Returns the authenticated Member.
  Future<Member> verifyCode(String memberId, String code);

  /// Web admin flow: sign in with email and password.
  Future<Member> signInWithEmail(String email, String password);

  /// Send password reset email (web admin).
  Future<void> sendPasswordReset(String email);

  /// Update password for current user (web admin).
  Future<void> updatePassword(String currentPassword, String newPassword);

  /// Get the currently authenticated Member, or null.
  Future<Member?> getCurrentUser();

  /// Stream of the current Member (null when signed out).
  Stream<Member?> streamCurrentUser();

  /// Stream of raw Firebase Auth state changes.
  Stream<User?> authStateChanges();

  /// Sign out.
  Future<void> signOut();

  /// Update emergency contact for the current member.
  Future<void> updateEmergencyContact(EmergencyContact contact);

  /// Update notification preferences for the current member.
  Future<void> updateNotificationPreferences(bool enabled);
}
