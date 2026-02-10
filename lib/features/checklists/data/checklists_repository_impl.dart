import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/checklists_repository.dart';
import 'models/checklist.dart';

class ChecklistsRepositoryImpl implements ChecklistsRepository {
  ChecklistsRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _templatesCol =>
      _firestore.collection('checklists');

  CollectionReference<Map<String, dynamic>> get _completionsCol =>
      _firestore.collection('checklist_completions');

  // ── Helpers ──

  static const _typeMap = {
    'preRace': ChecklistType.preRace,
    'postRace': ChecklistType.postRace,
    'safety': ChecklistType.safety,
    'custom': ChecklistType.custom,
  };

  static String _typeToString(ChecklistType t) =>
      _typeMap.entries.firstWhere((e) => e.value == t).key;

  static ChecklistType _typeFromString(String s) =>
      _typeMap[s] ?? ChecklistType.custom;

  static const _statusMap = {
    'inProgress': ChecklistCompletionStatus.inProgress,
    'completedPendingSignoff': ChecklistCompletionStatus.completedPendingSignoff,
    'signedOff': ChecklistCompletionStatus.signedOff,
  };

  static String _statusToString(ChecklistCompletionStatus s) =>
      _statusMap.entries.firstWhere((e) => e.value == s).key;

  static ChecklistCompletionStatus _statusFromString(String s) =>
      _statusMap[s] ?? ChecklistCompletionStatus.inProgress;

