# BENApp V189 — Stability Core

This build is based on the V188 FIX source that passed `flutter analyze` on the development PC.

## Critical fixes in this pass

- MapLibre is kept alive with `IndexedStack` instead of animating/disposal through `AnimatedSwitcher` when switching tabs. This is specifically intended to avoid iOS native MapLibre platform-view lifecycle crashes.
- Android uses MapLibre hybrid composition.
- BEN World no longer creates a second OpenFreeMap planet source. It reuses the `openmaptiles` source already defined by the OpenFreeMap style and adds the BEN 3D building extrusion/road layer on top. This keeps Android and iOS on the same tile source.
- Feed `Konumunu gör` now carries the exact memory into BEN World and the map focuses that memory instead of arbitrarily choosing the first memory.
- iOS location/camera/photo-library/microphone usage descriptions were added. Without the location usage description, iOS location acquisition could fail before the app receives a usable position.
- Photo capture/gallery selection now downsizes/compresses images before upload to reduce PHP upload-limit failures on the local development server.
- Local PHP development server now allows up to 32 MB per uploaded file and 40 MB POST bodies.
- The + menu now contains `Canlı Yayın Aç` and opens the existing Live screen. The center + button itself is unchanged.
- Android microphone permission was added for the live/video audio foundation.

## Not claimed complete

- This does not yet implement real WebRTC/RTMP live video transport.
- BEN Odaları / Clubhouse-style live audio rooms are not yet implemented; the current community room code is only a data foundation.
- Flutter analyze/build was not run in this container because the Flutter/Dart SDK is unavailable here. The developer machine must run `flutter analyze` before packaging/testing.
