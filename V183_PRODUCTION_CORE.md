# BENApp V183 — Production Core

- Backend is the feed source of truth; no demo feed fallback.
- Memory creation is remote-first; local storage is only a cache/media mirror.
- Real stories are derived from server memories; hard-coded story bots are not surfaced.
- Map screen no longer runs inside AnimatedSwitcher; MapLibre native view gets a stable host.
- 3D building/road layers are attempted on both Android and iOS with per-layer safety guards.
- Memory tree artificial 14-group / 5-memory caps removed.
- Splash keeps the BEN master logo and adds a short lock/glow phase.
- Existing + navigation is preserved.
