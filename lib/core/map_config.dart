abstract final class MapConfig {
  static const _cartoApiKey = String.fromEnvironment('CARTO_BASEMAPS_API_KEY');
  static const _cartoRasterUrl =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  static String get cartoTileUrl => cartoTileUrlFor(_cartoApiKey);

  static String cartoTileUrlFor(String apiKey) {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) return _cartoRasterUrl;
    return '$_cartoRasterUrl?key=${Uri.encodeQueryComponent(trimmedKey)}';
  }
}
