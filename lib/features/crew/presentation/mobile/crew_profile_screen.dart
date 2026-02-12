import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_providers.dart';

/// Boat positions available for crew members.
const kCrewPositions = [
  'Tactician',
  'Navigator',
  'Main trimmer',
  'Jib/Genoa trimmer',
  'Spinnaker trimmer',
  'Spinnaker hoist / douse',
  'Pit',
  'Mast',
  'Bow',
  'Helm (non-skipper)',
  'Rail / ballast',
  'Floater',
  'Grinder',
  'Watch / lookout',
  'Spectator (on boat)',
];

/// Crew profile setup — boat + name + position dropdown.
class CrewProfileScreen extends ConsumerStatefulWidget {
  const CrewProfileScreen({super.key});

  @override
  ConsumerState<CrewProfileScreen> createState() => _CrewProfileScreenState();
}

class _CrewProfileScreenState extends ConsumerState<CrewProfileScreen> {
  final _nameCtrl = TextEditingController();
  String? _selectedBoatId;
  String? _selectedBoatLabel;
  String _selectedPosition = kCrewPositions.first;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _loadExisting(WidgetRef ref) {
    if (_loaded) return;
    _loaded = true;
    final member = ref.read(currentUserProvider).value;
    if (member != null) {
      _nameCtrl.text = member.displayName;
    }
    // Load saved crew profile from Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('crew_profiles')
        .doc(uid)
        .get()
        .then((snap) {
      if (snap.exists && mounted) {
        final d = snap.data()!;
        setState(() {
          _nameCtrl.text = d['displayName'] as String? ?? _nameCtrl.text;
          _selectedBoatId = d['boatId'] as String?;
          _selectedBoatLabel = d['boatLabel'] as String?;
          final pos = d['boatPosition'] as String?;
          if (pos != null && kCrewPositions.contains(pos)) {
            _selectedPosition = pos;
          }
        });
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    _loadExisting(ref);

    return Scaffold(
      appBar: AppBar(title: const Text('Crew Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Set up your crew profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('This tells the skipper and RC who you are and your role.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 20),

          // Name
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Boat selector
          const Text('Boat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          _BoatSelector(
            selectedId: _selectedBoatId,
            selectedLabel: _selectedBoatLabel,
            onSelected: (id, label) {
              setState(() {
                _selectedBoatId = id;
                _selectedBoatLabel = label;
              });
            },
          ),
          const SizedBox(height: 16),

          // Position dropdown
          const Text('Position on Boat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedPosition,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.assignment_ind),
              border: OutlineInputBorder(),
            ),
            items: kCrewPositions
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedPosition = v);
            },
          ),
          const SizedBox(height: 24),

          // Save
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Profile',
                  style: const TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('Not logged in');

      await FirebaseFirestore.instance
          .collection('crew_profiles')
          .doc(uid)
          .set({
        'displayName': _nameCtrl.text.trim(),
        'boatId': _selectedBoatId ?? '',
        'boatLabel': _selectedBoatLabel ?? '',
        'boatPosition': _selectedPosition,
        'role': 'crew',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Boat selector — picks from the fleet (boats collection).
class _BoatSelector extends StatelessWidget {
  const _BoatSelector({
    required this.selectedId,
    required this.selectedLabel,
    required this.onSelected,
  });

  final String? selectedId;
  final String? selectedLabel;
  final void Function(String id, String label) onSelected;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('boats')
          .where('isActive', isEqualTo: true)
          .orderBy('sailNumber')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final boats = <(String, String)>[];
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final name = d['boatName'] as String? ?? '';
          final sail = d['sailNumber'] as String? ?? '';
          final boatClass = d['boatClass'] as String? ?? '';
          if (name.isNotEmpty || sail.isNotEmpty) {
            final label = [
              if (name.isNotEmpty) name,
              if (sail.isNotEmpty) '(Sail $sail)',
              if (boatClass.isNotEmpty) '— $boatClass',
            ].join(' ');
            boats.add((doc.id, label));
          }
        }

        if (boats.isEmpty) {
          return TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: selectedLabel ?? 'No boats in fleet',
              prefixIcon: const Icon(Icons.sailing),
              border: const OutlineInputBorder(),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          value: selectedId != null &&
                  boats.any((b) => b.$1 == selectedId)
              ? selectedId
              : null,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.sailing),
            border: OutlineInputBorder(),
            hintText: 'Select a boat from fleet',
          ),
          items: boats
              .map((b) => DropdownMenuItem(
                    value: b.$1,
                    child: Text(b.$2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (id) {
            if (id != null) {
              final match = boats.firstWhere((b) => b.$1 == id);
              onSelected(match.$1, match.$2);
            }
          },
        );
      },
    );
  }
}
