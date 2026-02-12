import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../demo_mode_service.dart';

/// Screen to activate demo mode — creates a test race with sample data.
class DemoModeScreen extends StatefulWidget {
  const DemoModeScreen({super.key});

  @override
  State<DemoModeScreen> createState() => _DemoModeScreenState();
}

class _DemoModeScreenState extends State<DemoModeScreen> {
  bool _loading = false;
  String? _demoEventId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    setState(() => _loading = true);
    try {
      final id = await DemoModeService.getTodaysDemoEventId();
      if (mounted) setState(() => _demoEventId = id);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createDemo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = await DemoModeService.createDemoRace();
      if (mounted) {
        setState(() => _demoEventId = id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo race created with sample boats!')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cleanupDemo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clean Up Demo Data?'),
        content: const Text(
            'This will delete all demo race events, boats, and check-ins. '
            'Real data will not be affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Demo Data')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await DemoModeService.cleanupDemoData();
      if (mounted) {
        setState(() => _demoEventId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo data cleaned up')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Mode')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.science, color: Colors.amber.shade800, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Demo Mode',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.amber.shade900)),
                              const SizedBox(height: 4),
                              const Text(
                                'Simulate a race day to test features. '
                                'Creates a test event with sample boats and check-ins. '
                                'No notifications will be sent.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_error != null) ...[
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Error: $_error',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Demo status
                if (_demoEventId != null) ...[
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 24),
                              const SizedBox(width: 8),
                              const Text('Demo Race Active',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '10 sample boats · 6 checked in · Course not yet set',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick actions for the demo race
                  const Text('Test Features',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),

                  _DemoAction(
                    icon: Icons.map,
                    label: 'Select Course',
                    subtitle: 'Pick a course for the demo race',
                    color: Colors.blue,
                    onTap: () =>
                        context.push('/courses/select/$_demoEventId'),
                  ),
                  _DemoAction(
                    icon: Icons.timer,
                    label: 'Start Sequence (Rule 26)',
                    subtitle: 'Run the 5-4-1-Go horn sequence',
                    color: Colors.green,
                    onTap: () =>
                        context.push('/timing/start/$_demoEventId'),
                  ),
                  _DemoAction(
                    icon: Icons.how_to_reg,
                    label: 'Boat Check-In',
                    subtitle: 'View and manage boat check-ins',
                    color: Colors.teal,
                    onTap: () =>
                        context.push('/checkin/$_demoEventId'),
                  ),
                  _DemoAction(
                    icon: Icons.sports_score,
                    label: 'Record Finishes',
                    subtitle: 'Tap to record finish times',
                    color: Colors.orange,
                    onTap: () =>
                        context.push('/timing/$_demoEventId'),
                  ),
                  _DemoAction(
                    icon: Icons.campaign,
                    label: 'Fleet Broadcast',
                    subtitle: 'Send course/status to fleet (demo only)',
                    color: Colors.red,
                    onTap: () =>
                        context.push('/courses/broadcast/$_demoEventId'),
                  ),
                  _DemoAction(
                    icon: Icons.gps_fixed,
                    label: 'Race Mode (Skipper)',
                    subtitle: 'GPS tracking during the race',
                    color: Colors.indigo,
                    onTap: () => context.push('/race-mode'),
                  ),
                  _DemoAction(
                    icon: Icons.report,
                    label: 'Report Incident',
                    subtitle: 'File a test protest',
                    color: Colors.amber,
                    onTap: () =>
                        context.push('/incidents/report/$_demoEventId'),
                  ),

                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _cleanupDemo,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clean Up Demo Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ] else ...[
                  // No demo active — show create button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _createDemo,
                      icon: const Icon(Icons.play_arrow, size: 28),
                      label: const Text('Create Demo Race',
                          style: TextStyle(fontSize: 18)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This will create:\n'
                    '• A "Demo Race Day" event for today\n'
                    '• 10 sample boats across 4 fleets\n'
                    '• 6 pre-checked-in boats with crew\n'
                    '• All features available for testing',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ],
            ),
    );
  }
}

class _DemoAction extends StatelessWidget {
  const _DemoAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle:
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
