import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/racing_rules_service.dart';
import '../racing_rules_providers.dart';

class SituationAdvisorScreen extends ConsumerStatefulWidget {
  const SituationAdvisorScreen({super.key});

  @override
  ConsumerState<SituationAdvisorScreen> createState() =>
      _SituationAdvisorScreenState();
}

class _SituationAdvisorScreenState
    extends ConsumerState<SituationAdvisorScreen> {
  int _step = 0;
  String? _encounterType;
  String? _subAnswer;
  final Set<String> _additionalFactors = {};

  static const _encounterTypes = [
    ('crossing', 'Crossing', Icons.compare_arrows),
    ('overtaking', 'Overtaking', Icons.fast_forward),
    ('mark_rounding', 'Mark Rounding', Icons.trip_origin),
    ('start_line', 'Start Line', Icons.flag),
    ('tacking_gybing', 'Tacking / Gybing', Icons.swap_horiz),
    ('obstruction', 'Obstruction', Icons.warning_amber),
  ];

  static const _additionalFactorOptions = [
    'Proper course',
    'Room to keep clear',
    'Seamanship',
    'Contact occurred',
  ];

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(racingRulesDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Situation Advisor')),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (db) => Stepper(
          currentStep: _step,
          onStepContinue: _step < 3 ? () => setState(() => _step++) : null,
          onStepCancel:
              _step > 0 ? () => setState(() => _step--) : null,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (_step < 3)
                    FilledButton(
                      onPressed: _canContinue()
                          ? details.onStepContinue
                          : null,
                      child: Text(_step == 2 ? 'Show Results' : 'Next'),
                    ),
                  if (_step > 0) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            // Step 1: Encounter type
            Step(
              title: const Text('Type of Encounter'),
              isActive: _step >= 0,
              state: _step > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: _encounterTypes.map((t) {
                  final (id, label, icon) = t;
                  return Card(
                    color: _encounterType == id
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                        : null,
                    child: ListTile(
                      leading: Icon(icon),
                      title: Text(label),
                      selected: _encounterType == id,
                      onTap: () =>
                          setState(() => _encounterType = id),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Step 2: Sub-questions
            Step(
              title: const Text('Details'),
              isActive: _step >= 1,
              state: _step > 1 ? StepState.complete : StepState.indexed,
              content: _buildSubQuestions(),
            ),

            // Step 3: Additional factors
            Step(
              title: const Text('Additional Factors'),
              isActive: _step >= 2,
              state: _step > 2 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _additionalFactorOptions.map((f) {
                  return CheckboxListTile(
                    title: Text(f),
                    value: _additionalFactors.contains(f),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _additionalFactors.add(f);
                        } else {
                          _additionalFactors.remove(f);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            // Step 4: Results
            Step(
              title: const Text('Applicable Rules'),
              isActive: _step >= 3,
              state: StepState.indexed,
              content: _buildResults(db),
            ),
          ],
        ),
      ),
    );
  }

  bool _canContinue() {
    if (_step == 0) return _encounterType != null;
    if (_step == 1) return _subAnswer != null;
    return true;
  }

  Widget _buildSubQuestions() {
    switch (_encounterType) {
      case 'crossing':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Which boat was on starboard tack?'),
            const SizedBox(height: 8),
            _subOption('your_boat', 'Your boat (you had right of way)'),
            _subOption('other_boat', 'Other boat (you should have kept clear)'),
            _subOption('unclear', 'Unclear / disputed'),
          ],
        );
      case 'mark_rounding':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Were boats overlapped at the zone?'),
            const SizedBox(height: 8),
            _subOption('overlapped_inside', 'Yes — you were inside'),
            _subOption('overlapped_outside', 'Yes — you were outside'),
            _subOption('clear_ahead', 'No — you were clear ahead'),
            _subOption('clear_astern', 'No — you were clear astern'),
          ],
        );
      case 'overtaking':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Which side was the overtaking boat?'),
            const SizedBox(height: 8),
            _subOption('windward', 'Windward side'),
            _subOption('leeward', 'Leeward side'),
          ],
        );
      case 'start_line':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What happened at the start?'),
            const SizedBox(height: 8),
            _subOption('ocs', 'Over the line early (OCS)'),
            _subOption('barging', 'Barging at the committee boat'),
            _subOption('luffing', 'Luffing before the start'),
          ],
        );
      case 'tacking_gybing':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What was happening?'),
            const SizedBox(height: 8),
            _subOption('tacking_across', 'Boat tacked in front of another'),
            _subOption('simultaneous', 'Both boats tacking simultaneously'),
            _subOption('lee_bow', 'Lee-bow tack'),
          ],
        );
      case 'obstruction':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What type of obstruction?'),
            const SizedBox(height: 8),
            _subOption('fixed', 'Fixed object (land, pier, etc.)'),
            _subOption('boat', 'Another boat / vessel'),
            _subOption('continuing', 'Continuing obstruction (shoreline)'),
          ],
        );
      default:
        return const Text('Select an encounter type first.');
    }
  }

  Widget _subOption(String value, String label) {
    return Card(
      color: _subAnswer == value
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        title: Text(label),
        selected: _subAnswer == value,
        onTap: () => setState(() => _subAnswer = value),
      ),
    );
  }

  Widget _buildResults(RacingRulesDatabase db) {
    final applicableRules = _getApplicableRules();
    final hasContact = _additionalFactors.contains('Contact occurred');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...applicableRules.map((entry) {
          final rule = db.findRule(entry.ruleNumber);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        child: Text(
                          entry.ruleNumber,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rule?.title ?? 'Rule ${entry.ruleNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        label: Text(
                          entry.relevance,
                          style: const TextStyle(fontSize: 10),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.explanation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () =>
                        context.go('/rules/detail/${entry.ruleNumber}'),
                    child: const Text('View full rule'),
                  ),
                ],
              ),
            ),
          );
        }),
        if (hasContact)
          Card(
            color: Colors.orange.shade50,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Contact occurred — Rule 14 (Avoiding Contact) applies. Both boats have an obligation to avoid contact if reasonably possible.',
              ),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          color: Colors.amber.shade50,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'This is a reference tool for discussion. Official rulings are made through the protest process.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            setState(() {
              _step = 0;
              _encounterType = null;
              _subAnswer = null;
              _additionalFactors.clear();
            });
          },
          child: const Text('Start Over'),
        ),
      ],
    );
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

    // Additional factors
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
