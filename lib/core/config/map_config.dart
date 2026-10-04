/// Central map configuration for BEN.
///
/// Development builds work without a provider key by falling back to the
/// standard OpenStreetMap raster tiles. Production builds can provide a
/// secured MapTiler public key with:
///
/// flutter build ios --dart-define=BEN_MAPTILER_KEY=YOUR_KEY
///
/// Keep the provider switch in one place so a map provider can be replaced
/// without editing both map screens.
final class BenMapConfig {
  static const String mapTilerKey = String.fromEnvironment(
    'BEN_MAPTILER_KEY',
    defaultValue: '',
  );

  static bool get usesMapTiler => mapTilerKey.trim().isNotEmpty;

  static String get tileUrlTemplate {
    if (usesMapTiler) {
      return 'https://api.maptiler.com/maps/streets-v4/256/{z}/{x}/{y}.png?key=$mapTilerKey';
    }

    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  static String get attribution => usesMapTiler
      ? '© MapTiler © OpenStreetMap contributors'
      : '© OpenStreetMap contributors';
}