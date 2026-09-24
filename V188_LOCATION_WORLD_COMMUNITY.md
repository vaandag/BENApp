# BENApp V188 — Location / World / Community foundation

This release builds on the clean V186 source and adds the next production foundation without changing the BEN | Harita | + | Mesajlar | Profil navigation.

## Location
- Location acquisition now returns a structured result with reason codes.
- Current GPS uses a high-accuracy request with a last-known-position fallback.
- Location accuracy is persisted on memories and sent to the backend.
- Creating a memory can continue without location; explicit Location memories require a valid coordinate.
- The create-memory screen shows whether location is ready and lets the user refresh it.
- A failed backend save no longer silently becomes a local-only published memory.

## BEN World
- The 3D map can acquire the user's current location when permission is available.
- The location control now centers on the user rather than incorrectly jumping to the first memory.
- Existing memory pins and fullscreen memory flow remain intact.

## Regional community
- Backend creates regional rooms from the user's coordinates using reverse geocoding.
- Regional messages are persistent and include the sender's username/avatar.
- A Topluluk screen provides automatic regional chat plus Rank & Badges.
- No city selection UI is required.

## Rank & badges
- XP is derived from real server-side activity: memories, comments, likes, follows, regional messages and live rooms.
- Levels and badges are generated from real thresholds instead of static demo values.

## Global live
- Live discovery remains global; it is not restricted by the user's region.
