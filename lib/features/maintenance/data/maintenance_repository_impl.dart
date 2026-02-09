import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/maintenance_repository.dart';
import 'models/maintenance_request.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  MaintenanceRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _firestore.collection('maintenance_requests');

  CollectionReference<Map<String, dynamic>> get _scheduleCol =>
      _firestore.collection('scheduled_maintenance');

  // ── Enum helpers ──

  static const _priorityMap = {
    'low': MaintenancePriority.low,
    'medium': MaintenancePriority.medium,
    'high': MaintenancePriority.high,
    'critical': MaintenancePriority.critical,
  };
  static String _priorityToStr(MaintenancePriority p) =>
      _priorityMap.entries.firstWhere((e) => e.value == p).key;
  static MaintenancePriority _priorityFromStr(String s) =>
      _priorityMap[s] ?? MaintenancePriority.low;

  static const _statusMap = {
    'reported': MaintenanceStatus.reported,
    'acknowledged': MaintenanceStatus.acknowledged,
    'inProgress': MaintenanceStatus.inProgress,
    'awaitingParts': MaintenanceStatus.awaitingParts,
    'completed': MaintenanceStatus.completed,
    'deferred': MaintenanceStatus.deferred,
  };
  static String _statusToStr(MaintenanceStatus s) =>
      _statusMap.entries.firstWhere((e) => e.value == s).key;
  static MaintenanceStatus _statusFromStr(String s) =>
      _statusMap[s] ?? MaintenanceStatus.reported;

  static const _categoryMap = {
    'engine': MaintenanceCategory.engine,
    'electrical': MaintenanceCategory.electrical,
    'hull': MaintenanceCategory.hull,
    'rigging': MaintenanceCategory.rigging,
    'safety': MaintenanceCategory.safety,
    'electronics': MaintenanceCategory.electronics,
    'general': MaintenanceCategory.general,
  };
  static String _categoryToStr(MaintenanceCategory c) =>
      _categoryMap.entries.firstWhere((e) => e.value == c).key;
  static MaintenanceCategory _categoryFromStr(String s) =>
      _categoryMap[s] ?? MaintenanceCategory.general;

  // ── Doc conversion ──

  MaintenanceRequest _requestFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final commentsRaw = d['comments'] as List<dynamic>? ?? [];
    final comments = commentsRaw.map((raw) {
      final m = raw as Map<String, dynamic>;
      DateTime createdAt;
      final tsRaw = m['createdAt'];
      if (tsRaw is Timestamp) {
        createdAt = tsRaw.toDate();
      } else {
        createdAt = DateTime.now();
      }
      return MaintenanceComment(
        id: m['id'] as String? ?? '',
        authorId: m['authorId'] as String? ?? '',
        authorName: m['authorName'] as String? ?? '',
        text: m['text'] as String? ?? '',
        photoUrl: m['photoUrl'] as String?,
        createdAt: createdAt,
      );
    }).toList();

    DateTime reportedAt;
    final rRaw = d['reportedAt'];
    if (rRaw is Timestamp) {
      reportedAt = rRaw.toDate();
    } else {
      reportedAt = DateTime.now();
    }

    DateTime? completedAt;
    final cRaw = d['completedAt'];
    if (cRaw is Timestamp) completedAt = cRaw.toDate();

    final photosRaw = d['photos'] as List<dynamic>? ?? [];

    return MaintenanceRequest(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      priority: _priorityFromStr(d['priority'] as String? ?? 'low'),
      reportedBy: d['reportedBy'] as String? ?? '',
      reportedAt: reportedAt,
      assignedTo: d['assignedTo'] as String?,
      status: _statusFromStr(d['status'] as String? ?? 'reported'),
      photos: photosRaw.map((e) => e.toString()).toList(),
      completedAt: completedAt,
      completionNotes: d['completionNotes'] as String?,
      boatName: d['boatName'] as String? ?? '',
      category: _categoryFromStr(d['category'] as String? ?? 'general'),
      estimatedCost: (d['estimatedCost'] as num?)?.toDouble(),
      comments: comments,
    );
  }

  Map<String, dynamic> _requestToMap(MaintenanceRequest r) {
    return {
      'title': r.title,
      'description': r.description,
      'priority': _priorityToStr(r.priority),
      'reportedBy': r.reportedBy,
      'reportedAt': Timestamp.fromDate(r.reportedAt),
      'assignedTo': r.assignedTo,
      'status': _statusToStr(r.status),
      'photos': r.photos,
      'completedAt':
          r.completedAt != null ? Timestamp.fromDate(r.completedAt!) : null,
      'completionNotes': r.completionNotes,
      'boatName': r.boatName,
      'category': _categoryToStr(r.category),
      'estimatedCost': r.estimatedCost,
      'comments': r.comments
          .map((c) => {
                'id': c.id,
                'authorId': c.authorId,
                'authorName': c.authorName,
                'text': c.text,
                'photoUrl': c.photoUrl,
                'createdAt': Timestamp.fromDate(c.createdAt),
              })
          .toList(),
    };
  }

  ScheduledMaintenance _scheduleFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    DateTime? lastCompleted;
    final lcRaw = d['lastCompletedAt'];
    if (lcRaw is Timestamp) lastCompleted = lcRaw.toDate();
    DateTime? nextDue;
    final ndRaw = d['nextDueAt'];
    if (ndRaw is Timestamp) nextDue = ndRaw.toDate();

    return ScheduledMaintenance(
      id: doc.id,
      boatName: d['boatName'] as String? ?? '',
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      intervalDays: d['intervalDays'] as int? ?? 30,
      lastCompletedAt: lastCompleted,
      nextDueAt: nextDue,
    );
  }

  Map<String, dynamic> _scheduleToMap(ScheduledMaintenance s) {
    return {
      'boatName': s.boatName,
      'title': s.title,
      'description': s.description,
      'intervalDays': s.intervalDays,
      'lastCompletedAt': s.lastCompletedAt != null
          ? Timestamp.fromDate(s.lastCompletedAt!)
          : null,
      'nextDueAt':
          s.nextDueAt != null ? Timestamp.fromDate(s.nextDueAt!) : null,
    };
  }

  // ── Requests ──

  @override
  Stream<List<MaintenanceRequest>> watchRequests() {
    return _requestsCol
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_requestFromDoc).toList());
  }

  @override
  Stream<MaintenanceRequest> watchRequest(String requestId) {
    return _requestsCol.doc(requestId).snapshots().map(_requestFromDoc);
  }

  @override
  Future<MaintenanceRequest> createRequest(MaintenanceRequest request) async {
    final docRef = await _requestsCol.add(_requestToMap(request));
    return request.copyWith(id: docRef.id);
  }

  @override
  Future<void> updateRequest(MaintenanceRequest request) async {
    await _requestsCol
        .doc(request.id)
        .set(_requestToMap(request), SetOptions(merge: true));
  }

  @override
  Future<void> updateStatus(String requestId, MaintenanceStatus status,
      {String? completionNotes}) async {
    final updates = <String, dynamic>{'status': _statusToStr(status)};
    if (status == MaintenanceStatus.completed) {
      updates['completedAt'] = Timestamp.fromDate(DateTime.now());
    }
    if (completionNotes != null) {
      updates['completionNotes'] = completionNotes;
    }
    await _requestsCol.doc(requestId).update(updates);
  }

  @override
  Future<void> assignRequest(String requestId, String assignedTo) async {
    await _requestsCol.doc(requestId).update({'assignedTo': assignedTo});
  }

  @override
  Future<void> bulkUpdateStatus(
      List<String> requestIds, MaintenanceStatus status) async {
    final batch = _firestore.batch();
    for (final id in requestIds) {
      batch.update(_requestsCol.doc(id), {'status': _statusToStr(status)});
    }
    await batch.commit();
  }

  // ── Comments ──

  @override
  Future<void> addComment(
      String requestId, MaintenanceComment comment) async {
    await _requestsCol.doc(requestId).update({
      'comments': FieldValue.arrayUnion([
        {
          'id': comment.id,
          'authorId': comment.authorId,
          'authorName': comment.authorName,
          'text': comment.text,
          'photoUrl': comment.photoUrl,
          'createdAt': Timestamp.fromDate(comment.createdAt),
        }
      ]),
    });
  }

  // ── Photos ──

  @override
  Future<String> uploadPhoto({
    required String requestId,
    required Uint8List imageBytes,
    String? fileName,
  }) async {
    final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('maintenance/$requestId/$name');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putData(imageBytes, metadata);
    final url = await ref.getDownloadURL();

    // Also append to the request's photos array
    await _requestsCol.doc(requestId).update({
      'photos': FieldValue.arrayUnion([url]),
    });
    return url;
  }

  // ── Scheduled maintenance ──

  @override
  Stream<List<ScheduledMaintenance>> watchScheduledMaintenance() {
    return _scheduleCol
        .orderBy('nextDueAt')
        .snapshots()
        .map((snap) => snap.docs.map(_scheduleFromDoc).toList());
  }

  @override
  Future<void> saveScheduledMaintenance(ScheduledMaintenance item) async {
    await _scheduleCol
        .doc(item.id)
        .set(_scheduleToMap(item), SetOptions(merge: true));
  }

  @override
  Future<void> deleteScheduledMaintenance(String id) async {
    await _scheduleCol.doc(id).delete();
  }

  @override
  Future<void> seedScheduledMaintenance() async {
    final callable = FirebaseFunctions.instance
        .httpsCallable('seedScheduledMaintenance');
    await callable.call<void>();
  }
}
