import 'package:flutter_test/flutter_test.dart';
import 'package:mpyc_raceday/core/map_config.dart';

void main() {
  const baseUrl =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  test('empty key returns base URL without key param', () {
    expect(MapConfig.cartoTileUrlFor(''), baseUrl);
    expect(MapConfig.cartoTileUrlFor(''), isNot(contains('?key=')));
  });

  test('whitespace-only key returns base URL', () {
    expect(MapConfig.cartoTileUrlFor('   \t\n '), baseUrl);
  });

  test('key is trimmed and query-component encoded', () {
    final url = MapConfig.cartoTileUrlFor('  a b&c=d?e  ');
    expect(url, '$baseUrl?key=a+b%26c%3Dd%3Fe');
  });
}
