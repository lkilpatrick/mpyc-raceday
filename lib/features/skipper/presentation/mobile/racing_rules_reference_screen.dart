import 'package:flutter/material.dart';

import '../widgets/weather_header.dart';

/// Static racing rules quick reference for skippers.
/// Part 2 basics, penalties, protest process, MPYC notes.
class RacingRulesReferenceScreen extends StatelessWidget {
  const RacingRulesReferenceScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = const Column(
      children: [
        WeatherHeader(),
        Expanded(child: _RulesContent()),
      ],
    );

    if (embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Racing Rules Reference')),
      body: content,
    );
  }
}

class _RulesContent extends StatelessWidget {
  const _RulesContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _section(
          'Part 2 — Right of Way',
          Icons.compare_arrows,
          Colors.blue,
          [
            _rule('Rule 10 — Port / Starboard',
                'On opposite tacks, the port-tack boat shall keep clear of the starboard-tack boat.'),
            _rule('Rule 11 — Windward / Leeward',
                'When overlapped on the same tack, the windward boat shall keep clear of the leeward boat.'),
            _rule('Rule 12 — Clear Astern / Ahead',
                'When not overlapped on the same tack, the boat clear astern shall keep clear of the boat clear ahead.'),
            _rule('Rule 13 — While Tacking',
                'After passing head to wind, a boat shall keep clear of other boats until she is on a close-hauled course.'),
            _rule('Rule 14 — Avoiding Contact',
                'A boat shall avoid contact with another boat if reasonably possible. A right-of-way boat that breaks Rule 14 is penalized only if contact causes damage or injury.'),
          ],
        ),
        _section(
          'Mark-Room & Obstructions',
          Icons.trip_origin,
          Colors.orange,
          [
            _rule('Rule 18 — Mark-Room',
                'When boats are overlapped at the zone (3 hull lengths), the outside boat shall give the inside boat mark-room.'),
            _rule('Rule 19 — Room at Obstruction',
                'At an obstruction, the outside boat shall give the inside boat room to pass between her and the obstruction.'),
            _rule('Rule 20 — Room to Tack',
                'A boat may hail for room to tack at an obstruction. The hailed boat shall respond promptly.'),
          ],
        ),
        _section(
          'Starting',
          Icons.flag,
          Colors.green,
          [
            _rule('Rule 26 — Starting Sequence',
                'Warning signal (4 min), Preparatory signal (3 min), One-minute signal, Starting signal.'),
            _rule('Rule 29 — Individual Recall',
                'If any part of a boat\'s hull is on the course side at the starting signal, she must return and start correctly.'),
            _rule('Rule 30 — Starting Penalties',
                'I flag: round-the-ends rule. Z flag: 20% penalty. U flag: disqualified if in triangle. Black flag: disqualified.'),
          ],
        ),
        _section(
          'Penalties',
          Icons.rotate_left,
          Colors.red,
          [
            _rule('Rule 44.1 — Taking a Penalty',
                'A boat may take a Two-Turns Penalty (one tack + one gybe in each turn) when she may have broken a rule while racing.'),
            _rule('Rule 44.2 — One-Turn Penalty',
                'When the sailing instructions so provide, the penalty is One Turn instead of Two Turns.'),
            _rule('DNF — Did Not Finish',
                'A boat that does not finish within the time limit or retires.'),
            _rule('DSQ — Disqualification',
                'A boat disqualified under a rule or by a protest committee.'),
            _rule('OCS — On Course Side',
                'A boat on the course side of the starting line at the starting signal that does not return and start correctly.'),
          ],
        ),
        _section(
          'Protests',
          Icons.gavel,
          Colors.purple,
          [
            _rule('Rule 60 — Right to Protest',
                'A boat may protest another boat for an alleged breach of a rule.'),
            _rule('Rule 61 — Informing the Protestee',
                'Hail "Protest" at the first reasonable opportunity and display a red flag (boats over 6m).'),
            _rule('Rule 62 — Redress',
                'A boat may request redress if her score was made significantly worse through no fault of her own.'),
            _rule('Filing a Protest',
                'Submit a written protest within the time limit (usually 90 minutes after the last boat finishes). Include: incident time, location, rules alleged, description.'),
          ],
        ),
        _section(
          'MPYC Club Notes',
          Icons.anchor,
          Colors.teal,
          [
            _rule('Protest Time Limit',
                '90 minutes after the last boat finishes the last race of the day.'),
            _rule('Penalty Turns',
                'Standard Two-Turns Penalty unless the sailing instructions specify otherwise.'),
            _rule('Safety',
                'All boats must carry required safety equipment. PFDs must be worn when the RC displays flag Y.'),
            _rule('VHF Channel',
                'Monitor VHF Channel 69 for RC communications during racing.'),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _section(
      String title, IconData icon, Color color, List<Widget> rules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ...rules,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _rule(String title, String body) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(body,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
