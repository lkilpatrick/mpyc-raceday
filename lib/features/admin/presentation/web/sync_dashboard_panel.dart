import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SyncDashboardPanel extends StatefulWidget {
  const SyncDashboardPanel({super.key});

  @override
  State<SyncDashboardPanel> createState() => _SyncDashboardPanelState();
}

class _SyncDashboardPanelState extends State<SyncDashboardPanel> {
  bool _syncing = false;
  String? _syncMessage;

  static const _defaultSyncUrl =
      'https://manualmembersync-kxa7ukqkaq-uc.a.run.app';

  String? get _manualSyncUrl {
    if (!kIsWeb) {
      return dotenv.maybeGet('MANUAL_SYNC_URL') ?? _defaultSyncUrl;
    }
    const fromDefine = String.fromEnvironment('MANUAL_SYNC_URL');
    return fromDefine.isNotEmpty ? fromDefine : _defaultSyncUrl;
  }

  @override
  Widget build(BuildContext context) {
    final logsStream = FirebaseFirestore.instance
        .collection('memberSyncLogs')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: logsStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final latest = docs.isNotEmpty ? docs.first.data() : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Member Sync Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const Icon(Icons.autorenew, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Auto-refresh enabled',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  label: 'Last Sync',
                  value: _formatTimestamp(latest?['timestamp']),
                ),
                _MetricCard(label: 'New', value: '${latest?['newCount'] ?? 0}'),
                _MetricCard(
                  label: 'Updated',
                  value: '${latest?['updatedCount'] ?? 0}',
                ),
                _MetricCard(
                  label: 'Unchanged',
                  value: '${latest?['unchangedCount'] ?? 0}',
                ),
              ],
            ),
            if (_syncMessage != null) ...[
              const SizedBox(height: 8),
              Text(_syncMessage!),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _syncing ? null : _syncNow,
              icon: _syncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(_syncing ? 'Syncing...' : 'Sync Now'),
            ),
            const SizedBox(height: 16),
            Text(
              'Sync History (Last 30)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = docs[index].data();
                  final errors = (row['errors'] as List?) ?? const [];
                  return ListTile(
                    title: Text(_formatTimestamp(row['timestamp'])),
                    subtitle: Text(
                      'new ${row['newCount'] ?? 0} • updated ${row['updatedCount'] ?? 0} • unchanged ${row['unchangedCount'] ?? 0}',
                    ),
                    trailing: errors.isEmpty
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : Tooltip(
                            message: errors.join('\n'),
                            child: Icon(
                              Icons.error,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncNow() async {
    final url = _manualSyncUrl;
    if (url == null || url.isEmpty) {
      setState(() => _syncMessage = 'Missing MANUAL_SYNC_URL configuration.');
      return;
    }

    setState(() {
      _syncing = true;
      _syncMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(const <String, dynamic>{}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _syncMessage =
              'Sync complete: new ${body['newCount'] ?? 0}, updated ${body['updatedCount'] ?? 0}, unchanged ${body['unchangedCount'] ?? 0}';
        });
      } else {
        setState(() {
          _syncMessage =
              'Sync failed (${response.statusCode}): ${response.body}';
        });
      }
    } catch (error) {
      setState(() => _syncMessage = 'Sync failed: $error');
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  String _formatTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toLocal().toString();
    }
    return '—';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
