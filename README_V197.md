# BENApp V197 — Restore BEN Social Icons + iOS 3D Map Stability

Base branch: `ui/ben-design-system-v1`

## Included

- Feed like action is restored to the custom BEN dart mark (`BENDartIcon`).
- Feed comment action is restored to the custom BEN feather mark (`BENFeatherIcon`).
- The custom painter artwork remains the source of the icons; no standard heart or chat bubble is used for these two actions.
- BEN World waits for a finite, non-zero layout size before creating the native MapLibre view. This guards against initializing the iOS native map from a hidden/zero-sized layout.
- MapLibre Flutter is updated from 0.27.1 to 0.28.0. The upstream 0.28.0 release includes an iOS fix for a crash when a map is first displayed at zero size and an iOS map-resource teardown fix.
- iOS deployment target is raised from 13.0 to 15.5 to match MapLibre 0.28.0 requirements.
- App version and API health version are advanced to `1.0.0+197` / `197`.

## Compatibility

- This build requires iOS 15.5 or newer.
- The MapLibre 0.28.0 release requires Flutter 3.44 / Dart 3.12 or newer.
- Existing users on iOS versions earlier than 15.5 cannot install this build.

## Validation

- GitHub Actions will run `flutter pub get`, `flutter analyze --no-fatal-infos`, and `flutter test`.
- iOS IPA compilation is a separate manual workflow run.
- A physical iPhone interaction test is still required to confirm the reported tap-to-exit crash is resolved; CI cannot emulate MapLibre touch gestures on a real device.

## Device test checklist

1. Install the V197 iOS build on an iPhone running iOS 15.5 or newer.
2. Open **Harita** from the bottom navigation.
3. Pan, pinch-zoom, rotate and tilt the 3D map repeatedly.
4. Tap a BEN pin and open its memory card.
5. Switch to another tab, return to **Harita**, and repeat the gestures.
6. Verify like and comment actions show the BEN dart and feather artwork.


## Local development admin test account

- `backend/start_ben_server.bat` now defaults `BEN_ADMIN_USER_IDS` to `1`, so account ID 1 is recognized as an administrator when the local PHP server starts.
- The script preserves an explicitly supplied `BEN_ADMIN_USER_IDS` value, allowing multiple comma-separated IDs or a different test account.
- After updating the local repository, stop the currently running PHP server and start `backend/start_ben_server.bat` again. The console should show `BEN yonetici kullanici ID'leri: 1`.
- This default is for the local development server only. Do not copy it into a public production server configuration without an explicit administrator policy.
