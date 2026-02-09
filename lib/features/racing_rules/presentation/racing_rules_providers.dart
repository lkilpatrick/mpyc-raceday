import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/racing_rules_service.dart';

final racingRulesServiceProvider = Provider<RacingRulesService>((ref) {
  return RacingRulesService();
});

final racingRulesDatabaseProvider = FutureProvider<RacingRulesDatabase>((ref) {
  return ref.watch(racingRulesServiceProvider).load();
});

final recentLookupsProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(racingRulesServiceProvider).getRecentLookups();
});

final bookmarksProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(racingRulesServiceProvider).getBookmarks();
});

final textSizeProvider = FutureProvider<double>((ref) {
  return ref.watch(racingRulesServiceProvider).getTextSize();
});
