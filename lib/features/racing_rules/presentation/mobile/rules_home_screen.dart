import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/racing_rules_service.dart';
import '../racing_rules_providers.dart';

class RulesHomeScreen extends ConsumerStatefulWidget {
  const RulesHomeScreen({super.key});

  @override
  ConsumerState<RulesHomeScreen> createState() => _RulesHomeScreenState();
}

class _RulesHomeScreenState extends ConsumerState<RulesHomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _quickRefRules = [
    '10', '11', '12', '13', '14', '15', '16', '17', '18'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(racingRulesDatabaseProvider);
    final recentAsync = ref.watch(recentLookupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Racing Rules')),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading rules: $e')),
        data: (db) {
          final searchResults =
              _query.isEmpty ? <RuleData>[] : db.search(_query);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search rules, definitions, keywords...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              const SizedBox(height: 12),

              // Search results
              if (_query.isNotEmpty) ...[
                Text(
                  '${searchResults.length} results',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                ...searchResults.take(20).map((r) => ListTile(
                      title: Text('Rule ${r.number} — ${r.title}'),
                      subtitle: Text(
                        r.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _openRule(r.number),
                    )),
                const Divider(height: 24),
              ],

              // Situation Advisor button
              if (_query.isEmpty) ...[
                Card(
                  color: Colors.blue.shade50,
                  child: InkWell(
                    onTap: () => context.push('/rules/advisor'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.gavel,
                            size: 32,
                            color: Colors.blue.shade800,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Situation Advisor',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.blue.shade900,
                                      ),
                                ),
                                Text(
                                  'Step-by-step dispute resolution',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.blue.shade700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Colors.blue.shade800),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/rules/definitions'),
                        icon: const Icon(Icons.menu_book),
                        label: const Text('Definitions'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Reference
                Text(
                  'Quick Reference',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickRefRules.map((ruleNum) {
                    final rule = db.findRule(ruleNum);
                    return ActionChip(
                      label: Text('$ruleNum${rule != null ? " ${rule.title}" : ""}'),
                      onPressed: () => _openRule(ruleNum),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Recent Lookups
                if (recentAsync.value?.isNotEmpty ?? false) ...[
                  Text(
                    'Recent Lookups',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...recentAsync.value!.take(8).map((ruleNum) {
                    final rule = db.findRule(ruleNum);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text(ruleNum)),
                      title: Text(rule?.title ?? 'Rule $ruleNum'),
                      onTap: () => _openRule(ruleNum),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Browse by Part
                Text(
                  'Browse Rules',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...db.parts.map((part) => ExpansionTile(
                      title: Text(part.title),
                      children: part.sections.map((section) {
                        return ExpansionTile(
                          title: Text(section.title),
                          tilePadding:
                              const EdgeInsets.only(left: 24, right: 16),
                          children: section.rules.map((rule) {
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.only(left: 48, right: 16),
                              title: Text(
                                  'Rule ${rule.number} — ${rule.title}'),
                              onTap: () => _openRule(rule.number),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openRule(String ruleNumber) {
    ref.read(racingRulesServiceProvider).addRecentLookup(ruleNumber);
    ref.invalidate(recentLookupsProvider);
    context.push('/rules/detail/$ruleNumber');
  }
}
