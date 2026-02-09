import 'package:flutter/material.dart';

import '../domain/crew_assignment_repository.dart';

String roleLabel(CrewRole role) {
  switch (role) {
    case CrewRole.pro:
      return 'PRO';
    case CrewRole.signalBoat:
      return 'Signal Boat';
    case CrewRole.markBoat:
      return 'Mark Boat';
    case CrewRole.safetyBoat:
      return 'Safety';
  }
}

String statusLabel(ConfirmationStatus status) {
  switch (status) {
    case ConfirmationStatus.pending:
      return 'Pending';
    case ConfirmationStatus.confirmed:
      return 'Confirmed';
    case ConfirmationStatus.declined:
      return 'Declined';
  }
}

Color statusColor(ConfirmationStatus status) {
  switch (status) {
    case ConfirmationStatus.pending:
      return Colors.orange;
    case ConfirmationStatus.confirmed:
      return Colors.green;
    case ConfirmationStatus.declined:
      return Colors.red;
  }
}

String eventStatusLabel(EventStatus status) {
  switch (status) {
    case EventStatus.scheduled:
      return 'Scheduled';
    case EventStatus.cancelled:
      return 'Cancelled';
    case EventStatus.completed:
      return 'Completed';
  }
}
