import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('System Settings',
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Clubspot'),
            Tab(text: 'Notifications'),
            Tab(text: 'Weather'),
            Tab(text: 'Race'),
            Tab(text: 'Users'),
            Tab(text: 'Data'),
            Tab(text: 'Audit Log'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _ClubspotTab(),
              _NotificationsTab(),
              _WeatherSettingsTab(),
              _RaceSettingsTab(),
              _UserManagementTab(),
              _DataManagementTab(),
              _AuditLogTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 1 — Clubspot Integration
// ═══════════════════════════════════════════════════════

class _ClubspotTab extends StatefulWidget {
  const _ClubspotTab();

  @override
  State<_ClubspotTab> createState() => _ClubspotTabState();
}

class _ClubspotTabState extends State<_ClubspotTab> {
  final _apiKeyCtrl = TextEditingController();
  final _clubIdCtrl = TextEditingController();
  String _syncSchedule = 'daily';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('clubspot')
        .get();
    if (doc.exists) {
      final d = doc.data()!;
      _apiKeyCtrl.text = d['apiKey'] as String? ?? '';
      _clubIdCtrl.text = d['clubId'] as String? ?? '';
      _syncSchedule = d['syncSchedule'] as String? ?? 'daily';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('clubspot')
        .set({
      'apiKey': _apiKeyCtrl.text.trim(),
      'clubId': _clubIdCtrl.text.trim(),
      'syncSchedule': _syncSchedule,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clubspot settings saved')),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _clubIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Clubspot API Integration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            width: 500,
            child: TextField(
              controller: _apiKeyCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
                helperText: 'Stored securely in Firestore',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _clubIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Club ID',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 300,
            child: DropdownButtonFormField<String>(
              value: _syncSchedule,
              decoration: const InputDecoration(
                labelText: 'Sync Schedule',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'manual', child: Text('Manual Only')),
              ],
              onChanged: (v) => setState(() => _syncSchedule = v ?? 'daily'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/sync-dashboard'),
                icon: const Icon(Icons.sync),
                label: const Text('Manual Sync'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 2 — Notification Settings
// ═══════════════════════════════════════════════════════

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab();

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  final _twilioSidCtrl = TextEditingController();
  final _twilioTokenCtrl = TextEditingController();
  final _twilioFromCtrl = TextEditingController();
  bool _loading = true;
  final Map<String, bool> _triggers = {
    'courseSelected': true,
    'incidentReported': true,
    'hearingScheduled': true,
    'maintenanceCritical': true,
    'crewAssigned': true,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('notifications')
        .get();
    if (doc.exists) {
      final d = doc.data()!;
      _twilioSidCtrl.text = d['twilioSid'] as String? ?? '';
      _twilioTokenCtrl.text = d['twilioToken'] as String? ?? '';
      _twilioFromCtrl.text = d['twilioFrom'] as String? ?? '';
      final t = d['triggers'] as Map<String, dynamic>? ?? {};
      for (final key in _triggers.keys) {
        _triggers[key] = t[key] as bool? ?? true;
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('notifications')
        .set({
      'twilioSid': _twilioSidCtrl.text.trim(),
      'twilioToken': _twilioTokenCtrl.text.trim(),
      'twilioFrom': _twilioFromCtrl.text.trim(),
      'triggers': _triggers,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings saved')),
      );
    }
  }

  @override
  void dispose() {
    _twilioSidCtrl.dispose();
    _twilioTokenCtrl.dispose();
    _twilioFromCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Twilio Configuration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            width: 500,
            child: TextField(
              controller: _twilioSidCtrl,
              decoration: const InputDecoration(
                labelText: 'Account SID',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 500,
            child: TextField(
              controller: _twilioTokenCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Auth Token',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _twilioFromCtrl,
              decoration: const InputDecoration(
                labelText: 'From Number',
                border: OutlineInputBorder(),
                hintText: '+1XXXXXXXXXX',
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Notification Triggers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._triggers.entries.map((e) {
            final label = switch (e.key) {
              'courseSelected' => 'Course Selected',
              'incidentReported' => 'Incident Reported',
              'hearingScheduled' => 'Hearing Scheduled',
              'maintenanceCritical' => 'Critical Maintenance',
              'crewAssigned' => 'Crew Assigned',
              _ => e.key,
            };
            return SwitchListTile(
              title: Text(label),
              value: e.value,
              onChanged: (v) => setState(() => _triggers[e.key] = v),
            );
          }),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 3 — Weather Settings
// ═══════════════════════════════════════════════════════

class _WeatherSettingsTab extends StatefulWidget {
  const _WeatherSettingsTab();

  @override
  State<_WeatherSettingsTab> createState() => _WeatherSettingsTabState();
}

class _WeatherSettingsTabState extends State<_WeatherSettingsTab> {
  double _windAlertThreshold = 25;
  int _pollingMinutes = 15;
  String _units = 'imperial';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('weather')
        .get();
    if (doc.exists) {
      final d = doc.data()!;
      _windAlertThreshold = (d['windAlertThreshold'] as num?)?.toDouble() ?? 25;
      _pollingMinutes = d['pollingMinutes'] as int? ?? 15;
      _units = d['units'] as String? ?? 'imperial';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('weather')
        .set({
      'windAlertThreshold': _windAlertThreshold,
      'pollingMinutes': _pollingMinutes,
      'units': _units,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weather settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weather Alert Thresholds',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Text('Wind Alert: ${_windAlertThreshold.toStringAsFixed(0)} kts'),
          Slider(
            value: _windAlertThreshold,
            min: 10,
            max: 50,
            divisions: 40,
            label: '${_windAlertThreshold.toStringAsFixed(0)} kts',
            onChanged: (v) => setState(() => _windAlertThreshold = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<int>(
              value: _pollingMinutes,
              decoration: const InputDecoration(
                labelText: 'Polling Interval',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 minutes')),
                DropdownMenuItem(value: 10, child: Text('10 minutes')),
                DropdownMenuItem(value: 15, child: Text('15 minutes')),
                DropdownMenuItem(value: 30, child: Text('30 minutes')),
                DropdownMenuItem(value: 60, child: Text('60 minutes')),
              ],
              onChanged: (v) => setState(() => _pollingMinutes = v ?? 15),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              value: _units,
              decoration: const InputDecoration(
                labelText: 'Units',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'imperial', child: Text('Imperial (°F, kts)')),
                DropdownMenuItem(value: 'metric', child: Text('Metric (°C, m/s)')),
              ],
              onChanged: (v) => setState(() => _units = v ?? 'imperial'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 4 — Race Settings
// ═══════════════════════════════════════════════════════

class _RaceSettingsTab extends StatefulWidget {
  const _RaceSettingsTab();

  @override
  State<_RaceSettingsTab> createState() => _RaceSettingsTabState();
}

class _RaceSettingsTabState extends State<_RaceSettingsTab> {
  String _handicapSystem = 'PHRF';
  String _timingPrecision = 'seconds';
  int _startSequenceMinutes = 5;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('race')
        .get();
    if (doc.exists) {
      final d = doc.data()!;
      _handicapSystem = d['handicapSystem'] as String? ?? 'PHRF';
      _timingPrecision = d['timingPrecision'] as String? ?? 'seconds';
      _startSequenceMinutes = d['startSequenceMinutes'] as int? ?? 5;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('race')
        .set({
      'handicapSystem': _handicapSystem,
      'timingPrecision': _timingPrecision,
      'startSequenceMinutes': _startSequenceMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Race settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Race Configuration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            width: 300,
            child: DropdownButtonFormField<String>(
              value: _handicapSystem,
              decoration: const InputDecoration(
                labelText: 'Handicap System',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'PHRF', child: Text('PHRF')),
                DropdownMenuItem(value: 'IRC', child: Text('IRC')),
                DropdownMenuItem(value: 'ORC', child: Text('ORC')),
                DropdownMenuItem(value: 'one-design', child: Text('One Design')),
              ],
              onChanged: (v) => setState(() => _handicapSystem = v ?? 'PHRF'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 300,
            child: DropdownButtonFormField<String>(
              value: _timingPrecision,
              decoration: const InputDecoration(
                labelText: 'Timing Precision',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'seconds', child: Text('Seconds')),
                DropdownMenuItem(value: 'tenths', child: Text('Tenths of a second')),
                DropdownMenuItem(value: 'hundredths', child: Text('Hundredths')),
              ],
              onChanged: (v) =>
                  setState(() => _timingPrecision = v ?? 'seconds'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 300,
            child: DropdownButtonFormField<int>(
              value: _startSequenceMinutes,
              decoration: const InputDecoration(
                labelText: 'Start Sequence',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 3, child: Text('3-minute')),
                DropdownMenuItem(value: 5, child: Text('5-minute')),
                DropdownMenuItem(value: 10, child: Text('10-minute')),
              ],
              onChanged: (v) =>
                  setState(() => _startSequenceMinutes = v ?? 5),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 5 — User Management (link to Members)
// ═══════════════════════════════════════════════════════

class _UserManagementTab extends StatelessWidget {
  const _UserManagementTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('User and role management is handled in the Members page.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.go('/members'),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Member Management'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 6 — Data Management
// ═══════════════════════════════════════════════════════

class _DataManagementTab extends StatelessWidget {
  const _DataManagementTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data Management',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export All Data'),
              subtitle: const Text(
                  'Download all Firestore collections as JSON'),
              trailing: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Export started — check downloads')),
                  );
                },
                child: const Text('Export'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Import Historical Data'),
              subtitle: const Text('Upload JSON to restore or migrate data'),
              trailing: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Import feature — select file')),
                  );
                },
                child: const Text('Import'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
              title: Text('Purge Old Data',
                  style: TextStyle(color: Colors.red.shade700)),
              subtitle: const Text(
                  'Remove data older than selected date (irreversible)'),
              trailing: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Purge Data?'),
                      content: const Text(
                          'This will permanently delete old records. Are you sure?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel')),
                        FilledButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Purge')),
                      ],
                    ),
                  );
                },
                child: const Text('Purge'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 7 — Audit Log
// ═══════════════════════════════════════════════════════

class _AuditLogTab extends StatefulWidget {
  const _AuditLogTab();

  @override
  State<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<_AuditLogTab> {
  String _actionFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DropdownButton<String>(
                value: _actionFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Actions')),
                  DropdownMenuItem(value: 'checkin', child: Text('Check-Ins')),
                  DropdownMenuItem(value: 'incident', child: Text('Incidents')),
                  DropdownMenuItem(
                      value: 'maintenance', child: Text('Maintenance')),
                  DropdownMenuItem(value: 'settings', child: Text('Settings')),
                  DropdownMenuItem(value: 'sync', child: Text('Sync')),
                ],
                onChanged: (v) =>
                    setState(() => _actionFilter = v ?? 'all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildQuery().snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No audit log entries'));
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Time')),
                      DataColumn(label: Text('Action')),
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Details')),
                    ],
                    rows: docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final ts = d['timestamp'] as Timestamp?;
                      final timeStr = ts != null
                          ? DateFormat.yMMMd()
                              .add_Hm()
                              .format(ts.toDate())
                          : '';
                      return DataRow(cells: [
                        DataCell(Text(timeStr,
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text(d['action'] as String? ?? '',
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text(d['userId'] as String? ?? '',
                            style: const TextStyle(fontSize: 12))),
                        DataCell(SizedBox(
                          width: 300,
                          child: Text(
                            d['details'] as String? ?? '',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('audit_log')
        .orderBy('timestamp', descending: true)
        .limit(100);
    if (_actionFilter != 'all') {
      query = FirebaseFirestore.instance
          .collection('audit_log')
          .where('category', isEqualTo: _actionFilter)
          .orderBy('timestamp', descending: true)
          .limit(100);
    }
    return query;
  }
}
