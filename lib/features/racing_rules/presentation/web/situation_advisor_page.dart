import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/utils/web_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../incidents/data/models/race_incident.dart';
import '../../../incidents/data/services/protest_form_generator.dart';
import '../../../incidents/presentation/incidents_providers.dart';
import '../../data/racing_rules_service.dart';
import '../racing_rules_providers.dart';

class SituationAdvisorPage extends ConsumerStatefulWidget {
  const SituationAdvisorPage({super.key});

  @override
  ConsumerState<SituationAdvisorPage> createState() =>
      _SituationAdvisorPageState();
}

class _SituationAdvisorPageState extends ConsumerState<SituationAdvisorPage> {
  int _step = 0;
  String? _encounterType;
  String? _subAnswer;
  final Set<String> _additionalFactors = {};

  static const _encounterTypes = [
    ('crossing', 'Crossing', Icons.compare_arrows,
        'Two boats on opposite tacks meeting'),
    ('overtaking', 'Overtaking', Icons.fast_forward,
        'One boat passing another from behind'),
    ('mark_rounding', 'Mark Rounding', Icons.trip_origin,
        'Boats approaching or rounding a mark'),
    ('start_line', 'Start Line', Icons.flag,
        'Incidents at or near the starting line'),
    ('tacking_gybing', 'Tacking / Gybing', Icons.swap_horiz,
        'Boat changing tack or gybing near others'),
    ('obstruction', 'Obstruction', Icons.warning_amber,
        'Boats near a fixed or continuing obstruction'),
  ];

  static const _additionalFactorOptions = [
    ('Proper course', 'Proper course limitations may apply'),
    ('Room to keep clear', 'Was there room to keep clear?'),
    ('Seamanship', 'Seamanship obligations apply'),
    ('Contact occurred', 'Physical contact between boats'),
  ];

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(racingRulesDatabaseProvider);

