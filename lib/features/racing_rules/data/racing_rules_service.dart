import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RuleData {
  final String number;
  final String title;
  final String text;
  final List<String> crossReferences;
  final List<String> keywords;

  const RuleData({
    required this.number,
    required this.title,
    required this.text,
    required this.crossReferences,
    required this.keywords,
  });

  factory RuleData.fromJson(Map<String, dynamic> json) => RuleData(
        number: json['number'] as String? ?? '',
        title: json['title'] as String? ?? '',
        text: json['text'] as String? ?? '',
        crossReferences: (json['crossReferences'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        keywords: (json['keywords'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class SectionData {
  final String id;
  final String title;
  final List<RuleData> rules;

  const SectionData({
    required this.id,
    required this.title,
    required this.rules,
  });

  factory SectionData.fromJson(Map<String, dynamic> json) => SectionData(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        rules: (json['rules'] as List<dynamic>?)
                ?.map((e) => RuleData.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class PartData {
  final String id;
  final String title;
  final List<SectionData> sections;

  const PartData({
    required this.id,
    required this.title,
    required this.sections,
  });

  factory PartData.fromJson(Map<String, dynamic> json) => PartData(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        sections: (json['sections'] as List<dynamic>?)
                ?.map((e) => SectionData.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class DefinitionData {
  final String term;
  final String definition;
  final List<String> relatedRules;

  const DefinitionData({
    required this.term,
    required this.definition,
    required this.relatedRules,
  });

  factory DefinitionData.fromJson(Map<String, dynamic> json) => DefinitionData(
        term: json['term'] as String? ?? '',
        definition: json['definition'] as String? ?? '',
        relatedRules: (json['relatedRules'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class RacingRulesDatabase {
  final String edition;
  final List<PartData> parts;
  final List<DefinitionData> definitions;

  const RacingRulesDatabase({
    required this.edition,
    required this.parts,
    required this.definitions,
  });

  List<RuleData> get allRules =>
      parts.expand((p) => p.sections.expand((s) => s.rules)).toList();

  RuleData? findRule(String number) {
    for (final rule in allRules) {
      if (rule.number == number) return rule;
    }
    return null;
  }

  List<RuleData> search(String query) {
    final q = query.toLowerCase();
    return allRules.where((r) {
      return r.number.contains(q) ||
          r.title.toLowerCase().contains(q) ||
          r.text.toLowerCase().contains(q) ||
          r.keywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }

  List<DefinitionData> searchDefinitions(String query) {
    final q = query.toLowerCase();
    return definitions.where((d) {
      return d.term.toLowerCase().contains(q) ||
          d.definition.toLowerCase().contains(q);
    }).toList();
  }
}

class RacingRulesService {
  RacingRulesDatabase? _db;
  static const _recentKey = 'racing_rules_recent';
  static const _bookmarksKey = 'racing_rules_bookmarks';
  static const _textSizeKey = 'racing_rules_text_size';

  Future<RacingRulesDatabase> load() async {
    if (_db != null) return _db!;
    final jsonStr =
        await rootBundle.loadString('assets/racing_rules.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;

    _db = RacingRulesDatabase(
      edition: data['edition'] as String? ?? '',
      parts: (data['parts'] as List<dynamic>?)
              ?.map((e) => PartData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      definitions: (data['definitions'] as List<dynamic>?)
              ?.map(
                  (e) => DefinitionData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
    return _db!;
  }

  // Recent lookups
  Future<List<String>> getRecentLookups() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? [];
  }

  Future<void> addRecentLookup(String ruleNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList(_recentKey) ?? [];
    recent.remove(ruleNumber);
    recent.insert(0, ruleNumber);
    if (recent.length > 20) recent.removeLast();
    await prefs.setStringList(_recentKey, recent);
  }

  // Bookmarks
  Future<List<String>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_bookmarksKey) ?? [];
  }

  Future<void> toggleBookmark(String ruleNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_bookmarksKey) ?? [];
    if (bookmarks.contains(ruleNumber)) {
      bookmarks.remove(ruleNumber);
    } else {
      bookmarks.add(ruleNumber);
    }
    await prefs.setStringList(_bookmarksKey, bookmarks);
  }

  // Text size
  Future<double> getTextSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_textSizeKey) ?? 16.0;
  }

  Future<void> setTextSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSizeKey, size);
  }
}
