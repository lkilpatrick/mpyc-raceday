import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/features/checklists/data/models/checklist.dart';

void main() {
  group('ChecklistItem model', () {
    test('critical items are identified', () {
      final item = ChecklistItem(
        id: 'i1',
        title: 'Check PFDs',
        description: 'Verify all PFDs aboard',
        category: 'Safety',
        requiresPhoto: false,
        requiresNote: false,
        isCritical: true,
        order: 1,
      );
      expect(item.isCritical, true);
      expect(item.requiresPhoto, false);
    });

    test('non-critical items', () {
      final item = ChecklistItem(
        id: 'i2',
        title: 'Clean deck',
        description: 'Hose down deck',
        category: 'Post-Race',
        requiresPhoto: false,
        requiresNote: false,
        isCritical: false,
        order: 2,
      );
      expect(item.isCritical, false);
    });
  });

  group('ChecklistCompletion progress', () {
    test('calculates progress from completed items', () {
      final completion = ChecklistCompletion(
        id: 'c1',
        checklistId: 'cl1',
        eventId: 'e1',
        completedBy: 'user1',
        startedAt: DateTime(2024, 6, 15, 8, 0),
        items: [
          CompletedItem(
            itemId: 'i1',
            checked: true,
            timestamp: DateTime(2024, 6, 15, 8, 5),
          ),
          CompletedItem(
            itemId: 'i2',
            checked: false,
            timestamp: DateTime(2024, 6, 15, 8, 5),
          ),
          CompletedItem(
            itemId: 'i3',
            checked: true,
            timestamp: DateTime(2024, 6, 15, 8, 10),
          ),
        ],
        status: ChecklistCompletionStatus.inProgress,
      );

      final checked = completion.items.where((i) => i.checked).length;
      final total = completion.items.length;
      final progress = total > 0 ? checked / total : 0.0;

      expect(checked, 2);
      expect(total, 3);
      expect(progress, closeTo(0.667, 0.01));
    });

    test('all critical items done enables sign-off', () {
      final criticalIds = {'i1', 'i3'};
      final completedItems = [
        CompletedItem(
          itemId: 'i1',
          checked: true,
          timestamp: DateTime.now(),
        ),
        CompletedItem(
          itemId: 'i2',
          checked: false,
          timestamp: DateTime.now(),
        ),
        CompletedItem(
          itemId: 'i3',
          checked: true,
          timestamp: DateTime.now(),
        ),
      ];

      final allCriticalDone = criticalIds.every((id) {
        final item = completedItems.where((i) => i.itemId == id).firstOrNull;
        return item?.checked ?? false;
      });

      expect(allCriticalDone, true);
    });

    test('missing critical item blocks sign-off', () {
      final criticalIds = {'i1', 'i3'};
      final completedItems = [
        CompletedItem(
          itemId: 'i1',
          checked: true,
          timestamp: DateTime.now(),
        ),
        CompletedItem(
          itemId: 'i3',
          checked: false,
          timestamp: DateTime.now(),
        ),
      ];

      final allCriticalDone = criticalIds.every((id) {
        final item = completedItems.where((i) => i.itemId == id).firstOrNull;
        return item?.checked ?? false;
      });

      expect(allCriticalDone, false);
    });
  });

  group('ChecklistCompletionStatus', () {
    test('all statuses exist', () {
      expect(ChecklistCompletionStatus.values, hasLength(3));
      expect(ChecklistCompletionStatus.values,
          contains(ChecklistCompletionStatus.inProgress));
      expect(ChecklistCompletionStatus.values,
          contains(ChecklistCompletionStatus.completedPendingSignoff));
      expect(ChecklistCompletionStatus.values,
          contains(ChecklistCompletionStatus.signedOff));
    });
  });

  group('CompletedItem with notes and photos', () {
    test('item with note', () {
      final item = CompletedItem(
        itemId: 'i1',
        checked: true,
        note: 'One PFD needs replacement',
        timestamp: DateTime.now(),
      );
      expect(item.note, isNotNull);
      expect(item.note, contains('replacement'));
    });

    test('item with photo URL', () {
      final item = CompletedItem(
        itemId: 'i1',
        checked: true,
        photoUrl: 'https://storage.example.com/photo.jpg',
        timestamp: DateTime.now(),
      );
      expect(item.photoUrl, isNotNull);
    });
  });
}
