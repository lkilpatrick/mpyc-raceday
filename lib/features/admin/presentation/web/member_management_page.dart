import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:mpyc_raceday/shared/services/clubspot_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MemberManagementPage extends StatefulWidget {
  const MemberManagementPage({super.key});

  @override
  State<MemberManagementPage> createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends State<MemberManagementPage> {
  final _service = ClubspotService();
  final _searchController = TextEditingController();
  final Set<String> _selectedIds = <String>{};
  String _search = '';
  String _sortBy = 'lastName';
  bool _asc = true;
  Map<String, dynamic>? _expandedMember;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance.collection('members').snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final members =
            snapshot.data?.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList() ??
            <Map<String, dynamic>>[];

        final filtered =
            members.where((member) {
              if (_search.isEmpty) return true;
              final haystack = [
                member['firstName'],
                member['lastName'],
                member['email'],
                member['mobileNumber'],
                member['memberNumber'],
                member['membershipStatus'],
                member['membershipCategory'],
              ].join(' ').toLowerCase();
              return haystack.contains(_search.toLowerCase());
            }).toList()..sort((a, b) {
              final left = (a[_sortBy] ?? '').toString();
              final right = (b[_sortBy] ?? '').toString();
              return _asc ? left.compareTo(right) : right.compareTo(left);
            });

        return Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search / filter members',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _search = value),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _exportCsv(filtered),
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                ),
                PopupMenuButton<String>(
                  enabled: _selectedIds.isNotEmpty,
                  tooltip: 'Bulk role assignment',
                  onSelected: (role) => _bulkAssignRole(role),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'admin', child: Text('Assign admin')),
                    PopupMenuItem(value: 'pro', child: Text('Assign pro')),
                    PopupMenuItem(
                      value: 'rc_crew',
                      child: Text('Assign rc_crew'),
                    ),
                    PopupMenuItem(
                      value: 'member',
                      child: Text('Assign member'),
                    ),
                  ],
                  child: FilledButton.icon(
                    onPressed: _selectedIds.isEmpty ? null : () {},
                    icon: const Icon(Icons.groups),
                    label: Text('Bulk Role (${_selectedIds.length})'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: DataTable2(
                sortAscending: _asc,
                sortColumnIndex: _sortColumnIndex,
                columns: [
                  const DataColumn2(label: Text('Name'), size: ColumnSize.L),
                  const DataColumn2(label: Text('Email'), size: ColumnSize.L),
                  const DataColumn2(label: Text('Mobile')),
                  _sortableColumn('Member #', 'memberNumber', 3),
                  _sortableColumn('Membership Status', 'membershipStatus', 4),
                  _sortableColumn('Category', 'membershipCategory', 5),
                  const DataColumn2(label: Text('Tags')),
                  const DataColumn2(label: Text('App Role')),
                  _sortableColumn('Last Synced', 'lastSynced', 8),
                ],
                rows: filtered.map((member) {
                  final id = member['id'].toString();
                  final selected = _selectedIds.contains(id);
                  final tags =
                      (member['memberTags'] as List?)?.join(', ') ?? '';
                  return DataRow2(
                    selected: selected,
                    onTap: () => setState(() => _expandedMember = member),
                    onSelectChanged: (_) => setState(() {
                      if (selected) {
                        _selectedIds.remove(id);
                      } else {
                        _selectedIds.add(id);
                      }
                    }),
                    cells: [
                      DataCell(
                        Text(
                          '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'
                              .trim(),
                        ),
                      ),
                      DataCell(Text('${member['email'] ?? ''}')),
                      DataCell(Text('${member['mobileNumber'] ?? ''}')),
                      DataCell(Text('${member['memberNumber'] ?? ''}')),
                      DataCell(Text('${member['membershipStatus'] ?? ''}')),
                      DataCell(Text('${member['membershipCategory'] ?? ''}')),
                      DataCell(Text(tags)),
                      DataCell(
                        DropdownButton<String>(
                          value: '${member['role'] ?? 'member'}',
                          items: const [
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('admin'),
                            ),
                            DropdownMenuItem(value: 'pro', child: Text('pro')),
                            DropdownMenuItem(
                              value: 'rc_crew',
                              child: Text('rc_crew'),
                            ),
                            DropdownMenuItem(
                              value: 'member',
                              child: Text('member'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            _assignRole(id, value);
                          },
                        ),
                      ),
                      DataCell(Text(_formatTimestamp(member['lastSynced']))),
                    ],
                  );
                }).toList(),
              ),
            ),
            if (_expandedMember != null)
              Card(
                margin: const EdgeInsets.only(top: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Member detail: ${_expandedMember!['firstName'] ?? ''} ${_expandedMember!['lastName'] ?? ''}\n'
                          'Email: ${_expandedMember!['email'] ?? ''}\n'
                          'Mobile: ${_expandedMember!['mobileNumber'] ?? ''}\n'
                          'Clubspot ID: ${_expandedMember!['clubspotId'] ?? ''}',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openInClubspot,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open in Clubspot'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  DataColumn2 _sortableColumn(String label, String key, int index) {
    return DataColumn2(
      label: Text(label),
      onSort: (_, asc) {
        setState(() {
          _sortBy = key;
          _asc = asc;
        });
      },
    );
  }

  int? get _sortColumnIndex {
    switch (_sortBy) {
      case 'memberNumber':
        return 3;
      case 'membershipStatus':
        return 4;
      case 'membershipCategory':
        return 5;
      case 'lastSynced':
        return 8;
      default:
        return null;
    }
  }

  Future<void> _assignRole(String memberId, String role) {
    return FirebaseFirestore.instance.collection('members').doc(memberId).set({
      'role': role,
    }, SetOptions(merge: true));
  }

  Future<void> _bulkAssignRole(String role) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final id in _selectedIds) {
      final doc = FirebaseFirestore.instance.collection('members').doc(id);
      batch.set(doc, {'role': role}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> _openInClubspot() async {
    final memberNumber = '${_expandedMember?['memberNumber'] ?? ''}';
    if (memberNumber.isEmpty) return;

    try {
      final uri = await _service.createMemberPortalSession(memberNumber);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create Clubspot portal session.'),
        ),
      );
    }
  }

  Future<void> _exportCsv(List<Map<String, dynamic>> members) async {
    final rows = <List<String>>[
      const [
        'Name',
        'Email',
        'Mobile',
        'Member #',
        'Membership Status',
        'Category',
        'Tags',
        'App Role',
        'Last Synced',
      ],
      ...members.map((member) {
        final name = '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'
            .trim();
        return [
          name,
          '${member['email'] ?? ''}',
          '${member['mobileNumber'] ?? ''}',
          '${member['memberNumber'] ?? ''}',
          '${member['membershipStatus'] ?? ''}',
          '${member['membershipCategory'] ?? ''}',
          ((member['memberTags'] as List?) ?? const []).join('|'),
          '${member['role'] ?? 'member'}',
          _formatTimestamp(member['lastSynced']),
        ];
      }),
    ];

    final csv = rows
        .map((row) {
          return row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',');
        })
        .join('\n');

    final uri = Uri.parse(
      'data:text/csv;charset=utf-8,${Uri.encodeComponent(csv)}',
    );
    await launchUrl(uri);
  }

  String _formatTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate().toLocal().toString();
    return '';
  }
}
