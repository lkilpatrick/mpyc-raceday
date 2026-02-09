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
  return authState.value != null;
});

final currentRolesProvider = Provider<List<MemberRole>>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.value?.roles ?? [];
});

final isWebAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentRolesProvider).contains(MemberRole.webAdmin);
});

final isClubBoardProvider = Provider<bool>((ref) {
  return ref.watch(currentRolesProvider).any((r) =>
      [MemberRole.webAdmin, MemberRole.clubBoard].contains(r));
});

final isRCChairProvider = Provider<bool>((ref) {
  return ref.watch(currentRolesProvider).any((r) =>
      [MemberRole.webAdmin, MemberRole.rcChair].contains(r));
});

final isSkipperOrAboveProvider = Provider<bool>((ref) {
  return ref.watch(currentRolesProvider).any((r) => [
        MemberRole.webAdmin,
        MemberRole.rcChair,
        MemberRole.clubBoard,
        MemberRole.skipper,
      ].contains(r));
});

final canAccessWebDashboardProvider = Provider<bool>((ref) {
  return ref.watch(currentRolesProvider).any((r) => [
        MemberRole.webAdmin,
        MemberRole.clubBoard,
        MemberRole.rcChair,
      ].contains(r));
});
