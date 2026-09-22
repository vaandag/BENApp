# BENApp V173 — Feed / Map / Social UX

This release is a product-flow refinement, not a new-feature dump.

## Changes
- Home feed now uses `Akış` (discovery) and `Bağlar` (people you follow) as the two primary feed modes.
- `PhpMemoryRepository.list()` accepts a `scope` query (`discover`, `following`, `mine`). The backend should interpret these scopes for production data separation.
- Feed memory cards have a dedicated map action using a map symbol with the BEN mark. It opens the selected memory's location.
- Every feed memory now has a Share action.
- Memory opening uses `MemoryFullscreenViewer` for immersive photo/video/text viewing.
- Fullscreen memory actions: like, comment, pin, share.
- Map memory preview opens the same fullscreen viewer instead of leaving the user on a half-detail state.
- Messages screen removes story-like circular shortcuts. It now contains only New conversation, Person search, and conversations.
- Notifications are no longer exposed from the profile overflow menu; the home notification bell remains the notification entry point.
- Profile share control now opens profile sharing and username-copy actions instead of silently copying the whole profile.
- `share_plus` is used for the native Android/iOS share sheet. WhatsApp and other installed apps appear through the OS share UI.
- The existing turquoise 52x52 center `+` button is preserved unchanged.

## Important backend note
The mobile client now sends `scope=discover` and `scope=following` to `GET /api/memories`. The current mobile source does not contain the PHP backend, so the local backend must implement those scope semantics for the two feeds to become genuinely different. Until then, the UI is ready and the existing API response remains usable.
