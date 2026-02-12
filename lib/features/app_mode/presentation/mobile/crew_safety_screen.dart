import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/data/auth_providers.dart';

class CrewSafetyScreen extends ConsumerWidget {
  const CrewSafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentUserProvider);
    final member = memberAsync.value;

    return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // MOB quick action
          Card(
            color: Colors.red.shade50,
            child: InkWell(
              onTap: () => _showMobGuide(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.sos, size: 40, color: Colors.red.shade700),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Man Overboard (MOB)',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900)),
                          const Text('Tap for quick-action guide',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Emergency contacts
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emergency, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Emergency Contacts',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ContactTile(
                    label: 'Coast Guard',
                    number: '(831) 647-7300',
                    icon: Icons.local_police,
                  ),
                  _ContactTile(
                    label: 'Monterey Harbor',
                    number: '(831) 646-3950',
                    icon: Icons.anchor,
                  ),
                  if (member != null) ...[
                    const Divider(),
                    _ContactTile(
                      label:
                          'Your Emergency: ${member.emergencyContact.name}',
                      number: member.emergencyContact.phone,
                      icon: Icons.person,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // VHF channels
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.radio, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('VHF Radio Channels',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow('Ch 16', 'Emergency / Distress'),
                  _InfoRow('Ch 68', 'MPYC Race Committee'),
                  _InfoRow('Ch 69', 'Club Operations'),
                  _InfoRow('Ch 72', 'Ship to Ship'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Safety checklist
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.checklist, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Safety Equipment Check',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _CheckItem('PFDs for all crew'),
                  _CheckItem('Throwable flotation device'),
                  _CheckItem('Fire extinguisher'),
                  _CheckItem('Sound signaling device (horn/whistle)'),
                  _CheckItem('VHF radio charged'),
                  _CheckItem('First aid kit'),
                  _CheckItem('Knife / cutting tool'),
                ],
              ),
            ),
          ),
        ],
    );
  }

  void _showMobGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sos, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('MOB Procedure'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. SHOUT "Man Overboard!" and point',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('2. Throw flotation device immediately'),
              SizedBox(height: 6),
              Text('3. Assign a spotter — never lose sight'),
              SizedBox(height: 6),
              Text('4. Press MOB button on GPS if available'),
              SizedBox(height: 6),
              Text('5. Radio "MAYDAY" on Ch 16 if needed'),
              SizedBox(height: 6),
              Text('6. Execute Figure-8 or Quick-Stop maneuver'),
              SizedBox(height: 6),
              Text('7. Approach from downwind'),
              SizedBox(height: 6),
              Text('8. Recover person — check for hypothermia'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.label,
    required this.number,
    required this.icon,
  });

  final String label;
  final String number;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      subtitle: Text(number,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.blue)),
      trailing: IconButton(
        icon: const Icon(Icons.phone, color: Colors.green),
        onPressed: () => launchUrl(Uri.parse('tel:$number')),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _CheckItem extends StatefulWidget {
  const _CheckItem(this.label);
  final String label;

  @override
  State<_CheckItem> createState() => _CheckItemState();
}

class _CheckItemState extends State<_CheckItem> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.label,
          style: TextStyle(
            fontSize: 13,
            decoration: _checked ? TextDecoration.lineThrough : null,
          )),
      value: _checked,
      onChanged: (v) => setState(() => _checked = v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}
