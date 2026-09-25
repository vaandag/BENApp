# BENApp V191 — BEN World Premium Map

## Direct upgrade from V190

This release keeps the V189 iOS MapLibre lifecycle fix and V190 camera/source foundation. It adds the first real BEN World visual/data upgrade rather than replacing the map with a demo.

### Added
- Native MapLibre GeoJSON clustering for memory points on Android and iOS.
- Cluster bubbles with live point counts.
- Zoom-driven cluster expansion: cluster -> smaller cluster -> individual BEN memories.
- Individual memory points use the BEN master logo rather than a generic map pin.
- Cluster/point taps are handled through the MapLibre rendered-feature path.
- More visible 3D building edges and cyan road accents on the OpenFreeMap building source.
- Reset perspective now prefers the user's resolved location when available.

### Preserved
- V189 lazy MapLibre mounting for iOS stability.
- V190 initial camera resolution and Android OpenFreeMap 3D source.
- Existing memory card/fullscreen flow.
- Existing BEN navigation and center + button.

## Validation
Flutter/Dart SDK is not available in the build container, so `flutter analyze` was not run here. Run it on the Windows development machine before creating an APK/IPA.
