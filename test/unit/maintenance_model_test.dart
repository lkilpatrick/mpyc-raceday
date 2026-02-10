import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/maintenance/data/models/maintenance_request.dart';
import 'package:mpyc_raceday/features/maintenance/domain/maintenance_repository.dart';

void main() {
  group('MaintenancePriority', () {
    test('has all expected values', () {
      expect(MaintenancePriority.values, hasLength(4));
      expect(MaintenancePriority.values, contains(MaintenancePriority.low));
      expect(MaintenancePriority.values, contains(MaintenancePriority.medium));
      expect(MaintenancePriority.values, contains(MaintenancePriority.high));
      expect(
          MaintenancePriority.values, contains(MaintenancePriority.critical));
    });
  });

  group('MaintenanceStatus', () {
    test('has all expected values', () {
      expect(MaintenanceStatus.values, hasLength(6));
      expect(
          MaintenanceStatus.values, contains(MaintenanceStatus.reported));
      expect(MaintenanceStatus.values,
          contains(MaintenanceStatus.acknowledged));
      expect(
          MaintenanceStatus.values, contains(MaintenanceStatus.inProgress));
      expect(MaintenanceStatus.values,
          contains(MaintenanceStatus.awaitingParts));
      expect(
          MaintenanceStatus.values, contains(MaintenanceStatus.completed));
      expect(
          MaintenanceStatus.values, contains(MaintenanceStatus.deferred));
    });
  });

  group('MaintenanceCategory', () {
    test('has all expected values', () {
      expect(MaintenanceCategory.values, hasLength(7));
      expect(
          MaintenanceCategory.values, contains(MaintenanceCategory.engine));
      expect(MaintenanceCategory.values,
          contains(MaintenanceCategory.electrical));
      expect(MaintenanceCategory.values, contains(MaintenanceCategory.hull));
      expect(
          MaintenanceCategory.values, contains(MaintenanceCategory.rigging));
      expect(
          MaintenanceCategory.values, contains(MaintenanceCategory.safety));
      expect(MaintenanceCategory.values,
          contains(MaintenanceCategory.electronics));
      expect(
          MaintenanceCategory.values, contains(MaintenanceCategory.general));
    });
  });

  group('MaintenanceComment', () {
    test('creates with all fields', () {
      final comment = MaintenanceComment(
        id: 'mc1',
        authorId: 'u1',
        authorName: 'Admin',
        text: 'Parts ordered',
        createdAt: DateTime(2024, 6, 15),
      );

      expect(comment.id, 'mc1');
      expect(comment.authorId, 'u1');
      expect(comment.authorName, 'Admin');
      expect(comment.text, 'Parts ordered');
      expect(comment.photoUrl, isNull);
    });

    test('creates with optional photoUrl', () {
      final comment = MaintenanceComment(
        id: 'mc2',
        authorId: 'u1',
        authorName: 'Admin',
        text: 'Photo of damage',
        photoUrl: 'https://example.com/photo.jpg',
        createdAt: DateTime(2024, 6, 15),
      );

      expect(comment.photoUrl, 'https://example.com/photo.jpg');
    });

    test('copyWith preserves fields', () {
      final original = MaintenanceComment(
        id: 'mc1',
        authorId: 'u1',
        authorName: 'Admin',
        text: 'Original',
        createdAt: DateTime(2024, 6, 15),
      );

      final updated = original.copyWith(text: 'Updated');
      expect(updated.id, 'mc1');
      expect(updated.authorId, 'u1');
      expect(updated.authorName, 'Admin');
      expect(updated.text, 'Updated');
    });
  });

  group('MaintenanceRequest', () {
    MaintenanceRequest makeRequest({
      MaintenancePriority priority = MaintenancePriority.medium,
      MaintenanceStatus status = MaintenanceStatus.reported,
      MaintenanceCategory category = MaintenanceCategory.general,
    }) {
      return MaintenanceRequest(
        id: 'mr1',
        title: 'Engine oil leak',
        description: 'Oil leaking from port engine',
        priority: priority,
        reportedBy: 'skipper1',
        reportedAt: DateTime(2024, 6, 15),
        status: status,
        photos: const [],
        boatName: "Duncan's Watch",
        category: category,
        comments: const [],
      );
    }

    test('creates with required fields and defaults', () {
      final request = makeRequest();

      expect(request.id, 'mr1');
      expect(request.title, 'Engine oil leak');
      expect(request.description, contains('Oil leaking'));
      expect(request.priority, MaintenancePriority.medium);
      expect(request.reportedBy, 'skipper1');
      expect(request.status, MaintenanceStatus.reported);
      expect(request.photos, isEmpty);
      expect(request.boatName, "Duncan's Watch");
      expect(request.category, MaintenanceCategory.general);
      expect(request.assignedTo, isNull);
      expect(request.completedAt, isNull);
      expect(request.completionNotes, isNull);
      expect(request.estimatedCost, isNull);
      expect(request.comments, isEmpty);
    });

    test('creates with optional fields', () {
      final request = MaintenanceRequest(
        id: 'mr2',
        title: 'Replace winch',
        description: 'Starboard primary winch stripped',
        priority: MaintenancePriority.high,
        reportedBy: 'skipper2',
        reportedAt: DateTime(2024, 6, 10),
        assignedTo: 'tech1',
        status: MaintenanceStatus.inProgress,
        photos: ['https://example.com/winch.jpg'],
        completedAt: null,
        completionNotes: null,
        boatName: 'Signal Boat',
        category: MaintenanceCategory.rigging,
        estimatedCost: 450.0,
        comments: [
          MaintenanceComment(
            id: 'c1',
            authorId: 'u1',
            authorName: 'Tech',
            text: 'Ordered replacement',
            createdAt: DateTime(2024, 6, 11),
          ),
        ],
      );

      expect(request.assignedTo, 'tech1');
      expect(request.photos, hasLength(1));
      expect(request.estimatedCost, 450.0);
      expect(request.comments, hasLength(1));
    });

    test('copyWith updates single field', () {
      final original = makeRequest();
      final updated =
          original.copyWith(status: MaintenanceStatus.acknowledged);

      expect(updated.id, 'mr1');
      expect(updated.title, 'Engine oil leak');
      expect(updated.status, MaintenanceStatus.acknowledged);
      expect(updated.priority, MaintenancePriority.medium);
    });

    test('copyWith updates multiple fields', () {
      final original = makeRequest();
      final updated = original.copyWith(
        status: MaintenanceStatus.completed,
        completedAt: DateTime(2024, 6, 20),
        completionNotes: 'Fixed and tested',
      );

      expect(updated.status, MaintenanceStatus.completed);
      expect(updated.completedAt, DateTime(2024, 6, 20));
      expect(updated.completionNotes, 'Fixed and tested');
    });

    test('all priority levels', () {
      for (final p in MaintenancePriority.values) {
        final request = makeRequest(priority: p);
        expect(request.priority, p);
      }
    });

    test('all status values', () {
      for (final s in MaintenanceStatus.values) {
        final request = makeRequest(status: s);
        expect(request.status, s);
      }
    });

    test('all category values', () {
      for (final c in MaintenanceCategory.values) {
        final request = makeRequest(category: c);
        expect(request.category, c);
      }
    });
  });

  group('ScheduledMaintenance', () {
    test('creates with required fields', () {
      const item = ScheduledMaintenance(
        id: 'sm1',
        boatName: 'Signal Boat',
        title: 'Engine service',
        description: 'Change oil and filters',
        intervalDays: 90,
      );

      expect(item.id, 'sm1');
      expect(item.boatName, 'Signal Boat');
      expect(item.title, 'Engine service');
      expect(item.intervalDays, 90);
      expect(item.lastCompletedAt, isNull);
      expect(item.nextDueAt, isNull);
    });

    test('creates with optional dates', () {
      final item = ScheduledMaintenance(
        id: 'sm2',
        boatName: 'Mark Boat',
        title: 'Hull cleaning',
        description: 'Bottom scrub',
        intervalDays: 30,
        lastCompletedAt: DateTime(2024, 6, 1),
        nextDueAt: DateTime(2024, 7, 1),
      );

      expect(item.lastCompletedAt, DateTime(2024, 6, 1));
      expect(item.nextDueAt, DateTime(2024, 7, 1));
    });

    test('copyWith preserves unmodified fields', () {
      const original = ScheduledMaintenance(
        id: 'sm1',
        boatName: 'Signal Boat',
        title: 'Engine service',
        description: 'Change oil',
        intervalDays: 90,
      );

      final updated = original.copyWith(intervalDays: 60);
      expect(updated.id, 'sm1');
      expect(updated.boatName, 'Signal Boat');
      expect(updated.title, 'Engine service');
      expect(updated.intervalDays, 60);
    });

    test('copyWith can set dates', () {
      const original = ScheduledMaintenance(
        id: 'sm1',
        boatName: 'Signal Boat',
        title: 'Engine service',
        description: 'Change oil',
        intervalDays: 90,
      );

      final updated = original.copyWith(
        lastCompletedAt: DateTime(2024, 6, 15),
        nextDueAt: DateTime(2024, 9, 13),
      );
      expect(updated.lastCompletedAt, DateTime(2024, 6, 15));
      expect(updated.nextDueAt, DateTime(2024, 9, 13));
    });
  });
}
