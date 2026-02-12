import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralized audit logging service. Writes every significant
/// create / update / delete action to the `audit_logs` Firestore collection.
class AuditService {
  AuditService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('audit_logs');

  /// Log an action. [category] is used for filtering in the UI
  /// (e.g. 'checklist', 'incident', 'course', 'member', 'maintenance',
  /// 'settings', 'sync', 'checkin', 'crew', 'timing').
  /// [source] indicates origin: 'web', 'mobile', or 'system'.
  Future<void> log({
    required String action,
    required String entityType,
    required String entityId,
    required String category,
    Map<String, dynamic> details = const {},
    String? userId,
    String source = 'web',
  }) async {
    try {
      final uid =
          userId ?? FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final displayName =
          FirebaseAuth.instance.currentUser?.displayName ?? '';
      final email = FirebaseAuth.instance.currentUser?.email ?? '';

      await _col.add({
        'userId': uid,
        'userName': displayName.isNotEmpty
            ? displayName
            : email.isNotEmpty
                ? email
                : uid,
        'action': action,
        'category': category,
        'entityType': entityType,
        'entityId': entityId,
        'details': details,
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Audit logging is best-effort — never block the main operation
    }
  }
}

/// Global provider for the audit service.
final auditServiceProvider = Provider<AuditService>((ref) => AuditService());
