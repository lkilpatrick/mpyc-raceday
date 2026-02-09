import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/racing_rules_service.dart';
import '../racing_rules_providers.dart';

class RuleDetailScreen extends ConsumerStatefulWidget {
  const RuleDetailScreen({super.key, required this.ruleNumber});

  final String ruleNumber;

  @override
  ConsumerState<RuleDetailScreen> createState() => _RuleDetailScreenState();
}

class _RuleDetailScreenState extends ConsumerState<RuleDetailScreen> {
  double _textSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadTextSize();
  }

  Future<void> _loadTextSize() async {
    final size = await ref.read(racingRulesServiceProvider).getTextSize();
    if (mounted) setState(() => _textSize = size);
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(racingRulesDatabaseProvider);
    final bookmarksAsync = ref.watch(bookmarksProvider);

    return dbAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (db) {
        final rule = db.findRule(widget.ruleNumber);
        if (rule == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Rule ${widget.ruleNumber} not found')),
          );
        }

        final bookmarks = bookmarksAsync.value ?? [];
        final isBookmarked = bookmarks.contains(rule.number);
        final definedTerms =
            db.definitions.map((d) => d.term.toLowerCase()).toSet();

        return Scaffold(
          appBar: AppBar(
            title: Text('Rule ${rule.number}'),
            actions: [
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
                onPressed: () async {
                  await ref
                      .read(racingRulesServiceProvider)
                      .toggleBookmark(rule.number);
                  ref.invalidate(bookmarksProvider);
                },
              ),
              IconButton(
                icon: const Icon(Icons.text_decrease),
                onPressed: () => _changeTextSize(-2),
              ),
              IconButton(
                icon: const Icon(Icons.text_increase),
                onPressed: () => _changeTextSize(2),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Text(
                rule.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Rule ${rule.number}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 16),

              // Rule text with highlighted defined terms
              _buildRuleText(rule.text, definedTerms, db),

              // Cross-references
              if (rule.crossReferences.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  'Related Rules',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: rule.crossReferences.map((ref) {
                    final related = db.findRule(ref);
                    return ActionChip(
                      label: Text(
                          'Rule $ref${related != null ? " — ${related.title}" : ""}'),
                      onPressed: () => _openRule(ref),
                    );
                  }).toList(),
                ),
              ],

              // Keywords
              if (rule.keywords.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: rule.keywords
                      .map((k) => Chip(
                            label: Text(k, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 24),

              // Disclaimer
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleText(
    String text,
    Set<String> definedTerms,
    RacingRulesDatabase db,
  ) {
    // Split text into words and highlight defined terms
    final words = text.split(' ');
    final spans = <InlineSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final cleanWord =
          word.replaceAll(RegExp(r'[.,;:()"]'), '').toLowerCase();

      // Check multi-word terms first
      bool matched = false;
      for (final def in db.definitions) {
        final termWords = def.term.toLowerCase().split(' ');
        if (termWords.length > 1 && i + termWords.length <= words.length) {
          final phrase = words
              .sublist(i, i + termWords.length)
              .join(' ')
              .replaceAll(RegExp(r'[.,;:()"]'), '')
              .toLowerCase();
          if (phrase == def.term.toLowerCase()) {
            spans.add(WidgetSpan(
              child: GestureDetector(
                onTap: () => _showDefinition(def),
                child: Text(
                  words.sublist(i, i + termWords.length).join(' '),
                  style: TextStyle(
                    fontSize: _textSize,
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ));
            i += termWords.length - 1;
            matched = true;
            break;
          }
        }
      }

      if (!matched) {
        if (definedTerms.contains(cleanWord) && cleanWord.length > 3) {
          spans.add(WidgetSpan(
            child: GestureDetector(
              onTap: () {
                final def = db.definitions.firstWhere(
                  (d) => d.term.toLowerCase() == cleanWord,
                  orElse: () => db.definitions.firstWhere(
                    (d) => d.term.toLowerCase().contains(cleanWord),
                    orElse: () => const DefinitionData(
                        term: '', definition: '', relatedRules: []),
                  ),
                );
                if (def.term.isNotEmpty) _showDefinition(def);
              },
              child: Text(
                word,
                style: TextStyle(
                  fontSize: _textSize,
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ));
        } else {
          spans.add(TextSpan(
            text: word,
            style: TextStyle(fontSize: _textSize),
          ));
        }
      }

      if (i < words.length - 1) {
        spans.add(TextSpan(
            text: ' ', style: TextStyle(fontSize: _textSize)));
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: _textSize,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }

  void _showDefinition(DefinitionData def) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              def.term,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(def.definition),
            if (def.relatedRules.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: def.relatedRules
                    .map((r) => ActionChip(
                          label: Text('Rule $r'),
                          onPressed: () {
                            Navigator.pop(context);
                            _openRule(r);
                          },
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openRule(String ruleNumber) {
    ref.read(racingRulesServiceProvider).addRecentLookup(ruleNumber);
    ref.invalidate(recentLookupsProvider);
    context.go('/rules/detail/$ruleNumber');
  }

  Future<void> _changeTextSize(double delta) async {
    final newSize = (_textSize + delta).clamp(12.0, 28.0);
    setState(() => _textSize = newSize);
    await ref.read(racingRulesServiceProvider).setTextSize(newSize);
  }
}