  Checklist _checklistFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final rawItems = d['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((raw) {
      final m = raw as Map<String, dynamic>;
      return ChecklistItem(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        category: m['category'] as String? ?? '',
        requiresPhoto: m['requiresPhoto'] as bool? ?? false,
        requiresNote: m['requiresNote'] as bool? ?? false,
        isCritical: m['isCritical'] as bool? ?? false,
        order: m['order'] as int? ?? 0,
      );
    }).toList();

    DateTime lastModifiedAt;
    final modRaw = d['lastModifiedAt'];
    if (modRaw is Timestamp) {
      lastModifiedAt = modRaw.toDate();
    } else {
      lastModifiedAt = DateTime.now();
    }

    return Checklist(
      id: doc.id,
      name: d['name'] as String? ?? '',
      type: _typeFromString(d['type'] as String? ?? 'custom'),
      items: items,
      version: d['version'] as int? ?? 1,
      lastModifiedBy: d['lastModifiedBy'] as String? ?? '',
      lastModifiedAt: lastModifiedAt,
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _checklistToMap(Checklist checklist) {
    return {
      'name': checklist.name,
      'type': _typeToString(checklist.type),
      'items': checklist.items
          .map((i) => {
                'id': i.id,
                'title': i.title,
                'description': i.description,
                'category': i.category,
                'requiresPhoto': i.requiresPhoto,
                'requiresNote': i.requiresNote,
                'isCritical': i.isCritical,
                'order': i.order,
              })
          .toList(),
      'version': checklist.version,
      'lastModifiedBy': checklist.lastModifiedBy,
      'lastModifiedAt': Timestamp.fromDate(checklist.lastModifiedAt),
      'isActive': checklist.isActive,
    };
  }

  ChecklistCompletion _completionFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final rawItems = d['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((raw) {
      final m = raw as Map<String, dynamic>;
      DateTime ts;
      final tsRaw = m['timestamp'];
      if (tsRaw is Timestamp) {
        ts = tsRaw.toDate();
      } else {
        ts = DateTime.now();
      }
      return CompletedItem(
        itemId: m['itemId'] as String? ?? '',
        checked: m['checked'] as bool? ?? false,
        note: m['note'] as String?,
        photoUrl: m['photoUrl'] as String?,
        timestamp: ts,
      );
    }).toList();

    DateTime startedAt;
    final startRaw = d['startedAt'];
    if (startRaw is Timestamp) {
      startedAt = startRaw.toDate();
    } else {
      startedAt = DateTime.now();
    }

    DateTime? completedAt;
    final compRaw = d['completedAt'];
    if (compRaw is Timestamp) {
      completedAt = compRaw.toDate();
    }

    DateTime? signOffAt;
    final signRaw = d['signOffAt'];
    if (signRaw is Timestamp) {
      signOffAt = signRaw.toDate();
    }

    return ChecklistCompletion(
      id: doc.id,
      checklistId: d['checklistId'] as String? ?? '',
      eventId: d['eventId'] as String? ?? '',
      completedBy: d['completedBy'] as String? ?? '',
      startedAt: startedAt,
      completedAt: completedAt,
      items: items,
      signOffBy: d['signOffBy'] as String?,
      signOffAt: signOffAt,
      status: _statusFromString(d['status'] as String? ?? 'inProgress'),
    );
  }

  Map<String, dynamic> _completionToMap(ChecklistCompletion c) {
    return {
      'checklistId': c.checklistId,
      'eventId': c.eventId,
      'completedBy': c.completedBy,
      'startedAt': Timestamp.fromDate(c.startedAt),
      'completedAt':
          c.completedAt != null ? Timestamp.fromDate(c.completedAt!) : null,
      'items': c.items
          .map((i) => {
                'itemId': i.itemId,
                'checked': i.checked,
                'note': i.note,
                'photoUrl': i.photoUrl,
                'timestamp': Timestamp.fromDate(i.timestamp),
              })
          .toList(),
      'signOffBy': c.signOffBy,
      'signOffAt':
          c.signOffAt != null ? Timestamp.fromDate(c.signOffAt!) : null,
      'status': _statusToString(c.status),
    };
  }

  // ── Templates ──

  @override
  Stream<List<Checklist>> watchTemplates() {
    return _templatesCol.snapshots().map(
          (snap) => snap.docs.map(_checklistFromDoc).toList(),
        );
  }

  @override
  Future<Checklist?> getTemplate(String checklistId) async {
    final doc = await _templatesCol.doc(checklistId).get();
    if (!doc.exists) return null;
    return _checklistFromDoc(doc);
  }

  @override
  Future<void> saveTemplate(Checklist checklist) async {
    await _templatesCol
        .doc(checklist.id)
        .set(_checklistToMap(checklist), SetOptions(merge: true));
  }

  @override
  Future<void> deleteTemplate(String checklistId) async {
    await _templatesCol.doc(checklistId).delete();
  }

  // ── Completions ──

  @override
  Stream<List<ChecklistCompletion>> watchActiveCompletions() {
    return _completionsCol
        .where('status', isEqualTo: 'inProgress')
        .snapshots()
        .map((snap) => snap.docs.map(_completionFromDoc).toList());
  }

  @override
  Stream<ChecklistCompletion> watchCompletion(String completionId) {
    return _completionsCol
        .doc(completionId)
        .snapshots()
        .map(_completionFromDoc);
  }

  @override
  Stream<List<ChecklistCompletion>> watchCompletionHistory({
    String? userId,
    String? checklistId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> query = _completionsCol.orderBy(
      'startedAt',
      descending: true,
    );
    if (userId != null) {
      query = query.where('completedBy', isEqualTo: userId);
    }
    if (checklistId != null) {
      query = query.where('checklistId', isEqualTo: checklistId);
    }
    if (startDate != null) {
      query = query.where(
        'startedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'startedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }
    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => _completionFromDoc(d))
              .toList(),
        );
  }

  @override
  Future<ChecklistCompletion> startChecklist({
    required String checklistId,
    required String eventId,
    required String userId,
  }) async {
    final template = await getTemplate(checklistId);
    if (template == null) throw Exception('Checklist template not found');

    final now = DateTime.now();
    final items = template.items
        .map((i) => CompletedItem(
              itemId: i.id,
              checked: false,
              timestamp: now,
            ))
        .toList();

    final completion = ChecklistCompletion(
      id: '',
      checklistId: checklistId,
      eventId: eventId,
      completedBy: userId,
      startedAt: now,
      items: items,
      status: ChecklistCompletionStatus.inProgress,
    );

    final docRef = await _completionsCol.add(_completionToMap(completion));
    return completion.copyWith(id: docRef.id);
  }

  @override
  Future<void> updateItem({
    required String completionId,
    required String itemId,
    required bool checked,
    String? note,
    String? photoUrl,
  }) async {
    final doc = await _completionsCol.doc(completionId).get();
    if (!doc.exists) return;
    final completion = _completionFromDoc(doc);

    final now = DateTime.now();
    final updatedItems = completion.items.map((item) {
      if (item.itemId != itemId) return item;
      return item.copyWith(
        checked: checked,
        note: note ?? item.note,
        photoUrl: photoUrl ?? item.photoUrl,
        timestamp: now,
      );
    }).toList();

    await _completionsCol.doc(completionId).update({
      'items': updatedItems
          .map((i) => {
                'itemId': i.itemId,
                'checked': i.checked,
                'note': i.note,
                'photoUrl': i.photoUrl,
                'timestamp': Timestamp.fromDate(i.timestamp),
              })
          .toList(),
    });
  }

  @override
  Future<void> requestSignOff(String completionId) async {
    await _completionsCol.doc(completionId).update({
      'status': 'completedPendingSignoff',
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> signOff({
    required String completionId,
    required String signOffUserId,
  }) async {
    await _completionsCol.doc(completionId).update({
      'status': 'signedOff',
      'signOffBy': signOffUserId,
      'signOffAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── Photo upload ──

  @override
  Future<String> uploadPhoto({
    required String completionId,
    required String itemId,
    required Uint8List imageBytes,
  }) async {
    final ref = _storage.ref('checklists/$completionId/$itemId.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putData(imageBytes, metadata);
    return await ref.getDownloadURL();
  }

}
