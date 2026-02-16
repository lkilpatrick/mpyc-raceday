import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../racing_rules_providers.dart';

class DefinitionsScreen extends ConsumerStatefulWidget {
  const DefinitionsScreen({super.key});

  @override
  ConsumerState<DefinitionsScreen> createState() => _DefinitionsScreenState();
}

class _DefinitionsScreenState extends ConsumerState<DefinitionsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(racingRulesDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Definitions')),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (db) {
          final filtered = _query.isEmpty
              ? db.definitions
              : db.searchDefinitions(_query);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search definitions...',
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Card(
                  color: Colors.blue.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Defined terms have specific meanings in the Racing Rules. When a term is used in its defined sense, it is printed in italics in the official rulebook.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final def = filtered[index];
                    return Card(
                      child: ExpansionTile(
                        title: Text(
                          def.term,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(def.definition),
                                if (def.relatedRules.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Used in Rules:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: def.relatedRules
                                        .map((r) => ActionChip(
                                              label: Text('Rule $r'),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: () => context
                                                  .go('/rules/detail/$r'),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
