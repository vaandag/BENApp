# BENApp V196 — 3D World Improvements + Admin ID

Base branch: `ui/ben-design-system-v1`

## Included

- Profile options now show the signed-in account's numeric **Hesap ID** and copy it to the clipboard.
- BEN World re-syncs map annotations when the live memory list changes, including new pins, deleted pins, or changed coordinates.
- Existing map symbols and circle annotations are cleared before re-creation, preventing stale/duplicated pins after feed refreshes or style reloads.
- Memory locations receive a clearer cyan halo and a larger BEN logo marker, with a circle tap target as a fallback.
- 3D building extrusions, road accents, and building outlines have stronger BEN teal contrast and appear at a slightly wider zoom range.
- The selected-memory card now displays actual like, comment, and save counts instead of static action labels.
- App package and API health versions are advanced to `1.0.0+196` / `196`.

## Admin activation

1. Open **Profil > Profil ayarları > Hesap ID** and copy the numeric ID.
2. Stop the PHP server window.
3. Start `backend/start_ben_server.bat` again.
4. When prompted for administrator user IDs, paste the copied ID and press Enter. Multiple administrators can be separated with commas.
5. Sign in to BEN again or reopen Profile. The app checks `GET /api/admin/status` and shows the Yönetim paneli entry only when the server confirms the ID is in `BEN_ADMIN_USER_IDS`.

The allowlist is parsed in `backend/public/lib/http.php`; the PHP test `backend/tests/admin_access_test.php` covers valid, duplicate, invalid, zero, and negative IDs. No default admin password or extra account is created.

## Validation

The push to this branch triggers `.github/workflows/ios.yml`, which runs PHP syntax checks, backend tests, `flutter analyze --no-fatal-infos`, and `flutter test`.

Physical iPhone/Android verification is still required for native MapLibre rendering, camera gestures, and real-world pin visibility. The current native MapLibre experience uses 3D building extrusions and camera tilt; it is not satellite imagery or full photorealistic terrain.
