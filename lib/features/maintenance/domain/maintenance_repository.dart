import 'dart:typed_data';



import '../data/models/maintenance_request.dart';



abstract class MaintenanceRepository {

  const MaintenanceRepository();



  // Requests

  Stream<List<MaintenanceRequest>> watchRequests();

  Stream<MaintenanceRequest> watchRequest(String requestId);

  Future<MaintenanceRequest> createRequest(MaintenanceRequest request);

  Future<void> updateRequest(MaintenanceRequest request);

  Future<void> updateStatus(String requestId, MaintenanceStatus status,

      {String? completionNotes});

  Future<void> assignRequest(String requestId, String assignedTo);

  Future<void> bulkUpdateStatus(

      List<String> requestIds, MaintenanceStatus status);

  Future<void> deleteRequest(String requestId);



  // Comments

  Future<void> addComment(String requestId, MaintenanceComment comment);



  // Photos

  Future<String> uploadPhoto({

    required String requestId,

    required Uint8List imageBytes,

    String? fileName,

  });



  // Scheduled maintenance

  Stream<List<ScheduledMaintenance>> watchScheduledMaintenance();

  Future<void> saveScheduledMaintenance(ScheduledMaintenance item);

  Future<void> deleteScheduledMaintenance(String id);

}



class ScheduledMaintenance {

  const ScheduledMaintenance({

    required this.id,

    required this.boatName,

    required this.title,

    required this.description,

    required this.intervalDays,

    this.lastCompletedAt,

    this.nextDueAt,

  });



  final String id;

  final String boatName;

  final String title;

  final String description;

  final int intervalDays;

  final DateTime? lastCompletedAt;

  final DateTime? nextDueAt;



  ScheduledMaintenance copyWith({

    String? id,

    String? boatName,

    String? title,

    String? description,

    int? intervalDays,

    DateTime? lastCompletedAt,

    DateTime? nextDueAt,

  }) {

    return ScheduledMaintenance(

      id: id ?? this.id,

      boatName: boatName ?? this.boatName,

      title: title ?? this.title,

      description: description ?? this.description,

      intervalDays: intervalDays ?? this.intervalDays,

      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,

      nextDueAt: nextDueAt ?? this.nextDueAt,

    );

  }

}