    return dbAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (db) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Step progress
          SizedBox(
            width: 260,
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Situation Advisor',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Walk through a racing situation to find applicable rules.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    _stepIndicator(0, 'Encounter Type',
                        _encounterType != null ? _encounterLabel() : null),
                    _stepIndicator(1, 'Details',
                        _subAnswer != null ? _subAnswerLabel() : null),
                    _stepIndicator(2, 'Additional Factors',
                        _additionalFactors.isNotEmpty
                            ? '${_additionalFactors.length} selected'
                            : null),
                    _stepIndicator(3, 'Results', null),
                    const Spacer(),
                    if (_step > 0)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Start Over'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Right: Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(db),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepIndicator(int step, String label, String? subtitle) {
    final isActive = _step == step;
    final isComplete = _step > step;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isComplete
                ? Colors.green
                : isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
            child: isComplete
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text('${step + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive || isComplete ? null : Colors.grey,
                    )),
                if (subtitle != null)
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(RacingRulesDatabase db) {
    switch (_step) {
      case 0:
        return _buildEncounterStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildFactorsStep();
      case 3:
        return _buildResultsStep(db);
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Encounter Type ──

  Widget _buildEncounterStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What type of encounter occurred?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Select the situation that best describes the incident.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _encounterTypes.map((t) {
            final (id, label, icon, desc) = t;
            final selected = _encounterType == id;
            return SizedBox(
              width: 280,
              child: Card(
                elevation: selected ? 4 : 1,
                color: selected
                    ? Colors.blue.shade50
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: selected
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2)
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _encounterType = id;
                      _subAnswer = null;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon,
                            size: 28,
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey),
                        const SizedBox(height: 8),
                        Text(label,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15,
                                color: selected ? Colors.blue.shade900 : null)),
                        const SizedBox(height: 4),
                        Text(desc,
                            style: TextStyle(
                                fontSize: 12, color: selected ? Colors.blue.shade700 : Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _encounterType != null
              ? () => setState(() => _step = 1)
              : null,
          child: const Text('Next'),
        ),
      ],
    );
  }

  // ── Step 1: Details ──

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _step = 0),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Provide more details',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ..._buildSubQuestions(),
        const SizedBox(height: 24),
        FilledButton(
          onPressed:
              _subAnswer != null ? () => setState(() => _step = 2) : null,
          child: const Text('Next'),
        ),
      ],
    );
  }

  List<Widget> _buildSubQuestions() {
    switch (_encounterType) {
      case 'crossing':
        return [
          const Text('Which boat was on starboard tack?'),
          const SizedBox(height: 8),
          _subOption('your_boat', 'Your boat (you had right of way)',
              Icons.check_circle_outline),
          _subOption('other_boat',
              'Other boat (you should have kept clear)', Icons.cancel_outlined),
          _subOption('unclear', 'Unclear / disputed', Icons.help_outline),
        ];
      case 'mark_rounding':
        return [
          const Text('Were boats overlapped at the zone?'),
          const SizedBox(height: 8),
          _subOption('overlapped_inside', 'Yes — you were inside',
              Icons.arrow_circle_left),
          _subOption('overlapped_outside', 'Yes — you were outside',
              Icons.arrow_circle_right),
          _subOption(
              'clear_ahead', 'No — you were clear ahead', Icons.arrow_upward),
          _subOption('clear_astern', 'No — you were clear astern',
              Icons.arrow_downward),
        ];
      case 'overtaking':
        return [
          const Text('Which side was the overtaking boat?'),
          const SizedBox(height: 8),
          _subOption('windward', 'Windward side', Icons.arrow_upward),
          _subOption('leeward', 'Leeward side', Icons.arrow_downward),
        ];
      case 'start_line':
        return [
          const Text('What happened at the start?'),
          const SizedBox(height: 8),
          _subOption('ocs', 'Over the line early (OCS)', Icons.timer),
          _subOption(
              'barging', 'Barging at the committee boat', Icons.directions_boat),
          _subOption('luffing', 'Luffing before the start', Icons.swap_vert),
        ];
      case 'tacking_gybing':
        return [
          const Text('What was happening?'),
          const SizedBox(height: 8),
          _subOption('tacking_across', 'Boat tacked in front of another',
              Icons.swap_horiz),
          _subOption('simultaneous', 'Both boats tacking simultaneously',
              Icons.sync),
          _subOption('lee_bow', 'Lee-bow tack', Icons.south_west),
        ];
      case 'obstruction':
        return [
          const Text('What type of obstruction?'),
          const SizedBox(height: 8),
          _subOption('fixed', 'Fixed object (land, pier, etc.)', Icons.anchor),
          _subOption('boat', 'Another boat / vessel', Icons.sailing),
          _subOption('continuing', 'Continuing obstruction (shoreline)',
              Icons.landscape),
        ];
      default:
        return [const Text('Select an encounter type first.')];
    }
  }

  Widget _subOption(String value, String label, IconData icon) {
    final selected = _subAnswer == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: selected ? 3 : 1,
        color: selected
            ? Colors.blue.shade50
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: selected
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: ListTile(
          leading: Icon(icon,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey),
          title: Text(label,
              style: TextStyle(
                  color: selected ? Colors.blue.shade900 : null)),
          selectedTileColor: Colors.transparent,
          selected: selected,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: () => setState(() => _subAnswer = value),
        ),
      ),
    );
  }

  // ── Step 2: Additional Factors ──

  Widget _buildFactorsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _step = 1),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Any additional factors?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Select all that apply (optional).',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        ..._additionalFactorOptions.map((f) {
          final (label, desc) = f;
          final checked = _additionalFactors.contains(label);
          return Card(
            color: checked
                ? Colors.blue.shade50
                : null,
            child: CheckboxListTile(
              title: Text(label,
                  style: TextStyle(fontWeight: FontWeight.w600,
                      color: checked ? Colors.blue.shade900 : null)),
              subtitle: Text(desc, style: TextStyle(fontSize: 12,
                  color: checked ? Colors.blue.shade700 : null)),
              value: checked,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _additionalFactors.add(label);
                  } else {
                    _additionalFactors.remove(label);
                  }
                });
              },
            ),
          );
        }),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _step = 3),
          child: const Text('Show Applicable Rules'),
        ),
      ],
    );
  }

  // ── Step 3: Results ──

  Widget _buildResultsStep(RacingRulesDatabase db) {
    final applicableRules = _getApplicableRules();
    final hasContact = _additionalFactors.contains('Contact occurred');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _step = 2),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Applicable Rules',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${applicableRules.length} rule(s) found for this situation',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...applicableRules.map((entry) {
          final rule = db.findRule(entry.ruleNumber);
          final relevanceColor = switch (entry.relevance) {
            'Primary' => Colors.red,
            'Applies' => Colors.orange,
            'Also applies' => Colors.blue,
            _ => Colors.grey,
          };
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: relevanceColor.withValues(alpha: 0.15),
                        child: Text(
                          entry.ruleNumber,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: relevanceColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rule?.title ?? 'Rule ${entry.ruleNumber}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: relevanceColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.relevance,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: relevanceColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(entry.explanation,
                      style: const TextStyle(height: 1.4)),
                  if (rule != null && rule.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('View full rule text',
                          style: TextStyle(fontSize: 13)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SelectableText(
                            rule.text,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        if (hasContact)
          Card(
            color: Colors.orange.shade50,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Contact occurred — Rule 14 (Avoiding Contact) applies. '
                      'Both boats have an obligation to avoid contact if reasonably possible.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        Card(
          color: Colors.amber.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'This is a reference tool for discussion. Official rulings '
                    'are made through the formal protest process.',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Start Over'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _fileProtest(applicableRules),
              icon: const Icon(Icons.description, size: 18),
              label: const Text('File Protest with These Rules'),
            ),
          ],
        ),
      ],
    );
  }

  void _fileProtest(List<_RuleResult> rules) {
    final ruleNumbers = rules.map((r) => r.ruleNumber).toList();
    final ruleLabels = rules
        .map((r) => '${r.ruleNumber} – ${r.explanation.split('.').first}')
        .toList();
    final explanations = rules.map((r) => r.explanation).toList();

    // Navigate to incidents page with pre-filled data via query params
    // We encode the situation advisor data and pass it
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AdvisorProtestBridge(
          encounterType: _encounterLabel(),
          details: _subAnswerLabel(),
          ruleNumbers: ruleNumbers,
          ruleLabels: ruleLabels,
          explanations: explanations,
          additionalFactors: _additionalFactors.toList(),
        ),
      ),
    );
  }

  // ── Helpers ──

  String _encounterLabel() {
    return _encounterTypes
            .where((t) => t.$1 == _encounterType)
            .firstOrNull
            ?.$2 ??
        '';
  }

  String _subAnswerLabel() {
    final labels = <String, String>{
      'your_boat': 'Your boat (starboard)',
      'other_boat': 'Other boat (starboard)',
      'unclear': 'Unclear',
      'overlapped_inside': 'Overlapped inside',
      'overlapped_outside': 'Overlapped outside',
      'clear_ahead': 'Clear ahead',
      'clear_astern': 'Clear astern',
      'windward': 'Windward',
      'leeward': 'Leeward',
      'ocs': 'OCS',
      'barging': 'Barging',
      'luffing': 'Luffing',
      'tacking_across': 'Tacked across',
      'simultaneous': 'Simultaneous',
      'lee_bow': 'Lee-bow',
      'fixed': 'Fixed object',
      'boat': 'Another boat',
      'continuing': 'Continuing',
    };
    return labels[_subAnswer] ?? '';
  }

  void _reset() {
    setState(() {
      _step = 0;
      _encounterType = null;
      _subAnswer = null;
      _additionalFactors.clear();
    });
  }

  List<_RuleResult> _getApplicableRules() {
    final results = <_RuleResult>[];

    switch (_encounterType) {
      case 'crossing':
        results.add(const _RuleResult(
          ruleNumber: '10',
          relevance: 'Primary',
          explanation:
              'On opposite tacks, the port-tack boat must keep clear of the starboard-tack boat.',
        ));
        if (_subAnswer == 'unclear') {
          results.add(const _RuleResult(
            ruleNumber: '15',
            relevance: 'May apply',
            explanation:
                'If one boat acquired right of way, she must initially give the other room to keep clear.',
          ));
        }
        results.add(const _RuleResult(
          ruleNumber: '16',
          relevance: 'May apply',
          explanation:
              'If the right-of-way boat changed course, she must give the other boat room to keep clear.',
        ));
        break;

      case 'mark_rounding':
        results.add(const _RuleResult(
          ruleNumber: '18',
          relevance: 'Primary',
          explanation:
              'Mark-room rules apply when boats are in the zone. The outside boat must give the inside boat mark-room.',
        ));
        if (_subAnswer == 'overlapped_inside' ||
            _subAnswer == 'overlapped_outside') {
          results.add(const _RuleResult(
            ruleNumber: '11',
            relevance: 'Also applies',
            explanation:
                'When overlapped on the same tack, the windward boat must keep clear of the leeward boat.',
          ));
        }
        if (_subAnswer == 'clear_ahead' || _subAnswer == 'clear_astern') {
          results.add(const _RuleResult(
            ruleNumber: '12',
            relevance: 'Also applies',
            explanation:
                'When not overlapped, the boat clear astern must keep clear of the boat clear ahead.',
          ));
        }
        break;

      case 'overtaking':
        results.add(const _RuleResult(
          ruleNumber: '12',
          relevance: 'Primary',
          explanation:
              'The boat clear astern must keep clear of the boat clear ahead.',
        ));
        if (_subAnswer == 'leeward') {
          results.add(const _RuleResult(
            ruleNumber: '11',
            relevance: 'Once overlapped',
            explanation:
                'Once overlapped, the windward boat must keep clear of the leeward boat.',
          ));
          results.add(const _RuleResult(
            ruleNumber: '17',
            relevance: 'May apply',
            explanation:
                'If the leeward boat established overlap from clear astern within 2 hull lengths, she may not sail above proper course.',
          ));
        }
        if (_subAnswer == 'windward') {
          results.add(const _RuleResult(
            ruleNumber: '11',
            relevance: 'Once overlapped',
            explanation:
                'The windward boat must keep clear of the leeward boat.',
          ));
        }
        break;

      case 'start_line':
        results.add(const _RuleResult(
          ruleNumber: '29',
          relevance: 'Primary',
          explanation:
              'Individual recall rules apply when a boat is OCS at the starting signal.',
        ));
        results.add(const _RuleResult(
          ruleNumber: '30',
          relevance: 'May apply',
          explanation:
              'Starting penalties (I/Z/U/Black flag) may apply depending on which flag was displayed.',
        ));
        if (_subAnswer == 'barging' || _subAnswer == 'luffing') {
          results.add(const _RuleResult(
            ruleNumber: '11',
            relevance: 'Also applies',
            explanation:
                'Windward boat must keep clear of leeward boat on the same tack.',
          ));
        }
        break;

      case 'tacking_gybing':
        results.add(const _RuleResult(
          ruleNumber: '13',
          relevance: 'Primary',
          explanation:
              'A boat tacking must keep clear of other boats until she is on a close-hauled course.',
        ));
        if (_subAnswer == 'lee_bow') {
          results.add(const _RuleResult(
            ruleNumber: '15',
            relevance: 'Also applies',
            explanation:
                'When acquiring right of way, the boat must initially give room to keep clear.',
          ));
        }
        break;

      case 'obstruction':
        results.add(const _RuleResult(
          ruleNumber: '19',
          relevance: 'Primary',
          explanation:
              'Room to pass an obstruction — the outside boat must give the inside boat room.',
        ));
        if (_subAnswer == 'fixed') {
          results.add(const _RuleResult(
            ruleNumber: '20',
            relevance: 'May apply',
            explanation:
                'A boat may hail for room to tack at an obstruction if sailing close-hauled.',
          ));
        }
        break;
    }

    if (_additionalFactors.contains('Contact occurred')) {
      results.add(const _RuleResult(
        ruleNumber: '14',
        relevance: 'Applies',
        explanation:
            'Both boats have an obligation to avoid contact if reasonably possible.',
      ));
    }
    if (_additionalFactors.contains('Proper course')) {
      results.add(const _RuleResult(
        ruleNumber: '17',
        relevance: 'May apply',
        explanation:
            'Proper course limitations may apply to a leeward boat that established overlap from clear astern.',
      ));
    }

    return results;
  }
}

