import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/maintenance_repository_impl.dart';
import '../data/models/maintenance_request.dart';
import '../domain/maintenance_repository.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepositoryImpl();
});

final maintenanceRequestsProvider =
    StreamProvider<List<MaintenanceRequest>>((ref) {
  return ref.watch(maintenanceRepositoryProvider).watchRequests();
});

final maintenanceDetailProvider =
    StreamProvider.family<MaintenanceRequest, String>((ref, requestId) {
  return ref.watch(maintenanceRepositoryProvider).watchRequest(requestId);
});

final scheduledMaintenanceProvider =
    StreamProvider<List<ScheduledMaintenance>>((ref) {
  return ref.watch(maintenanceRepositoryProvider).watchScheduledMaintenance();
});

final criticalMaintenanceCountProvider = Provider<AsyncValue<int>>((ref) {
  final requests = ref.watch(maintenanceRequestsProvider);
  return requests.whenData((items) => items
      .where((r) =>
          r.priority == MaintenancePriority.critical &&
          r.status != MaintenanceStatus.completed &&
          r.status != MaintenanceStatus.deferred)
      .length);
});
