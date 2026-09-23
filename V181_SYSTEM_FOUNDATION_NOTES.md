BENApp V181 — System Foundation / iOS Stability

This build is based on BENApp V180 and keeps the existing BEN navigation, + button, 3D BEN World, feed modes, fullscreen memory viewer, profile tree, and branding.

Included fixes:
- Profile tree refreshes/re-fits when the memory dataset changes.
- iOS MapLibre path avoids the custom vector/expression layer path that can trigger native map crashes; Android keeps the custom 3D layers.
- Memory coordinates are requested automatically when the create-memory screen opens (with normal OS permission flow).
- Server memories carry owner username/avatar metadata.
- Profile avatars are uploaded to the PHP server instead of storing only a device-local file path.
- Photo/video media can be uploaded to the PHP server and referenced by media_url so other devices can load the same post media.
- Logged-in feed loading treats the server as authoritative and only uses local files to hydrate matching server memory IDs.
- Messages no longer contain demo conversations or automatic bot replies; conversations, search, send, read, edit and delete use the backend.
- SQLite schema migration adds media_url and preserves existing data.

Important:
- The backend/data/ben.sqlite file remains the persistent local server database. Keep it out of public Git repositories.
- Build iOS from the existing GitHub/iOS project when running GitHub Actions. This V180 source archive is the mobile/backend working base used for the Android APK workflow.
