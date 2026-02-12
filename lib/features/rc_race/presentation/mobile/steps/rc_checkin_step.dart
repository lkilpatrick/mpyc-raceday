import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../boat_checkin/presentation/boat_checkin_providers.dart';
import '../../../../boat_checkin/presentation/mobile/boat_checkin_screen.dart';
import '../../../data/models/race_session.dart';
import '../../rc_race_providers.dart';

/// Step 2: Boat check-in with real-time sync.
class RcCheckinStep extends ConsumerWidget {
  const RcCheckinStep({super.key, required this.session});

  final RaceSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(eventCheckinsProvider(session.id));
    // Derive isClosed from the session passed by parent — no extra listener
    final isClosed = session.checkinsClosed;

    return checkinsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (checkins) {
        final count = checkins.length;

        return Column(
          children: [
            // Check-in count hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.teal.withValues(alpha: 0.08),
              child: Column(
                children: [
                  Text('$count',
                      style: const TextStyle(
                          fontSize: 56, fontWeight: FontWeight.w900)),
                  const Text('boats checked in',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  if (isClosed)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Chip(
                        label: const Text('CHECK-IN CLOSED',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ),

            // Checked-in boats list
            Expanded(
              child: checkins.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sailing,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No boats checked in yet',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          const Text(
                            'Boats will appear here as skippers check in\nor as you add them from the fleet list.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: count,
                      itemBuilder: (_, i) {
                        final c = checkins[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                c.sailNumber.length > 3
                                    ? c.sailNumber.substring(
                                        c.sailNumber.length - 3)
                                    : c.sailNumber,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                                '${c.boatName} (${c.sailNumber})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '${c.skipperName} · ${c.crewCount} crew'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (c.safetyEquipmentVerified)
                                  const Icon(Icons.verified_user,
                                      color: Colors.green, size: 18),
                                if (c.phrfRating != null)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(left: 4),
                                    child: Text('PHRF ${c.phrfRating}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey)),
                                  ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline,
                                      color: Colors.red.shade300, size: 20),
                                  tooltip: 'Remove',
                                  onPressed: () => _removeCheckin(
                                      context, ref, c.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Manage check-ins button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _openFullCheckin(context),
                      icon: const Icon(Icons.edit),
                      label: const Text('Manage Check-Ins'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Proceed button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed:
                          count > 0 ? () => _proceedToStart(ref) : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        'Proceed to Start ($count boats)',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeCheckin(
      BuildContext context, WidgetRef ref, String checkinId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Check-In?'),
        content: const Text('This boat will be removed from the check-in list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(boatCheckinRepositoryProvider)
          .removeCheckin(checkinId);
      ref.invalidate(eventCheckinsProvider(session.id));
    }
  }

  void _openFullCheckin(BuildContext context) {
    // Push to existing full check-in screen
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullCheckinWrapper(eventId: session.id),
    ));
  }

  Future<void> _proceedToStart(WidgetRef ref) async {
    await ref
        .read(rcRaceRepositoryProvider)
        .updateStatus(session.id, RaceSessionStatus.startPending);
  }
}

/// Wrapper to push the existing BoatCheckinScreen as a full page.
class _FullCheckinWrapper extends StatelessWidget {
  const _FullCheckinWrapper({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return BoatCheckinScreen(eventId: eventId);
  }
}