class _RuleResult {
  const _RuleResult({
    required this.ruleNumber,
    required this.relevance,
    required this.explanation,
  });

  final String ruleNumber;
  final String relevance;
  final String explanation;
}

// ═══════════════════════════════════════════════════════════════════
// Advisor → Protest Bridge
// Creates an incident from advisor data and generates the protest form.
// ═══════════════════════════════════════════════════════════════════

class _AdvisorProtestBridge extends ConsumerStatefulWidget {
  const _AdvisorProtestBridge({
    required this.encounterType,
    required this.details,
    required this.ruleNumbers,
    required this.ruleLabels,
    required this.explanations,
    required this.additionalFactors,
  });

  final String encounterType;
  final String details;
  final List<String> ruleNumbers;
  final List<String> ruleLabels;
  final List<String> explanations;
  final List<String> additionalFactors;

  @override
  ConsumerState<_AdvisorProtestBridge> createState() =>
      _AdvisorProtestBridgeState();
}

class _AdvisorProtestBridgeState extends ConsumerState<_AdvisorProtestBridge> {
  final _descCtrl = TextEditingController();
  final _eventIdCtrl = TextEditingController();
  int _raceNumber = 1;
  CourseLocationOnIncident _location = CourseLocationOnIncident.openWater;
  final List<_SimpleBoat> _boats = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill description from advisor context
    final buf = StringBuffer();
    buf.writeln('Encounter: ${widget.encounterType} — ${widget.details}');
    if (widget.additionalFactors.isNotEmpty) {
      buf.writeln('Factors: ${widget.additionalFactors.join(', ')}');
    }
    buf.writeln();
    buf.writeln('Applicable rules:');
    for (int i = 0; i < widget.ruleLabels.length; i++) {
      buf.writeln('• Rule ${widget.ruleLabels[i]}');
    }
    _descCtrl.text = buf.toString();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _eventIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Protest from Situation Advisor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Advisor summary card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text('Situation Advisor Analysis',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue.shade800)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Encounter: ${widget.encounterType} — ${widget.details}'),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: widget.ruleNumbers
                              .map((r) => Chip(
                                    label: Text('Rule $r',
                                        style: const TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: Colors.blue.shade100,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text('Incident Details',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                // Event ID + Race Number
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _eventIdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Event ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _raceNumber,
                        decoration: const InputDecoration(
                          labelText: 'Race #',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(10, (i) => i + 1)
                            .map((n) => DropdownMenuItem(
                                value: n, child: Text('Race $n')))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _raceNumber = v ?? 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location
                Text('Location on Course',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: CourseLocationOnIncident.values.map((loc) {
                    final label = _locLabel(loc);
                    return ChoiceChip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      selected: _location == loc,
                      onSelected: (_) => setState(() => _location = loc),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Boats
                Text('Boats Involved',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                ..._boats.asMap().entries.map((e) {
                  final i = e.key;
                  final b = e.value;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                  labelText: 'Sail #', isDense: true),
                              onChanged: (v) => b.sailNumber = v,
                              controller:
                                  TextEditingController(text: b.sailNumber),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                  labelText: 'Boat Name', isDense: true),
                              onChanged: (v) => b.boatName = v,
                              controller:
                                  TextEditingController(text: b.boatName),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                  labelText: 'Skipper', isDense: true),
                              onChanged: (v) => b.skipperName = v,
                              controller:
                                  TextEditingController(text: b.skipperName),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SegmentedButton<BoatInvolvedRole>(
                            segments: const [
                              ButtonSegment(
                                  value: BoatInvolvedRole.protesting,
                                  label: Text('P',
                                      style: TextStyle(fontSize: 10))),
                              ButtonSegment(
                                  value: BoatInvolvedRole.protested,
                                  label: Text('D',
                                      style: TextStyle(fontSize: 10))),
                              ButtonSegment(
                                  value: BoatInvolvedRole.witness,
                                  label: Text('W',
                                      style: TextStyle(fontSize: 10))),
                            ],
                            selected: {b.role},
                            onSelectionChanged: (roles) =>
                                setState(() => b.role = roles.first),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setState(() => _boats.removeAt(i)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _boats.add(_SimpleBoat())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Boat'),
                ),
                const SizedBox(height: 16),

                // Description
                Text('Description',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                TextField(
                  controller: _descCtrl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Describe the incident...',
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submitAndGenerate,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.description),
                      label: const Text(
                          'Create Incident & Generate Protest Form'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitAndGenerate() async {
    if (_boats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one boat')),
      );
      return;
    }

    setState(() => _submitting = true);

    final now = DateTime.now();
    final incident = RaceIncident(
      id: '',
      eventId: _eventIdCtrl.text.trim().isEmpty
          ? 'advisor_${now.millisecondsSinceEpoch}'
          : _eventIdCtrl.text.trim(),
      raceNumber: _raceNumber,
      reportedAt: now,
      reportedBy:
          FirebaseAuth.instance.currentUser?.displayName ?? 'Admin',
      incidentTime: now,
      description: _descCtrl.text.trim(),
      locationOnCourse: _location,
      involvedBoats: _boats
          .map((b) => BoatInvolved(
                boatId: b.sailNumber.toLowerCase().replaceAll(' ', '_'),
                sailNumber: b.sailNumber,
                boatName: b.boatName,
                skipperName: b.skipperName,
                role: b.role,
              ))
          .toList(),
      rulesAlleged: widget.ruleLabels,
      status: RaceIncidentStatus.protestFiled,
    );

    // Create the incident in Firestore
    await ref.read(incidentsRepositoryProvider).createIncident(incident);

    // Generate protest form with advisor data pre-filled
    final formData = ProtestFormData(
      incidentDescription: _descCtrl.text.trim(),
      situationEncounterType: widget.encounterType,
      situationDetails: widget.details,
      situationRules: widget.ruleNumbers,
      situationExplanations: widget.explanations,
    );
    const gen = ProtestFormGenerator();
    final htmlContent =
        gen.generateProtestFormHtml(incident, formData: formData);
    openHtmlInNewTab(htmlContent, 'Protest Form');

    setState(() => _submitting = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Incident created and protest form generated')),
      );
    }
  }

  String _locLabel(CourseLocationOnIncident loc) => switch (loc) {
        CourseLocationOnIncident.startLine => 'Start Line',
        CourseLocationOnIncident.windwardMark => 'Windward Mark',
        CourseLocationOnIncident.gate => 'Gate',
        CourseLocationOnIncident.leewardMark => 'Leeward Mark',
        CourseLocationOnIncident.reachingMark => 'Reaching Mark',
        CourseLocationOnIncident.openWater => 'Open Water',
      };
}

class _SimpleBoat {
  String sailNumber = '';
  String boatName = '';
  String skipperName = '';
  BoatInvolvedRole role = BoatInvolvedRole.protesting;
}
