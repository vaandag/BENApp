# BENApp V136 — Stability + UI Polish

- Main navigation no longer recreates a PageView/controller during tab changes; pages remain mounted in a keyed animated stack to reduce route/inherited-widget lifecycle churn behind `_dependents.isEmpty` assertions.
- Preserved BEN | Harita | + | Mesajlar | Profil navigation and smooth transitions.
- Removed the extra floating `AN BIRAK` action from the BEN screen; the canonical bottom-center `+` remains the create entry point.
- Story viewer now supports local video memories in addition to local photos and has a richer no-media fallback.
- Comments screen received a more polished BEN visual treatment with rounded comment cards and improved header/input presentation.
- Tree zoom controls were reduced and the tree canvas background was refined.

This source was not compiled in this environment because Flutter SDK is unavailable here. Run `flutter analyze` and build on the development machine.
