import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpyc_raceday/features/auth/data/auth_repository_impl.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';
import 'package:mpyc_raceday/features/auth/domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

final currentUserProvider = StreamProvider<Member?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.streamCurrentUser();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull != null;
});

final currentMemberRoleProvider = Provider<MemberRole?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.valueOrNull?.role;
});

final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(currentMemberRoleProvider);
  return role == MemberRole.admin;
});

final isProProvider = Provider<bool>((ref) {
  final role = ref.watch(currentMemberRoleProvider);
  return role == MemberRole.pro;
});

final isRcCrewProvider = Provider<bool>((ref) {
  final role = ref.watch(currentMemberRoleProvider);
  return role == MemberRole.rcCrew;
});

final isAdminOrProProvider = Provider<bool>((ref) {
  final role = ref.watch(currentMemberRoleProvider);
  return role == MemberRole.admin || role == MemberRole.pro;
});
