# BENApp V135 — Full Audit / Stability & Media Fix

This build is based on V134. Source-level audit covered navigation, memory creation, Story/Memory metadata, home feed, comments, messages, profile tree, map, map-detail media, notifications, and backend routes.

## Fixed in V135
- Keep local photo/video memories when server metadata is available; server data no longer blindly replaces local media-bearing records.
- Story viewer uses the real local photo for the current user's Story when available.
- Home feed uses the local video file for a real video thumbnail/preview when available.
- Map memory detail uses a local video file when the stored path is local; network URL remains supported.
- Comments use the authenticated user id instead of hard-coded user id 1.
- Messages' demo chat model now carries a user id and the round action honors its icon.
- Anı Ağacı initial view is fitted to the visible phone viewport so the trunk/branches and memory nodes are not placed outside the initial view; tree drawing was strengthened for visibility.
- Existing MapScreen ticker fix from V133 is retained.

## Important source-level findings / remaining work
- Real backend chat UI is not fully wired yet; current conversation list still contains demo contacts and local chat state.
- Backend stores memory metadata, not uploaded photo/video files. Local media therefore remains device-local until a real media upload/CDN layer is added.
- Remote comment edit/delete endpoints are not implemented; local edit/delete remains local.
- Map demo pins and some demo feed content remain by design for development.
- Flutter SDK is not installed in this audit container, so `flutter analyze` / APK compilation could not be executed here. The final device validation must be run from the user's D:\BENApp\mobile environment.
