import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

@freezed
abstract class AuditLog with _$AuditLog {
  const factory AuditLog({
    required String id,
    required String userId,
    required String action,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> details,
    required DateTime timestamp,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _$AuditLogFromJson(json);
}
