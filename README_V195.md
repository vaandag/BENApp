# BENApp V195 — 3D World + Media Loading Repair

Base branch: `ui/ben-design-system-v1`

## Included

- BEN > Harita now mounts `Ben3DMapScreen` directly. The primary navigation no longer opens the 2D `MapScreen`.
- MapLibre is the active map renderer on both iOS and Android. The iOS-only FlutterMap fallback has been removed.
- OpenFreeMap vector building extrusions, roads and building edges are applied on both mobile platforms.
- Expired story memories are excluded from the 3D memory-marker layer.
- Feed and Story photo surfaces now render a deliberate BEN-colored loading state instead of an uninitialized blank/grey area.
- Story playback duration begins after its photo/video media has either loaded or failed, so a slow media request does not consume the whole Story duration before the user can see it.
- Feed/Story remote video previews show a loading state and fall back safely if initialization fails.
- The full-screen viewer accepts the backend's relative `/api/media/...` photo paths; remote video failures no longer leave an endless spinner and can be retried.
- App version and API health response are advanced to V195.

## Validation

1. `flutter pub get`
2. `flutter analyze --no-fatal-infos`
3. `flutter test`
4. Build the unsigned iOS IPA from GitHub Actions.
5. On iPhone and Android, open BEN > Harita and verify MapLibre 3D buildings, camera tilt/rotation and memory pins.
6. Test Story photo/video loading on a second device, swipe between stories while media is still loading, then open a Story into the full-screen viewer.
7. Test feed photo/video loading and retry behavior for an unavailable video.

## Runtime note

The automated CI can verify analysis, tests and iOS compilation. Actual MapLibre rendering and gesture stability still require testing on physical iPhone and Android devices.
