# BENApp V195 — Social Controls & Live Layout Repair

Base: `c7c6f907bb5b7167c651244524ea9d5fab9a1b90` (the current V194 development chain).

## Included changes

- Reworked the live publisher route into an explicitly expanded full-screen stack. The camera preview fills the available route; the start panel and **YAYINI BİTİR** control are anchored to the bottom safe area, while the title/status controls stay at the top safe area.
- Applied the same explicit full-screen layout to the live viewer route.
- Standardized the BEN feed controls to a compact heart, comment, bookmark and share row. Active like remains red; active comment/save accents remain BEN gold.
- Changed feed and memory-detail card surfaces to charcoal/near-black tones with legible light foregrounds.
- Kept the existing like, comment, save and share callbacks intact; this change is visual and layout-focused.
- Extended the PHP exception log entry with request method, API path, exception class and source location. The user-facing request reference remains unchanged.

## TURN deployment requirement

The app already requests ICE servers from `GET live/ice-servers`. The backend returns TURN credentials only when both server environment variables are configured:

- `BEN_TURN_URLS`: comma-separated TURN URLs, for example `turn:turn.example.com:3478?transport=udp,turn:turn.example.com:3478?transport=tcp,turns:turn.example.com:5349?transport=tcp`
- `BEN_TURN_SHARED_SECRET`: the Coturn REST shared secret. Keep this value only on the server; never put it in the mobile app or repository.

A Coturn service must be deployed and reachable on the listed ports. Without both variables, the app deliberately falls back to public STUN and shows the existing TURN-not-configured status. This repository change does not create or provision a TURN server.

## Media upload error reference

When a memory is saved locally but its server upload fails, the app keeps the local draft in its pending-sync queue. The visible reference ID is sent as `X-Request-Id`; match that ID in the hosting provider's PHP error log. V195 adds the request method, endpoint path, exception type, message and source line to that server log entry.

The screenshot's generic 500 response alone does not identify whether the failure occurred during media upload, database migration or memory creation. Do not enable `BEN_DEBUG=1` on a public production server just to expose internal exception details.

## Verification checklist

- Run `flutter pub get` and `flutter analyze`.
- Build and install the iOS app; verify the camera preview fills the screen and the end-broadcast button remains at the bottom.
- Test a second device joining the broadcast.
- Test text, photo and video memory publishing.
- If the upload still returns 500, search the PHP error log using the exact request reference shown in the app.
- Configure TURN environment variables on the hosting service and test on a network behind restrictive NAT/firewall.
