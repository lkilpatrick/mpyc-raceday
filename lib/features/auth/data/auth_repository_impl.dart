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
      await _ensureUidDoc(uid, doc.data());
      return _memberFromDoc(doc);
    }
    final memberDoc = snap.docs.first;
    await _ensureUidDoc(uid, memberDoc.data());
    return _memberFromDoc(memberDoc);
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
    if (snap.docs.isNotEmpty) {
      await _ensureUidDoc(user.uid, snap.docs.first.data());
      return _memberFromDoc(snap.docs.first);
    }

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
        await _ensureUidDoc(user.uid, doc.data());
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
    // Parse roles — support both new List<String> 'roles' and legacy single 'role'
    final roles = <MemberRole>[];
    final rolesRaw = data['roles'];
    if (rolesRaw is List) {
      for (final r in rolesRaw) {
        final parsed = _parseRole(r as String);
        if (parsed != null) roles.add(parsed);
      }
    } else {
      // Legacy: single 'role' field
      final roleStr = data['role'] as String? ?? 'crew';
      final parsed = _parseRole(roleStr);
      roles.add(parsed ?? MemberRole.crew);
    }
    if (roles.isEmpty) roles.add(MemberRole.crew);

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

    DateTime? lastLogin;
    final lastLoginRaw = data['lastLogin'];
    if (lastLoginRaw is Timestamp) {
      lastLogin = lastLoginRaw.toDate();
    } else if (lastLoginRaw is String) {
      lastLogin = DateTime.tryParse(lastLoginRaw);
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
      roles: roles,
      lastSynced: lastSynced,
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      emergencyContact: EmergencyContact(
        name: emergencyData['name'] as String? ?? 'Unknown',
        phone: emergencyData['phone'] as String? ?? '',
      ),
      signalNumber: data['signalNumber'] as String?,
      boatName: data['boatName'] as String?,
      sailNumber: data['sailNumber'] as String?,
      boatClass: data['boatClass'] as String?,
      phrfRating: (data['phrfRating'] as num?)?.toInt(),
      firebaseUid: data['firebaseUid'] as String?,
      lastLogin: lastLogin,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  static const _roleStringMap = {
    'web_admin': MemberRole.webAdmin,
    'webAdmin': MemberRole.webAdmin,
    'club_board': MemberRole.clubBoard,
    'clubBoard': MemberRole.clubBoard,
    'rc_chair': MemberRole.rcChair,
    'rcChair': MemberRole.rcChair,
    'skipper': MemberRole.skipper,
    'crew': MemberRole.crew,
    // Legacy mappings
    'admin': MemberRole.webAdmin,
    'pro': MemberRole.rcChair,
    'rc_crew': MemberRole.crew,
    'member': MemberRole.crew,
  };

  static MemberRole? _parseRole(String roleStr) => _roleStringMap[roleStr];

  /// Ensure a member document exists at /members/{uid} so Firestore security
  /// rules (which look up roles via `get(/members/$(request.auth.uid))`)
  /// can find the user's roles. The canonical member doc may be keyed by
  /// Clubspot ID; this writes a mirror keyed by Firebase Auth UID.
  Future<void> _ensureUidDoc(String uid, Map<String, dynamic> data) async {
    try {
      final uidDocRef = _firestore.collection('members').doc(uid);
      final uidDoc = await uidDocRef.get();
      if (uidDoc.exists) {
        // Keep roles in sync
        final existingRoles = uidDoc.data()?['roles'];
        final newRoles = data['roles'];
        if (existingRoles?.toString() != newRoles?.toString()) {
          await uidDocRef.update({
            'roles': newRoles,
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } else {
          await uidDocRef.update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
        return;
      }
      // Write a copy with the UID as doc ID
      await uidDocRef.set({
        ...data,
        'firebaseUid': uid,
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-fatal: the UID doc may already exist from seed script
    }
  }
}
