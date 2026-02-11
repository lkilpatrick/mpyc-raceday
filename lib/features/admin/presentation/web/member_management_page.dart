import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';
import 'package:mpyc_raceday/shared/services/audit_service.dart';
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
  Map<String, dynamic>? _detailMember;
  bool _activeOnly = true;

  static const _allRoles = [
    ('web_admin', 'Web Admin', Colors.red, Icons.shield),
    ('club_board', 'Club Board', Colors.purple, Icons.gavel),
    ('rc_chair', 'RC Chair', Colors.blue, Icons.flag),
    ('skipper', 'Skipper', Colors.teal, Icons.sailing),
    ('crew', 'Crew', Colors.grey, Icons.person),
  ];

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
              if (_activeOnly && member['isActive'] == false) return false;
              if (_search.isEmpty) return true;
              final haystack = [
                member['firstName'],
                member['lastName'],
                member['email'],
                member['mobileNumber'],
                member['memberNumber'],
                member['signalNumber'],
                member['boatName'],
                member['sailNumber'],
              ].join(' ').toLowerCase();
              return haystack.contains(_search.toLowerCase());
            }).toList()..sort((a, b) {
              final left = (a[_sortBy] ?? '').toString();
              final right = (b[_sortBy] ?? '').toString();
              return _asc ? left.compareTo(right) : right.compareTo(left);
            });

        return Row(
          children: [
            // Main table area
            Expanded(
              flex: _detailMember != null ? 3 : 1,
              child: Column(
                children: [
                  // Top bar
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 320,
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search members',
                            hintText: 'Name, signal #, email, boat...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) =>
                              setState(() => _search = value),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Active Only'),
                        selected: _activeOnly,
                        onSelected: (v) =>
                            setState(() => _activeOnly = v),
                      ),
                      FilledButton.icon(
                        onPressed: _showCreateMemberDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Member'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _exportCsv(filtered),
                        icon: const Icon(Icons.download),
                        label: const Text('Export CSV'),
                      ),
                      PopupMenuButton<String>(
                        enabled: _selectedIds.isNotEmpty,
                        tooltip: 'Bulk actions',
                        onSelected: _handleBulkAction,
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'add_role',
                            child: Text('Add role to selected'),
                          ),
                          const PopupMenuItem(
                            value: 'remove_role',
                            child: Text('Remove role from selected'),
                          ),
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Text('Deactivate selected'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete selected',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                        child: FilledButton.icon(
                          onPressed:
                              _selectedIds.isEmpty ? null : () {},
                          icon: const Icon(Icons.groups),
                          label: Text(
                              'Bulk (${_selectedIds.length})'),
                        ),
                      ),
                      Text(
                        'Showing ${filtered.length} of ${members.length} members',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Data table
                  Expanded(
                    child: DataTable2(
                      sortAscending: _asc,
                      sortColumnIndex: _sortColumnIndex,
                      columnSpacing: 12,
                      columns: [
                        _sortableColumn('Signal #', 'signalNumber', 0,
                            size: ColumnSize.S),
                        _sortableColumn('Name', 'lastName', 1,
                            size: ColumnSize.L),
                        const DataColumn2(
                            label: Text('Email'), size: ColumnSize.L),
                        const DataColumn2(label: Text('Phone')),
                        const DataColumn2(
                            label: Text('Roles'), size: ColumnSize.L),
                        _sortableColumn('Boat / Sail #', 'boatName', 5),
                        _sortableColumn('Status', 'membershipStatus', 6,
                            size: ColumnSize.S),
                        _sortableColumn('Last Login', 'lastLogin', 7),
                      ],
                      rows: filtered.map((member) {
                        final id = member['id'].toString();
                        final selected = _selectedIds.contains(id);
                        return DataRow2(
                          selected: selected,
                          onTap: () =>
                              setState(() => _detailMember = member),
                          onSelectChanged: (_) => setState(() {
                            if (selected) {
                              _selectedIds.remove(id);
                            } else {
                              _selectedIds.add(id);
                            }
                          }),
                          cells: [
                            DataCell(Text(
                              '${member['signalNumber'] ?? ''}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            )),
                            DataCell(Text(
                              '${member['lastName'] ?? ''}, ${member['firstName'] ?? ''}'
                                  .trim(),
                            )),
                            DataCell(Text('${member['email'] ?? ''}')),
                            DataCell(
                                Text('${member['mobileNumber'] ?? ''}')),
                            DataCell(_buildRoleChips(member)),
                            DataCell(Text(_boatDisplay(member))),
                            DataCell(_statusBadge(member)),
                            DataCell(Text(
                                _relativeTime(member['lastLogin']))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // Detail panel
            if (_detailMember != null) ...[
              const VerticalDivider(width: 1),
              SizedBox(
                width: 380,
                child: _MemberDetailPanel(
                  member: _detailMember!,
                  onClose: () => setState(() => _detailMember = null),
                  onRolesChanged: () => setState(() {}),
                  onEdit: () => _showEditMemberDialog(_detailMember!),
                  onDelete: () => _deleteMember(_detailMember!['id'] as String),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRoleChips(Map<String, dynamic> member) {
    final roles = _extractRoles(member);
    if (roles.isEmpty) {
      return Text('Unassigned',
          style: TextStyle(color: Colors.grey[400], fontSize: 12));
    }
    return Wrap(
      spacing: 4,
      children: roles.map((roleStr) {
        final match = _allRoles.where((r) => r.$1 == roleStr).firstOrNull;
        final label = match?.$2 ?? roleStr;
        final color = match?.$3 ?? Colors.grey;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        );
      }).toList(),
    );
  }

  Widget _statusBadge(Map<String, dynamic> member) {
    final isActive = member['isActive'] != false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green[700] : Colors.red[700],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _boatDisplay(Map<String, dynamic> member) {
    final boat = member['boatName'] as String? ?? '';
    final sail = member['sailNumber'] as String? ?? '';
    if (boat.isEmpty && sail.isEmpty) return '';
    if (sail.isEmpty) return boat;
    return '$boat ($sail)';
  }

  List<String> _extractRoles(Map<String, dynamic> member) {
    final rolesRaw = member['roles'];
    if (rolesRaw is List) return rolesRaw.cast<String>();
    final role = member['role'] as String?;
    if (role != null && role.isNotEmpty) return [role];
    return [];
  }

  DataColumn2 _sortableColumn(String label, String key, int index,
      {ColumnSize size = ColumnSize.M}) {
    return DataColumn2(
      label: Text(label),
      size: size,
      onSort: (_, asc) {
        setState(() {
          _sortBy = key;
          _asc = asc;
        });
      },
    );
  }

  int? get _sortColumnIndex {
    const map = {
      'signalNumber': 0,
      'lastName': 1,
      'boatName': 5,
      'membershipStatus': 6,
      'lastLogin': 7,
    };
    return map[_sortBy];
  }

  String _relativeTime(Object? value) {
    DateTime? dt;
    if (value is Timestamp) {
      dt = value.toDate();
    } else if (value is String) {
      dt = DateTime.tryParse(value);
    }
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(dt);
  }

  void _handleBulkAction(String action) {
    switch (action) {
      case 'add_role':
        _showBulkRoleDialog(add: true);
      case 'remove_role':
        _showBulkRoleDialog(add: false);
      case 'deactivate':
        _bulkDeactivate();
      case 'delete':
        _bulkDelete();
    }
  }

  Future<void> _showBulkRoleDialog({required bool add}) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(add ? 'Add Role' : 'Remove Role'),
        children: _allRoles
            .map((r) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, r.$1),
                  child: Row(
                    children: [
                      Icon(r.$4, color: r.$3, size: 18),
                      const SizedBox(width: 8),
                      Text(r.$2),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
    if (selected == null) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final id in _selectedIds) {
      final doc = FirebaseFirestore.instance.collection('members').doc(id);
      if (add) {
        batch.update(doc, {
          'roles': FieldValue.arrayUnion([selected]),
        });
      } else {
        batch.update(doc, {
          'roles': FieldValue.arrayRemove([selected]),
        });
      }
    }
    await batch.commit();
    final audit = AuditService();
    for (final id in _selectedIds) {
      audit.log(
        action: add ? 'add_role' : 'remove_role',
        entityType: 'member',
        entityId: id,
        category: 'settings',
        details: {'role': selected},
      );
    }
    setState(() => _selectedIds.clear());
  }

  Future<void> _bulkDeactivate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deactivate Members'),
        content: Text(
            'Deactivate ${_selectedIds.length} selected member(s)?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Deactivate')),
        ],
      ),
    );
    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();
    final audit = AuditService();
    for (final id in _selectedIds) {
      final doc = FirebaseFirestore.instance.collection('members').doc(id);
      batch.update(doc, {'isActive': false});
    }
    await batch.commit();
    for (final id in _selectedIds) {
      audit.log(
        action: 'deactivate_member',
        entityType: 'member',
        entityId: id,
        category: 'settings',
      );
    }
    setState(() => _selectedIds.clear());
  }

  void _showCreateMemberDialog() {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final memberNumCtrl = TextEditingController();
    final signalNumCtrl = TextEditingController();
    final boatNameCtrl = TextEditingController();
    final sailNumCtrl = TextEditingController();
    final boatClassCtrl = TextEditingController();
    final phrfCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Member'),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: firstNameCtrl,
                      decoration: const InputDecoration(labelText: 'First Name *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'First name is required' : null,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: lastNameCtrl,
                      decoration: const InputDecoration(labelText: 'Last Name *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
                    )),
                  ]),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email *'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(controller: memberNumCtrl, decoration: const InputDecoration(labelText: 'Member #'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: signalNumCtrl, decoration: const InputDecoration(labelText: 'Signal #'))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(controller: boatNameCtrl, decoration: const InputDecoration(labelText: 'Boat Name'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: sailNumCtrl, decoration: const InputDecoration(labelText: 'Sail #'))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(controller: boatClassCtrl, decoration: const InputDecoration(labelText: 'Boat Class'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: phrfCtrl, decoration: const InputDecoration(labelText: 'PHRF Rating'), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  Text('New members default to Crew role.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await FirebaseFirestore.instance.collection('members').add({
                'firstName': firstNameCtrl.text.trim(),
                'lastName': lastNameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'mobileNumber': phoneCtrl.text.trim(),
                'memberNumber': memberNumCtrl.text.trim(),
                'signalNumber': signalNumCtrl.text.trim(),
                'boatName': boatNameCtrl.text.trim(),
                'sailNumber': sailNumCtrl.text.trim(),
                'boatClass': boatClassCtrl.text.trim(),
                'phrfRating': int.tryParse(phrfCtrl.text.trim()),
                'roles': ['crew'],
                'membershipStatus': 'active',
                'membershipCategory': '',
                'memberTags': <String>[],
                'isActive': true,
                'emergencyContact': {'name': '', 'phone': ''},
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Add Member'),
          ),
        ],
      ),
    );
  }

  void _showEditMemberDialog(Map<String, dynamic> member) {
    final id = member['id'] as String;
    final firstNameCtrl = TextEditingController(text: member['firstName'] as String? ?? '');
    final lastNameCtrl = TextEditingController(text: member['lastName'] as String? ?? '');
    final emailCtrl = TextEditingController(text: member['email'] as String? ?? '');
    final phoneCtrl = TextEditingController(text: member['mobileNumber'] as String? ?? '');
    final memberNumCtrl = TextEditingController(text: member['memberNumber'] as String? ?? '');
    final signalNumCtrl = TextEditingController(text: member['signalNumber'] as String? ?? '');
    final boatNameCtrl = TextEditingController(text: member['boatName'] as String? ?? '');
    final sailNumCtrl = TextEditingController(text: member['sailNumber'] as String? ?? '');
    final boatClassCtrl = TextEditingController(text: member['boatClass'] as String? ?? '');
    final phrfCtrl = TextEditingController(text: '${member['phrfRating'] ?? ''}');
    final ecNameCtrl = TextEditingController(
        text: (member['emergencyContact'] as Map<String, dynamic>?)?['name'] as String? ?? '');
    final ecPhoneCtrl = TextEditingController(
        text: (member['emergencyContact'] as Map<String, dynamic>?)?['phone'] as String? ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Member'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(child: TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name'))),
                ]),
                const SizedBox(height: 8),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: memberNumCtrl, decoration: const InputDecoration(labelText: 'Member #'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: signalNumCtrl, decoration: const InputDecoration(labelText: 'Signal #'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: boatNameCtrl, decoration: const InputDecoration(labelText: 'Boat Name'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: sailNumCtrl, decoration: const InputDecoration(labelText: 'Sail #'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: boatClassCtrl, decoration: const InputDecoration(labelText: 'Boat Class'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: phrfCtrl, decoration: const InputDecoration(labelText: 'PHRF Rating'), keyboardType: TextInputType.number)),
                ]),
                const Divider(height: 24),
                Row(children: [
                  Expanded(child: TextField(controller: ecNameCtrl, decoration: const InputDecoration(labelText: 'Emergency Contact Name'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: ecPhoneCtrl, decoration: const InputDecoration(labelText: 'Emergency Phone'))),
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('members').doc(id).update({
                'firstName': firstNameCtrl.text.trim(),
                'lastName': lastNameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'mobileNumber': phoneCtrl.text.trim(),
                'memberNumber': memberNumCtrl.text.trim(),
                'signalNumber': signalNumCtrl.text.trim(),
                'boatName': boatNameCtrl.text.trim(),
                'sailNumber': sailNumCtrl.text.trim(),
                'boatClass': boatClassCtrl.text.trim(),
                'phrfRating': int.tryParse(phrfCtrl.text.trim()),
                'emergencyContact': {
                  'name': ecNameCtrl.text.trim(),
                  'phone': ecPhoneCtrl.text.trim(),
                },
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              setState(() => _detailMember = null);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMember(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Member'),
        content: const Text(
          'This will permanently delete this member record. This cannot be undone.\n\n'
          'If this member was synced from Clubspot, they will be re-created on the next sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.collection('members').doc(id).delete();
      setState(() => _detailMember = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _bulkDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Members'),
        content: Text(
          'Permanently delete ${_selectedIds.length} selected member(s)? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final id in _selectedIds) {
      batch.delete(FirebaseFirestore.instance.collection('members').doc(id));
    }
    await batch.commit();
    setState(() => _selectedIds.clear());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Members deleted')),
      );
    }
  }

  Future<void> _exportCsv(List<Map<String, dynamic>> members) async {
    final rows = <List<String>>[
      const [
        'Signal #',
        'Name',
        'Email',
        'Phone',
        'Member #',
        'Roles',
        'Boat',
        'Sail #',
        'Class',
        'PHRF',
        'Status',
        'Category',
        'Tags',
        'Last Login',
      ],
      ...members.map((member) {
        final name =
            '${member['lastName'] ?? ''}, ${member['firstName'] ?? ''}'
                .trim();
        return [
          '${member['signalNumber'] ?? ''}',
          name,
          '${member['email'] ?? ''}',
          '${member['mobileNumber'] ?? ''}',
          '${member['memberNumber'] ?? ''}',
          _extractRoles(member).join('|'),
          '${member['boatName'] ?? ''}',
          '${member['sailNumber'] ?? ''}',
          '${member['boatClass'] ?? ''}',
          '${member['phrfRating'] ?? ''}',
          '${member['membershipStatus'] ?? ''}',
          '${member['membershipCategory'] ?? ''}',
          ((member['memberTags'] as List?) ?? const []).join('|'),
          _relativeTime(member['lastLogin']),
        ];
      }),
    ];

    final csv = rows
        .map((row) {
          return row
              .map((cell) => '"${cell.replaceAll('"', '""')}"')
              .join(',');
        })
        .join('\n');

    final uri = Uri.parse(
      'data:text/csv;charset=utf-8,${Uri.encodeComponent(csv)}',
    );
    await launchUrl(uri);
  }
}

// ── Member Detail Slide-out Panel ──

class _MemberDetailPanel extends StatelessWidget {
  const _MemberDetailPanel({
    required this.member,
    required this.onClose,
    required this.onRolesChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> member;
  final VoidCallback onClose;
  final VoidCallback onRolesChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _roleEntries = [
    ('web_admin', 'Web Admin', Colors.red, Icons.shield),
    ('club_board', 'Club Board', Colors.purple, Icons.gavel),
    ('rc_chair', 'RC Chair', Colors.blue, Icons.flag),
    ('skipper', 'Skipper', Colors.teal, Icons.sailing),
    ('crew', 'Crew', Colors.grey, Icons.person),
  ];

  List<String> get _roles {
    final rolesRaw = member['roles'];
    if (rolesRaw is List) return rolesRaw.cast<String>();
    final role = member['role'] as String?;
    if (role != null) return [role];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final id = member['id'] as String;
    final firstName = member['firstName'] as String? ?? '';
    final lastName = member['lastName'] as String? ?? '';
    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';
    final emergencyContact =
        member['emergencyContact'] as Map<String, dynamic>? ??
            {'name': '', 'phone': ''};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue[700],
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$firstName $lastName',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (member['signalNumber'] != null)
                      Text('Signal #: ${member['signalNumber']}',
                          style: Theme.of(context).textTheme.bodySmall),
                    if (member['memberNumber'] != null)
                      Text('Member #: ${member['memberNumber']}',
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
          const Divider(height: 24),

          // Contact
          _sectionTitle(context, 'CONTACT'),
          _infoRow('Email', '${member['email'] ?? ''}'),
          _infoRow('Phone', '${member['mobileNumber'] ?? ''}'),
          _infoRow('Emergency',
              '${emergencyContact['name']} ${emergencyContact['phone']}'),
          const SizedBox(height: 16),

          // Membership
          _sectionTitle(context, 'MEMBERSHIP'),
          _infoRow('Status', '${member['membershipStatus'] ?? ''}'),
          _infoRow('Category', '${member['membershipCategory'] ?? ''}'),
          _infoRow('Tags',
              ((member['memberTags'] as List?) ?? []).join(', ')),
          _infoRow('Clubspot ID', '${member['clubspotId'] ?? ''}'),
          const SizedBox(height: 16),

          // Sailing
          _sectionTitle(context, 'SAILING'),
          _infoRow('Boat', '${member['boatName'] ?? ''}'),
          _infoRow('Sail #', '${member['sailNumber'] ?? ''}'),
          _infoRow('Class', '${member['boatClass'] ?? ''}'),
          _infoRow('PHRF', '${member['phrfRating'] ?? ''}'),
          const SizedBox(height: 16),

          // Roles
          _sectionTitle(context, 'ROLES'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _roleEntries.map((entry) {
              final hasRole = _roles.contains(entry.$1);
              return FilterChip(
                avatar: Icon(entry.$4, size: 16, color: entry.$3),
                label: Text(entry.$2),
                selected: hasRole,
                selectedColor: entry.$3.withValues(alpha: 0.2),
                onSelected: (selected) {
                  final doc = FirebaseFirestore.instance
                      .collection('members')
                      .doc(id);
                  if (selected) {
                    doc.update({
                      'roles': FieldValue.arrayUnion([entry.$1]),
                    });
                  } else {
                    doc.update({
                      'roles': FieldValue.arrayRemove([entry.$1]),
                    });
                  }
                  AuditService().log(
                    action: selected ? 'add_role' : 'remove_role',
                    entityType: 'member',
                    entityId: id,
                    category: 'settings',
                    details: {'role': entry.$1, 'memberName': '${member['firstName']} ${member['lastName']}'},
                  );
                  onRolesChanged();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text('Role changes are logged to audit trail',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[500])),
          const SizedBox(height: 16),

          // App Access
          _sectionTitle(context, 'APP ACCESS'),
          _infoRow('Firebase UID', '${member['firebaseUid'] ?? 'Not linked'}'),
          _infoRow('Last Login', _formatLastLogin(member['lastLogin'])),
          const SizedBox(height: 16),

          // Actions
          _sectionTitle(context, 'ACTIONS'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Member'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final doc = FirebaseFirestore.instance
                    .collection('members')
                    .doc(id);
                final isActive = member['isActive'] != false;
                doc.update({'isActive': !isActive});
                onRolesChanged();
              },
              icon: Icon(
                member['isActive'] != false
                    ? Icons.block
                    : Icons.check_circle,
                size: 16,
              ),
              label: Text(member['isActive'] != false
                  ? 'Deactivate Member'
                  : 'Reactivate Member'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_forever, size: 16),
              label: const Text('Delete Member'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              )),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: TextStyle(
                    fontSize: 12,
                    color: value.isEmpty ? Colors.grey[400] : null)),
          ),
        ],
      ),
    );
  }

  String _formatLastLogin(Object? value) {
    DateTime? dt;
    if (value is Timestamp) {
      dt = value.toDate();
    } else if (value is String && value.isNotEmpty) {
      dt = DateTime.tryParse(value);
    }
    if (dt == null) return 'Never';
    return DateFormat.yMMMd().add_jm().format(dt.toLocal());
  }
}
