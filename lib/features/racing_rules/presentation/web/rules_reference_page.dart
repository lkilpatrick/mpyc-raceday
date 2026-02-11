import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/racing_rules_service.dart';
import '../racing_rules_providers.dart';

class RulesReferencePage extends ConsumerStatefulWidget {
  const RulesReferencePage({super.key});

  @override
  ConsumerState<RulesReferencePage> createState() =>
      _RulesReferencePageState();
}

class _RulesReferencePageState extends ConsumerState<RulesReferencePage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedPartId;
  String? _selectedSectionId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(racingRulesDatabaseProvider);

    return dbAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (db) {
        return Row(
          children: [
            // Side navigation
            SizedBox(
              width: 280,
              child: Card(
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (v) =>
                            setState(() => _query = v.trim()),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          // Definitions link
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.menu_book, size: 18),
                            title: const Text('Definitions'),
                            selected: _selectedPartId == 'definitions',
                            onTap: () => setState(() {
                              _selectedPartId = 'definitions';
                              _selectedSectionId = null;
                            }),
                          ),
                          const Divider(height: 1),
                          ...db.parts.expand((part) {
                            return [
                              ExpansionTile(
                                dense: true,
                                title: Text(
                                  part.title,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                initiallyExpanded:
                                    _selectedPartId == part.id,
                                children: part.sections.map((section) {
                                  return ListTile(
                                    dense: true,
                                    contentPadding:
                                        const EdgeInsets.only(left: 32),
                                    title: Text(
                                      section.title,
                                      style:
                                          const TextStyle(fontSize: 12),
                                    ),
                                    selected: _selectedSectionId ==
                                        section.id,
                                    onTap: () => setState(() {
                                      _selectedPartId = part.id;
                                      _selectedSectionId = section.id;
                                    }),
                                  );
                                }).toList(),
                              ),
                            ];
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Main content
            Expanded(
              child: _query.isNotEmpty
                  ? _buildSearchResults(db)
                  : _selectedPartId == 'definitions'
                      ? _buildDefinitions(db)
                      : _buildContent(db),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(RacingRulesDatabase db) {
    final ruleResults = db.search(_query);
    final defResults = db.searchDefinitions(_query);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Search Results: ${ruleResults.length} rules, ${defResults.length} definitions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...ruleResults.map((r) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rule ${r.number} — ${r.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            )),
        if (defResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Definitions',
              style: Theme.of(context).textTheme.titleMedium),
          ...defResults.map((d) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.term,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(d.definition),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildDefinitions(RacingRulesDatabase db) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Definitions',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Defined terms have specific meanings in the Racing Rules of Sailing.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Divider(height: 16),
        ...db.definitions.map((d) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.term,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(d.definition),
                    if (d.relatedRules.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: d.relatedRules
                            .map((r) => ActionChip(
                                  label: Text('Rule $r',
                                      style:
                                          const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _navigateToRule(db, r),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            )),
      ],
    );
  }

  void _navigateToRule(RacingRulesDatabase db, String ruleNumber) {
    for (final part in db.parts) {
      for (final section in part.sections) {
        for (final rule in section.rules) {
          if (rule.number == ruleNumber) {
            setState(() {
              _selectedPartId = part.id;
              _selectedSectionId = section.id;
              _query = '';
              _searchController.clear();
            });
            return;
          }
        }
      }
    }
    // Rule not found — show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rule $ruleNumber not found')),
    );
  }

  Widget _buildContent(RacingRulesDatabase db) {
    // Find selected section or show overview
    PartData? selectedPart;
    SectionData? selectedSection;

    if (_selectedPartId != null) {
      selectedPart =
          db.parts.where((p) => p.id == _selectedPartId).firstOrNull;
    }
    if (_selectedSectionId != null && selectedPart != null) {
      selectedSection = selectedPart.sections
          .where((s) => s.id == _selectedSectionId)
          .firstOrNull;
    }

    if (selectedSection != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            selectedPart!.title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            selectedSection.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Divider(height: 16),
          ...selectedSection.rules.map((rule) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rule ${rule.number} — ${rule.title}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        rule.text,
                        style: const TextStyle(height: 1.5),
                      ),
                      if (rule.crossReferences.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: rule.crossReferences
                              .map((r) => ActionChip(
                                    label: Text('Rule $r',
                                        style: const TextStyle(
                                            fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _navigateToRule(db, r),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
        ],
      );
    }

    // Overview
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          db.edition,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Select a section from the left navigation to browse rules, or use the search bar to find specific content.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: db.parts.map((part) {
            final ruleCount =
                part.sections.fold<int>(0, (s, sec) => s + sec.rules.length);
            return SizedBox(
              width: 240,
              child: Card(
                child: InkWell(
                  onTap: () => setState(() {
                    _selectedPartId = part.id;
                    _selectedSectionId = part.sections.first.id;
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          part.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$ruleCount rules • ${part.sections.length} sections',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
