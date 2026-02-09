import 'package:flutter/material.dart';

/// Reusable confirmation dialog for destructive or important actions.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  Color? confirmColor,
  bool isDangerous = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: isDangerous || confirmColor != null
              ? FilledButton.styleFrom(
                  backgroundColor: confirmColor ?? Colors.red)
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Pre-built confirmation dialogs for common actions.
class ConfirmDialogs {
  const ConfirmDialogs._();

  static Future<bool> delete(BuildContext context, {String? itemName}) {
    return showConfirmDialog(
      context,
      title: 'Delete${itemName != null ? ' $itemName' : ''}?',
      message: 'This action cannot be undone.',
      confirmText: 'Delete',
      isDangerous: true,
    );
  }

  static Future<bool> abandonChecklist(BuildContext context) {
    return showConfirmDialog(
      context,
      title: 'Abandon Checklist?',
      message:
          'Your progress will be lost. You can start a new checklist later.',
      confirmText: 'Abandon',
      isDangerous: true,
    );
  }

  static Future<bool> generalRecall(BuildContext context) {
    return showConfirmDialog(
      context,
      title: 'General Recall?',
      message:
          'This will reset the start sequence. All boats must return to the starting area.',
      confirmText: 'Recall',
      confirmColor: Colors.orange,
    );
  }

  static Future<bool> fleetBroadcast(BuildContext context,
      {required String courseNumber}) {
    return showConfirmDialog(
      context,
      title: 'Broadcast Course $courseNumber?',
      message:
          'This will send SMS and push notifications to all checked-in skippers.',
      confirmText: 'Broadcast',
      confirmColor: Colors.blue,
    );
  }

  static Future<bool> closeCheckins(BuildContext context) {
    return showConfirmDialog(
      context,
      title: 'Close Check-In?',
      message: 'No more boats will be able to check in. This cannot be undone.',
      confirmText: 'Close',
      isDangerous: true,
    );
  }
}
