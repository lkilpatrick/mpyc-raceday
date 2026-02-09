import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';
import 'package:mpyc_raceday/features/auth/domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Future<({String maskedEmail, String memberId})> sendVerificationCode(
      String memberNumber) async {
    final callable = _functions.httpsCallable('sendVerificationCode');
    final result = await callable.call<Map<String, dynamic>>(
      {'memberNumber': memberNumber},
    );
    final data = result.data;
    return (
      maskedEmail: data['maskedEmail'] as String,
      memberId: data['memberId'] as String,
    );
  }

  @override
  Future<Member> verifyCode(String memberId, String code) async {
    final callable = _functions.httpsCallable('verifyCodeAndCreateToken');
    final result = await callable.call<Map<String, dynamic>>(
      {'memberId': memberId, 'code': code},
    );
    final data = result.data;
    final customToken = data['customToken'] as String;

    // Sign in with the custom token
    await _auth.signInWithCustomToken(customToken);

    // Fetch and return the member
    final member = await _fetchMember(memberId);
    if (member == null) {
      throw Exception('Member document not found after verification');
    }
    return member;
  }

  @override
  Future<Member> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user?.uid;
    if (uid == null) throw Exception('Sign in failed');

    // Look up member by firebaseUid
    final snap = await _firestore
        .collection('members')
        .where('firebaseUid', isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      // Try matching by email
      final emailSnap = await _firestore
          .collection('members')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (emailSnap.docs.isEmpty) {
        throw Exception('No member record linked to this account');
      }
      final doc = emailSnap.docs.first;
      // Link the UID
      await doc.reference.update({'firebaseUid': uid});
      return _memberFromDoc(doc);
    }
    return _memberFromDoc(snap.docs.first);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No authenticated user');
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  @override
  Future<Member?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Try by UID first
    final snap = await _firestore
        .collection('members')
        .where('firebaseUid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return _memberFromDoc(snap.docs.first);

    // Fallback: match by email
    if (user.email != null) {
      final emailSnap = await _firestore
          .collection('members')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      if (emailSnap.docs.isNotEmpty) {
        final doc = emailSnap.docs.first;
        await doc.reference.update({'firebaseUid': user.uid});
        return _memberFromDoc(doc);
      }
    }
    return null;
  }

  @override
  Stream<Member?> streamCurrentUser() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return getCurrentUser();
    });
  }

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updateEmergencyContact(EmergencyContact contact) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final snap = await _firestore
        .collection('members')
        .where('firebaseUid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) throw Exception('Member not found');

    await snap.docs.first.reference.update({
      'emergencyContact': {'name': contact.name, 'phone': contact.phone},
    });
  }

  @override
  Future<void> updateNotificationPreferences(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final snap = await _firestore
        .collection('members')
        .where('firebaseUid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) throw Exception('Member not found');

    await snap.docs.first.reference.update({
      'notificationsEnabled': enabled,
    });
  }

  Future<Member?> _fetchMember(String memberId) async {
    final doc = await _firestore.collection('members').doc(memberId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _memberFromSnapshot(doc.id, doc.data()!);
  }

  Member _memberFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _memberFromSnapshot(doc.id, doc.data());
  }

  Member _memberFromSnapshot(String id, Map<String, dynamic> data) {
    final roleStr = data['role'] as String? ?? 'member';
    final role = MemberRole.values.firstWhere(
      (r) =>
          r.name == roleStr ||
          (roleStr == 'rc_crew' && r == MemberRole.rcCrew),
      orElse: () => MemberRole.member,
    );

    final emergencyData =
        data['emergencyContact'] as Map<String, dynamic>? ??
            {'name': 'Unknown', 'phone': ''};

    final lastSyncedRaw = data['lastSynced'];
    DateTime lastSynced;
    if (lastSyncedRaw is Timestamp) {
      lastSynced = lastSyncedRaw.toDate();
    } else if (lastSyncedRaw is String) {
      lastSynced = DateTime.tryParse(lastSyncedRaw) ?? DateTime.now();
    } else {
      lastSynced = DateTime.now();
    }

    return Member(
      id: id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      mobileNumber: data['mobileNumber'] as String? ?? '',
      memberNumber: data['memberNumber'] as String? ?? '',
      membershipStatus: data['membershipStatus'] as String? ?? '',
      membershipCategory: data['membershipCategory'] as String? ?? '',
      memberTags: List<String>.from(data['memberTags'] ?? []),
      clubspotId: data['clubspotId'] as String? ?? '',
      role: role,
      lastSynced: lastSynced,
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      emergencyContact: EmergencyContact(
        name: emergencyData['name'] as String? ?? 'Unknown',
        phone: emergencyData['phone'] as String? ?? '',
      ),
    );
  }
}
